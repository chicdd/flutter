// 처치 보상 루팅 — 골드/경험치/장비/기타. 엘리트는 배율과 희귀 등급 확률이 크게 높다.
import 'dart:math';

import 'gear.dart';
import 'items.dart';

class LootRoll {
  final int gold;
  final int exp;
  final List<BagItem> items;
  const LootRoll({required this.gold, required this.exp, required this.items});
}

class _Base {
  final int gold;
  final int exp;
  const _Base(this.gold, this.exp);
}

class LootSystem {
  static int _counter = 0;
  static String _id() => 'm${DateTime.now().microsecondsSinceEpoch}_${_counter++}';

  static _Base _baseFor(String templateId) {
    switch (templateId) {
      case 'slime':
        return const _Base(6, 14);
      case 'bat':
        return const _Base(8, 16);
      case 'goblin':
        return const _Base(13, 24);
      case 'wolf':
        return const _Base(16, 30);
      case 'skeleton':
        return const _Base(22, 40);
      case 'orc':
        return const _Base(30, 55);
      case 'wraith':
        return const _Base(36, 70);
      case 'golem':
        return const _Base(45, 85);
      case 'demon':
        return const _Base(60, 120);
      default:
        return const _Base(10, 18);
    }
  }

  static Rarity _normalRarity(Random rng) {
    final r = rng.nextDouble();
    if (r < 0.70) return Rarity.common;
    if (r < 0.93) return Rarity.uncommon;
    return Rarity.rare;
  }

  static Rarity _eliteRarity(Random rng) {
    final r = rng.nextDouble();
    if (r < 0.28) return Rarity.uncommon;
    if (r < 0.58) return Rarity.rare;
    if (r < 0.83) return Rarity.epic;
    if (r < 0.96) return Rarity.legendary;
    return Rarity.mythic; // 4% 신화
  }

  static LootRoll roll({
    required String templateId,
    required bool elite,
    required int playerLevel,
    required Random rng,
  }) {
    final base = _baseFor(templateId);
    final items = <BagItem>[];

    if (elite) {
      final goldMult = 3 + rng.nextInt(4); // 3~6배
      final gold = base.gold * goldMult + 30 + playerLevel * 5;
      final exp = base.exp * 3 + 20;
      if (rng.nextDouble() < 0.90) {
        items.add(GearGenerator.random(level: playerLevel, rarity: _eliteRarity(rng), rng: rng));
      }
      if (rng.nextDouble() < 0.30) {
        items.add(GearGenerator.random(level: playerLevel, rarity: _eliteRarity(rng), rng: rng));
      }
      // 엘리트 특별 기타 보상.
      items.add(MiscItem(id: _id(), kind: MiscKind.magicCrystal, quantity: 1 + rng.nextInt(2)));
      if (rng.nextDouble() < 0.5) items.add(MiscItem(id: _id(), kind: MiscKind.ancientCoin));
      if (rng.nextDouble() < 0.6) items.add(MiscItem(id: _id(), kind: MiscKind.healthPotion));
      return LootRoll(gold: gold, exp: exp, items: items);
    }

    final gold = base.gold + rng.nextInt(base.gold + 1);
    final exp = base.exp;
    if (rng.nextDouble() < 0.18) {
      items.add(GearGenerator.random(level: playerLevel, rarity: _normalRarity(rng), rng: rng));
    }
    // 일반 기타 드랍(물약/가죽).
    if (rng.nextDouble() < 0.20) items.add(MiscItem(id: _id(), kind: MiscKind.healthPotion));
    if (rng.nextDouble() < 0.30) items.add(MiscItem(id: _id(), kind: MiscKind.monsterHide));
    return LootRoll(gold: gold, exp: exp, items: items);
  }
}
