// 전투 스탯 + 데미지 공식 (RPG 코어).
// 데미지 = max(최소, 공격력 - max(0, 방어력 - 방어구관통)) → 크리티컬 시 배수 적용.
// 모든 필드는 가산(additive) — 기본 스탯 + 장비 보너스 + 레벨 보너스를 operator+ 로 합산한다.
import 'dart:math';

class CombatStats {
  final double attack; // 공격력
  final double defense; // 방어력
  final double armorPen; // 방어구 관통력(방어력 상쇄)
  final double critChance; // 크리티컬 확률(0~1)
  final double critMultiplier; // 크리티컬 데미지 배수
  final double attackSpeed; // 초당 공격 횟수
  final double maxHp; // 최대 체력 보너스

  const CombatStats({
    this.attack = 0,
    this.defense = 0,
    this.armorPen = 0,
    this.critChance = 0,
    this.critMultiplier = 0,
    this.attackSpeed = 0,
    this.maxHp = 0,
  });

  CombatStats operator +(CombatStats o) => CombatStats(
        attack: attack + o.attack,
        defense: defense + o.defense,
        armorPen: armorPen + o.armorPen,
        critChance: critChance + o.critChance,
        critMultiplier: critMultiplier + o.critMultiplier,
        attackSpeed: attackSpeed + o.attackSpeed,
        maxHp: maxHp + o.maxHp,
      );

  Map<String, dynamic> toJson() => {
        'a': attack,
        'd': defense,
        'ap': armorPen,
        'cc': critChance,
        'cm': critMultiplier,
        'as': attackSpeed,
        'hp': maxHp,
      };

  factory CombatStats.fromJson(Map<String, dynamic> j) => CombatStats(
        attack: (j['a'] as num?)?.toDouble() ?? 0,
        defense: (j['d'] as num?)?.toDouble() ?? 0,
        armorPen: (j['ap'] as num?)?.toDouble() ?? 0,
        critChance: (j['cc'] as num?)?.toDouble() ?? 0,
        critMultiplier: (j['cm'] as num?)?.toDouble() ?? 0,
        attackSpeed: (j['as'] as num?)?.toDouble() ?? 0,
        maxHp: (j['hp'] as num?)?.toDouble() ?? 0,
      );

  CombatStats scaled(double f) => CombatStats(
        attack: attack * f,
        defense: defense * f,
        armorPen: armorPen * f,
        critChance: critChance,
        critMultiplier: critMultiplier,
        attackSpeed: attackSpeed,
        maxHp: maxHp * f,
      );

  // 플레이어 기본 스탯(레벨 1, 장비 없음).
  factory CombatStats.basePlayer() => const CombatStats(
        attack: 24,
        defense: 6,
        armorPen: 4,
        critChance: 0.20,
        critMultiplier: 1.8,
        attackSpeed: 1.4,
        maxHp: 100,
      );

  // 몬스터 템플릿별 스탯(기본 난이도 상향 반영).
  factory CombatStats.forMonster(String templateId) {
    switch (templateId) {
      case 'slime':
        return const CombatStats(
            attack: 10, defense: 2, armorPen: 0, critChance: 0.05, critMultiplier: 1.5, attackSpeed: 0.8);
      case 'bat':
        return const CombatStats(
            attack: 12, defense: 1, armorPen: 1, critChance: 0.12, critMultiplier: 1.6, attackSpeed: 1.6);
      case 'goblin':
        return const CombatStats(
            attack: 16, defense: 5, armorPen: 2, critChance: 0.10, critMultiplier: 1.6, attackSpeed: 1.1);
      case 'wolf':
        return const CombatStats(
            attack: 19, defense: 4, armorPen: 3, critChance: 0.15, critMultiplier: 1.7, attackSpeed: 1.5);
      case 'skeleton':
        return const CombatStats(
            attack: 22, defense: 9, armorPen: 5, critChance: 0.12, critMultiplier: 1.7, attackSpeed: 1.1);
      case 'orc':
        return const CombatStats(
            attack: 28, defense: 11, armorPen: 6, critChance: 0.10, critMultiplier: 1.8, attackSpeed: 0.9);
      case 'wraith':
        return const CombatStats(
            attack: 32, defense: 6, armorPen: 12, critChance: 0.18, critMultiplier: 1.9, attackSpeed: 1.2);
      case 'golem':
        return const CombatStats(
            attack: 30, defense: 20, armorPen: 4, critChance: 0.06, critMultiplier: 1.6, attackSpeed: 0.7);
      case 'demon':
        return const CombatStats(
            attack: 40, defense: 14, armorPen: 10, critChance: 0.16, critMultiplier: 2.0, attackSpeed: 1.1);
      default:
        return const CombatStats(
            attack: 12, defense: 3, armorPen: 0, critChance: 0.05, critMultiplier: 1.5, attackSpeed: 0.9);
    }
  }
}

class DamageResult {
  final int amount;
  final bool crit;
  const DamageResult(this.amount, this.crit);
}

// 공격자→방어자 데미지 산출. 최소 1 보장.
DamageResult resolveDamage(CombatStats attacker, CombatStats defender, Random rng) {
  final effectiveDef = (defender.defense - attacker.armorPen).clamp(0.0, double.infinity);
  var raw = attacker.attack - effectiveDef;
  if (raw < 1) raw = 1;
  final crit = rng.nextDouble() < attacker.critChance;
  if (crit) raw *= (attacker.critMultiplier <= 0 ? 1.5 : attacker.critMultiplier);
  return DamageResult(raw.round(), crit);
}
