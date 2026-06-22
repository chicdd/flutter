// 인벤토리 공용 아이템 인터페이스 + 기타(소비/재료) 아이템.
// 가방은 장비(GearItem)와 기타(MiscItem)를 함께 담는다. 기타 아이템은 같은 종류끼리 스택된다.
// locked: 우클릭 판매 잠금(실수 판매 방지) — 모든 일괄/단축 판매에서 제외된다.
import 'gear.dart';

abstract class BagItem {
  String get id;
  String get name;
  Rarity get rarity;
  bool get locked;
  set locked(bool v);
}

// 주의: 새 종류는 반드시 끝에 추가(저장 index 호환).
enum MiscKind { healthPotion, monsterHide, magicCrystal, ancientCoin, potionMedium, potionLarge, townScroll }

extension MiscKindX on MiscKind {
  String get name => switch (this) {
        MiscKind.healthPotion => '초급 포션',
        MiscKind.potionMedium => '중급 포션',
        MiscKind.potionLarge => '고급 포션',
        MiscKind.townScroll => '마을 귀환 주문서',
        MiscKind.monsterHide => '몬스터 가죽',
        MiscKind.magicCrystal => '마력 결정',
        MiscKind.ancientCoin => '고대 주화',
      };

  Rarity get rarity => switch (this) {
        MiscKind.healthPotion => Rarity.common,
        MiscKind.potionMedium => Rarity.uncommon,
        MiscKind.potionLarge => Rarity.rare,
        MiscKind.townScroll => Rarity.uncommon,
        MiscKind.monsterHide => Rarity.common,
        MiscKind.magicCrystal => Rarity.rare,
        MiscKind.ancientCoin => Rarity.epic,
      };

  int get sellUnit => switch (this) {
        MiscKind.healthPotion => 8,
        MiscKind.potionMedium => 20,
        MiscKind.potionLarge => 45,
        MiscKind.townScroll => 15,
        MiscKind.monsterHide => 5,
        MiscKind.magicCrystal => 40,
        MiscKind.ancientCoin => 120,
      };

  // 회복 비율(0 이면 회복 아이템 아님).
  double get healPercent => switch (this) {
        MiscKind.healthPotion => 0.30,
        MiscKind.potionMedium => 0.55,
        MiscKind.potionLarge => 0.80,
        _ => 0.0,
      };

  bool get usableHeal => healPercent > 0;
  bool get isTownScroll => this == MiscKind.townScroll;
  bool get isMaterial => this == MiscKind.monsterHide || this == MiscKind.magicCrystal || this == MiscKind.ancientCoin;
}

class MiscItem implements BagItem {
  @override
  final String id;
  final MiscKind kind;
  int quantity;
  @override
  bool locked;

  MiscItem({required this.id, required this.kind, this.quantity = 1, this.locked = false});

  @override
  String get name => kind.name;
  @override
  Rarity get rarity => kind.rarity;

  int get sellPrice => kind.sellUnit;

  Map<String, dynamic> toJson() =>
      {'id': id, 'kind': kind.index, 'qty': quantity, if (locked) 'lk': true};

  factory MiscItem.fromJson(Map<String, dynamic> j) => MiscItem(
        id: j['id'] as String,
        kind: MiscKind.values[(j['kind'] as num).toInt()],
        quantity: (j['qty'] as num?)?.toInt() ?? 1,
        locked: j['lk'] == true,
      );
}
