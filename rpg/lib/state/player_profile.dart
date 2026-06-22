// 플레이어 진행 상태 (레벨/경험치/골드/체력/장비/가방) — 게임(Flame)과 UI(Flutter) 공유.
// 가방은 장비(GearItem)와 기타(MiscItem)를 함께 담는다. ChangeNotifier 로 HUD/인벤토리 자동 갱신.
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/combat_stats.dart';
import '../models/enhance.dart';
import '../models/gear.dart';
import '../models/items.dart';

class PlayerProfile extends ChangeNotifier {
  static const int bagCapacity = 60; // 슬롯 수(디스플레이가 크면 더 많이 보임)

  int level = 1;
  int exp = 0;
  int gold = 0;
  int gachaLevel = 1; // 장비 뽑기 레벨(골드로 상승 → 더 높은 레벨 장비 등장)

  // 마지막 위치(재접속 시 복귀).
  double lastX = 1000;
  double lastY = 1000;

  // 캐릭터 아바타(64x64 PNG, base64). null 이면 기본 외형.
  String? avatarBase64;

  late int hp;

  final CombatStats _base = CombatStats.basePlayer();
  final Map<EquipSlot, GearItem?> equipped = {for (final s in EquipSlot.values) s: null};
  final List<BagItem> bag = [];

  PlayerProfile() {
    hp = maxHp;
    // 시작 물약 2개.
    bag.add(MiscItem(id: 'start_potion', kind: MiscKind.healthPotion, quantity: 2));
  }

  // 기본 + 레벨 보너스 + 장비 보너스 합산.
  CombatStats get total {
    var t = _base +
        CombatStats(
          attack: (level - 1) * 2.0,
          defense: (level - 1) * 1.0,
          maxHp: (level - 1) * 12.0,
        );
    for (final g in equipped.values) {
      if (g != null) t = t + g.effectiveBonus;
    }
    return t;
  }

  int get maxHp => total.maxHp.round();
  double get attackInterval => 1.0 / max(0.25, total.attackSpeed);
  int get expToNext => 60 + (level - 1) * 45;
  double get expRatio => (exp / expToNext).clamp(0.0, 1.0);
  bool get isDead => hp <= 0;

  // 같은 종류 기타 아이템은 스택되므로 새 슬롯이 필요한지 판단.
  bool get bagFull => bag.length >= bagCapacity;

  // 회복 포션(전 등급) 총 개수.
  int get potions {
    var n = 0;
    for (final it in bag) {
      if (it is MiscItem && it.kind.usableHeal) n += it.quantity;
    }
    return n;
  }

  int get townScrolls {
    var n = 0;
    for (final it in bag) {
      if (it is MiscItem && it.kind.isTownScroll) n += it.quantity;
    }
    return n;
  }

  // 장비 뽑기 레벨업 비용.
  int get gachaUpgradeCost => 100 + (gachaLevel - 1) * 80;
  bool upgradeGacha() {
    if (!spendGold(gachaUpgradeCost)) return false;
    gachaLevel++;
    notifyListeners();
    return true;
  }

  void damage(int amount) {
    hp = (hp - amount).clamp(0, maxHp);
    notifyListeners();
  }

  void revive() {
    hp = maxHp;
    notifyListeners();
  }

  void heal(int amount) {
    hp = (hp + amount).clamp(0, maxHp);
    notifyListeners();
  }

  // 보유한 포션 중 회복량이 가장 큰 것을 사용. 결과 메시지 반환(null=실패).
  String? usePotion() {
    if (hp >= maxHp) return '체력이 가득 찼습니다';
    MiscItem? best;
    for (final it in bag) {
      if (it is MiscItem && it.kind.usableHeal) {
        if (best == null || it.kind.healPercent > best.kind.healPercent) best = it;
      }
    }
    if (best == null) return '포션이 없습니다';
    final healed = (maxHp * best.kind.healPercent).round();
    hp = (hp + healed).clamp(0, maxHp);
    best.quantity--;
    if (best.quantity <= 0) bag.remove(best);
    notifyListeners();
    return '${best.kind.name} 사용 · +$healed HP';
  }

  // 특정 기타 아이템 1개 소비(예: 마을 귀환 주문서).
  bool consumeMisc(MiscKind kind) {
    for (final it in bag) {
      if (it is MiscItem && it.kind == kind) {
        it.quantity--;
        if (it.quantity <= 0) bag.remove(it);
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void gainExp(int amount) {
    exp += amount;
    var leveled = false;
    while (exp >= expToNext) {
      exp -= expToNext;
      level++;
      leveled = true;
    }
    if (leveled) hp = maxHp;
    notifyListeners();
  }

  void addGold(int amount) {
    gold += amount;
    notifyListeners();
  }

  bool spendGold(int amount) {
    if (gold < amount) return false;
    gold -= amount;
    notifyListeners();
    return true;
  }

  void setAvatar(String? base64) {
    avatarBase64 = base64;
    notifyListeners();
  }

  void toggleLock(BagItem item) {
    item.locked = !item.locked;
    notifyListeners();
  }

  // 가방에 추가. 기타 아이템은 같은 종류에 스택. 가득 차면 false.
  bool addItem(BagItem item) {
    if (item is MiscItem) {
      final idx = bag.indexWhere((it) => it is MiscItem && it.kind == item.kind);
      if (idx >= 0) {
        (bag[idx] as MiscItem).quantity += item.quantity;
        notifyListeners();
        return true;
      }
    }
    if (bagFull) return false;
    bag.add(item);
    notifyListeners();
    return true;
  }

  // 장착(가방→슬롯). 종류에 맞는 빈 슬롯(반지=4칸 중 첫 빈칸), 없으면 첫 슬롯 교체.
  void equip(GearItem g) {
    if (!bag.remove(g)) return;
    final slots = slotsForKind(g.kind);
    final target = slots.firstWhere((s) => equipped[s] == null, orElse: () => slots.first);
    final old = equipped[target];
    equipped[target] = g;
    if (old != null) bag.add(old);
    hp = hp.clamp(0, maxHp);
    notifyListeners();
  }

  // 같은 종류로 비교할 대표 장비(종이인형 ▲▼·약한장비 판매용).
  // 종류 슬롯 중 하나라도 비어 있으면 null(빈칸이면 장착을 권장 → 비교/자동판매 제외).
  GearItem? equippedComparable(GearKind kind) {
    final items = [for (final s in slotsForKind(kind)) equipped[s]];
    if (items.any((e) => e == null)) return null;
    items.sort((a, b) => a!.power.compareTo(b!.power));
    return items.first; // 가장 약한 착용분
  }

  void unequip(EquipSlot slot) {
    final g = equipped[slot];
    if (g == null || bagFull) return;
    equipped[slot] = null;
    bag.add(g);
    hp = hp.clamp(0, maxHp);
    notifyListeners();
  }

  final Random _enhanceRng = Random();

  // 강화 시도(천장 반영). 골드 부족이면 null, 아니면 결과 반환.
  // 성공: 단계+1·스택0 / 유지: 스택+1 / 하락: -1(체크포인트 바닥) 스택0 / 파괴: 가방에서 제거.
  EnhanceResult? tryEnhance(GearItem g) {
    if (!bag.contains(g)) return null;
    final target = g.enhanceLevel + 1;
    if (target > EnhanceSystem.maxLevel) return null;
    if (!spendGold(EnhanceSystem.cost(target))) return null;
    final res = EnhanceSystem.roll(target, g.enhanceStack, _enhanceRng);
    switch (res) {
      case EnhanceResult.success:
        g.enhanceLevel = target;
        g.enhanceStack = 0;
        break;
      case EnhanceResult.keep:
        g.enhanceStack++;
        break;
      case EnhanceResult.downgrade:
        g.enhanceLevel = max(EnhanceSystem.downFloor(g.enhanceLevel), g.enhanceLevel - 1);
        g.enhanceStack = 0;
        break;
      case EnhanceResult.destroy:
        bag.remove(g);
        break;
    }
    notifyListeners();
    return res;
  }

  // ── 직렬화(계정별 저장/복원) ──
  Map<String, dynamic> toJson() => {
        'level': level,
        'exp': exp,
        'gold': gold,
        'gacha': gachaLevel,
        'hp': hp,
        'x': lastX,
        'y': lastY,
        if (avatarBase64 != null) 'avatar': avatarBase64,
        'equipped': {
          for (final s in EquipSlot.values) s.name: equipped[s]?.toJson(),
        },
        'bag': bag
            .map((it) => it is GearItem
                ? {'t': 'g', ...it.toJson()}
                : {'t': 'm', ...(it as MiscItem).toJson()})
            .toList(),
      };

  void loadJson(Map<String, dynamic> j) {
    level = (j['level'] as num?)?.toInt() ?? 1;
    exp = (j['exp'] as num?)?.toInt() ?? 0;
    gold = (j['gold'] as num?)?.toInt() ?? 0;
    gachaLevel = (j['gacha'] as num?)?.toInt() ?? 1;
    lastX = (j['x'] as num?)?.toDouble() ?? 1000;
    lastY = (j['y'] as num?)?.toDouble() ?? 1000;
    avatarBase64 = j['avatar'] as String?;

    final eq = j['equipped'] as Map<String, dynamic>?;
    for (final s in EquipSlot.values) {
      final e = eq?[s.name];
      equipped[s] = e == null ? null : GearItem.fromJson(e as Map<String, dynamic>);
    }
    // 구형 저장 마이그레이션(armor→상의, ring→반지1).
    if (eq != null) {
      if (eq['armor'] != null && equipped[EquipSlot.top] == null) {
        equipped[EquipSlot.top] = GearItem.fromJson(eq['armor'] as Map<String, dynamic>);
      }
      if (eq['ring'] != null && equipped[EquipSlot.ring1] == null) {
        equipped[EquipSlot.ring1] = GearItem.fromJson(eq['ring'] as Map<String, dynamic>);
      }
    }

    bag.clear();
    for (final raw in (j['bag'] as List?) ?? const []) {
      final m = raw as Map<String, dynamic>;
      bag.add(m['t'] == 'g' ? GearItem.fromJson(m) : MiscItem.fromJson(m));
    }

    hp = ((j['hp'] as num?)?.toInt() ?? maxHp).clamp(0, maxHp);
    notifyListeners();
  }

  // 일괄 판매(잡템 정리): 잠금 안 된 평범/고급 장비 + 재료(가죽/결정/주화)를 판매. 포션/주문서 제외.
  int sellBulk() {
    var total = 0;
    bag.removeWhere((it) {
      if (it.locked) return false;
      if (it is GearItem && it.rarity.index <= Rarity.uncommon.index) {
        total += it.sellPrice;
        return true;
      }
      if (it is MiscItem && it.kind.isMaterial) {
        total += it.sellPrice * it.quantity;
        return true;
      }
      return false;
    });
    if (total > 0) {
      gold += total;
      notifyListeners();
    }
    return total;
  }

  // 현재 장착 장비보다 약한(종류별 power 비교) 잠금 안 된 장비를 모두 판매.
  int sellWeakerThanEquipped() {
    var total = 0;
    bag.removeWhere((it) {
      if (it.locked || it is! GearItem) return false;
      final eq = equippedComparable(it.kind);
      if (eq != null && it.power < eq.power) {
        total += it.sellPrice;
        return true;
      }
      return false;
    });
    if (total > 0) {
      gold += total;
      notifyListeners();
    }
    return total;
  }

  // 판매. 잠금 아이템은 판매되지 않는다. 기타는 1개씩, 장비는 통째로.
  void sell(BagItem item) {
    if (item.locked) return;
    if (item is GearItem) {
      if (bag.remove(item)) {
        gold += item.sellPrice;
        notifyListeners();
      }
    } else if (item is MiscItem) {
      final idx = bag.indexWhere((it) => it == item);
      if (idx < 0) return;
      gold += item.sellPrice;
      item.quantity--;
      if (item.quantity <= 0) bag.removeAt(idx);
      notifyListeners();
    }
  }
}
