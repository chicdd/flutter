// 장비 아이템 모델 + 절차적 생성 (RPG 루팅).
// 아이템 "종류"(GearKind)와 착용 "슬롯"(EquipSlot)을 분리한다 — 반지는 한 종류지만 4칸에 낄 수 있다.
import 'dart:math';

import 'combat_stats.dart';
import 'enhance.dart';
import 'items.dart';

// 종이인형 장비창의 착용 위치(14칸).
enum EquipSlot {
  weapon,
  helmet,
  shoulder,
  top, // 상의
  gloves, // 장갑
  bottom, // 하의
  boots,
  necklace, // 목걸이
  belt, // 벨트
  bracelet, // 팔찌
  ring1,
  ring2,
  ring3,
  ring4,
}

// 아이템 종류(드랍/생성 단위). 반지는 ring 하나지만 ring1~4 어디든 장착.
enum GearKind { weapon, helmet, shoulder, top, gloves, bottom, boots, necklace, belt, bracelet, ring }

extension EquipSlotX on EquipSlot {
  String get label => switch (this) {
        EquipSlot.weapon => '무기',
        EquipSlot.helmet => '투구',
        EquipSlot.shoulder => '어깨',
        EquipSlot.top => '상의',
        EquipSlot.gloves => '장갑',
        EquipSlot.bottom => '하의',
        EquipSlot.boots => '신발',
        EquipSlot.necklace => '목걸이',
        EquipSlot.belt => '벨트',
        EquipSlot.bracelet => '팔찌',
        EquipSlot.ring1 => '반지',
        EquipSlot.ring2 => '반지',
        EquipSlot.ring3 => '반지',
        EquipSlot.ring4 => '반지',
      };

  // 이 슬롯이 받는 아이템 종류.
  GearKind get kind => switch (this) {
        EquipSlot.weapon => GearKind.weapon,
        EquipSlot.helmet => GearKind.helmet,
        EquipSlot.shoulder => GearKind.shoulder,
        EquipSlot.top => GearKind.top,
        EquipSlot.gloves => GearKind.gloves,
        EquipSlot.bottom => GearKind.bottom,
        EquipSlot.boots => GearKind.boots,
        EquipSlot.necklace => GearKind.necklace,
        EquipSlot.belt => GearKind.belt,
        EquipSlot.bracelet => GearKind.bracelet,
        EquipSlot.ring1 || EquipSlot.ring2 || EquipSlot.ring3 || EquipSlot.ring4 => GearKind.ring,
      };
}

extension GearKindX on GearKind {
  String get baseName => switch (this) {
        GearKind.weapon => '무기',
        GearKind.helmet => '투구',
        GearKind.shoulder => '견갑',
        GearKind.top => '상의',
        GearKind.gloves => '장갑',
        GearKind.bottom => '하의',
        GearKind.boots => '장화',
        GearKind.necklace => '목걸이',
        GearKind.belt => '벨트',
        GearKind.bracelet => '팔찌',
        GearKind.ring => '반지',
      };
}

// 한 종류가 들어갈 수 있는 슬롯 목록(반지=4칸).
List<EquipSlot> slotsForKind(GearKind k) => switch (k) {
      GearKind.ring => const [EquipSlot.ring1, EquipSlot.ring2, EquipSlot.ring3, EquipSlot.ring4],
      GearKind.weapon => const [EquipSlot.weapon],
      GearKind.helmet => const [EquipSlot.helmet],
      GearKind.shoulder => const [EquipSlot.shoulder],
      GearKind.top => const [EquipSlot.top],
      GearKind.gloves => const [EquipSlot.gloves],
      GearKind.bottom => const [EquipSlot.bottom],
      GearKind.boots => const [EquipSlot.boots],
      GearKind.necklace => const [EquipSlot.necklace],
      GearKind.belt => const [EquipSlot.belt],
      GearKind.bracelet => const [EquipSlot.bracelet],
    };

enum WeaponType { sword, spear, bow, axe, staff }

extension WeaponTypeX on WeaponType {
  String get label => switch (this) {
        WeaponType.sword => '검',
        WeaponType.spear => '창',
        WeaponType.bow => '활',
        WeaponType.axe => '도끼',
        WeaponType.staff => '지팡이',
      };
}

// 무기별 전투 특성.
class WeaponProfile {
  final double range; // 사거리(px)
  final double halfAngleDeg; // 정면 부채꼴 반각(도)
  final bool cleave; // 범위 내 다수 타격
  final bool ranged; // 투사체(원거리)
  final double speedMult; // 공격 간격 배수(클수록 느림)
  const WeaponProfile(this.range, this.halfAngleDeg, this.cleave, this.ranged, this.speedMult);

  static const WeaponProfile fists = WeaponProfile(95, 55, false, false, 1.0);

  static WeaponProfile of(WeaponType? t) => switch (t) {
        WeaponType.sword => const WeaponProfile(120, 55, false, false, 1.0),
        WeaponType.spear => const WeaponProfile(180, 22, true, false, 1.1),
        WeaponType.bow => const WeaponProfile(360, 16, false, true, 1.55),
        WeaponType.axe => const WeaponProfile(105, 78, true, false, 1.35),
        WeaponType.staff => const WeaponProfile(240, 18, false, true, 1.2),
        null => fists,
      };
}

enum Rarity { common, uncommon, rare, epic, legendary, mythic }

extension RarityX on Rarity {
  String get label => switch (this) {
        Rarity.common => '평범한',
        Rarity.uncommon => '고급',
        Rarity.rare => '희귀',
        Rarity.epic => '영웅',
        Rarity.legendary => '전설',
        Rarity.mythic => '신화',
      };

  double get mult => switch (this) {
        Rarity.common => 1.0,
        Rarity.uncommon => 1.45,
        Rarity.rare => 2.0,
        Rarity.epic => 2.8,
        Rarity.legendary => 3.8,
        Rarity.mythic => 5.2,
      };

  int get colorValue => switch (this) {
        Rarity.common => 0xFFB0BEC5,
        Rarity.uncommon => 0xFF66BB6A,
        Rarity.rare => 0xFF42A5F5,
        Rarity.epic => 0xFFAB47BC,
        Rarity.legendary => 0xFFFFB300,
        Rarity.mythic => 0xFFFF3D00,
      };
}

class GearItem implements BagItem {
  @override
  final String id;
  @override
  final String name;
  final GearKind kind;
  @override
  final Rarity rarity;
  final CombatStats bonus;
  final int itemLevel;
  final WeaponType? weaponType; // 무기일 때만
  @override
  bool locked;
  int enhanceLevel; // +0~+20
  int enhanceStack; // 현재 단계 천장 누적(실패 횟수)

  GearItem({
    required this.id,
    required this.name,
    required this.kind,
    required this.rarity,
    required this.bonus,
    required this.itemLevel,
    this.weaponType,
    this.locked = false,
    this.enhanceLevel = 0,
    this.enhanceStack = 0,
  });

  // 강화 반영 능력치(기본 능력치 × 단계 누적 배수).
  CombatStats get effectiveBonus =>
      enhanceLevel <= 0 ? bonus : bonus.scaled(EnhanceSystem.statMult(enhanceLevel));

  // 표시명(+N).
  String get displayName => enhanceLevel > 0 ? '$name +$enhanceLevel' : name;

  double get power =>
      effectiveBonus.attack * 2 +
      effectiveBonus.defense * 1.5 +
      effectiveBonus.maxHp * 0.4 +
      effectiveBonus.armorPen * 2 +
      effectiveBonus.critChance * 120 +
      effectiveBonus.critMultiplier * 30 +
      effectiveBonus.attackSpeed * 60;

  int get sellPrice =>
      (power * (1 + rarity.index) + itemLevel * 3).round() + 5 + enhanceLevel * 20;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.index,
        'rarity': rarity.index,
        'bonus': bonus.toJson(),
        'lv': itemLevel,
        if (weaponType != null) 'wt': weaponType!.index,
        if (locked) 'lk': true,
        if (enhanceLevel > 0) 'eh': enhanceLevel,
        if (enhanceStack > 0) 'es': enhanceStack,
      };

  factory GearItem.fromJson(Map<String, dynamic> j) => GearItem(
        id: j['id'] as String,
        name: j['name'] as String,
        kind: _readKind(j),
        rarity: Rarity.values[(j['rarity'] as num).toInt()],
        bonus: CombatStats.fromJson(j['bonus'] as Map<String, dynamic>),
        itemLevel: (j['lv'] as num).toInt(),
        weaponType: j['wt'] == null ? null : WeaponType.values[(j['wt'] as num).toInt()],
        locked: j['lk'] == true,
        enhanceLevel: (j['eh'] as num?)?.toInt() ?? 0,
        enhanceStack: (j['es'] as num?)?.toInt() ?? 0,
      );

  // 신형(kind) 우선, 없으면 구형(slot index) 마이그레이션: 0 무기,1 갑옷→상의,2 투구,3 신발,4 반지.
  static GearKind _readKind(Map<String, dynamic> j) {
    if (j['kind'] != null) return GearKind.values[(j['kind'] as num).toInt()];
    final old = (j['slot'] as num?)?.toInt() ?? 0;
    return switch (old) {
      0 => GearKind.weapon,
      1 => GearKind.top,
      2 => GearKind.helmet,
      3 => GearKind.boots,
      4 => GearKind.ring,
      _ => GearKind.top,
    };
  }
}

class GearGenerator {
  static final Random _rng = Random();
  static int _counter = 0;

  static String _id() => 'g${DateTime.now().microsecondsSinceEpoch}_${_counter++}';

  static GearItem random({
    required int level,
    required Rarity rarity,
    GearKind? kind,
    Random? rng,
  }) {
    final r = rng ?? _rng;
    kind ??= GearKind.values[r.nextInt(GearKind.values.length)];
    final variance = 0.85 + r.nextDouble() * 0.3;
    final m = rarity.mult * (1 + level * 0.08) * variance;
    final tier = rarity.index; // 0~5

    CombatStats bonus;
    WeaponType? wt;
    String name = '${rarity.label} ${kind.baseName}';

    switch (kind) {
      case GearKind.weapon:
        wt = WeaponType.values[r.nextInt(WeaponType.values.length)];
        name = '${rarity.label} ${wt.label}';
        switch (wt) {
          case WeaponType.sword:
            bonus = CombatStats(attack: 7 * m, critChance: 0.02 * tier, attackSpeed: 0.05 * tier);
            break;
          case WeaponType.spear:
            bonus = CombatStats(attack: 6.5 * m, armorPen: 2.0 * tier + 1, attackSpeed: 0.03 * tier);
            break;
          case WeaponType.bow:
            bonus = CombatStats(attack: 6.2 * m, critChance: 0.04 * tier + 0.02, critMultiplier: 0.04 * tier);
            break;
          case WeaponType.axe:
            bonus = CombatStats(attack: 9 * m, critMultiplier: 0.05 * tier);
            break;
          case WeaponType.staff:
            bonus = CombatStats(attack: 7.5 * m, critMultiplier: 0.08 * tier, maxHp: 6 * m);
            break;
        }
        break;
      case GearKind.helmet:
        bonus = CombatStats(defense: 3 * m, maxHp: 10 * m, critChance: 0.01 * tier);
        break;
      case GearKind.top:
        bonus = CombatStats(defense: 5 * m, maxHp: 14 * m);
        break;
      case GearKind.bottom:
        bonus = CombatStats(defense: 3.5 * m, maxHp: 10 * m, attackSpeed: 0.02 * tier);
        break;
      case GearKind.shoulder:
        bonus = CombatStats(defense: 2.5 * m, maxHp: 8 * m, attack: 1.5 * m);
        break;
      case GearKind.gloves:
        bonus = CombatStats(attack: 2.5 * m, attackSpeed: 0.05 + 0.03 * tier, critChance: 0.02 * tier);
        break;
      case GearKind.boots:
        bonus = CombatStats(defense: 2 * m, maxHp: 8 * m, attackSpeed: 0.06 + 0.04 * tier);
        break;
      case GearKind.necklace:
        bonus = CombatStats(attack: 2.5 * m, critMultiplier: 0.06 * tier, maxHp: 6 * m);
        break;
      case GearKind.belt:
        bonus = CombatStats(defense: 2 * m, maxHp: 12 * m);
        break;
      case GearKind.bracelet:
        bonus = CombatStats(attack: 2 * m, critChance: 0.02 + 0.02 * tier);
        break;
      case GearKind.ring:
        bonus = CombatStats(
          attack: 2 * m,
          critChance: 0.03 + 0.02 * tier,
          critMultiplier: 0.05 * tier,
          armorPen: 2 * m * 0.5,
        );
        break;
    }

    return GearItem(
      id: _id(),
      name: name,
      kind: kind,
      rarity: rarity,
      bonus: bonus,
      itemLevel: level,
      weaponType: wt,
    );
  }
}
