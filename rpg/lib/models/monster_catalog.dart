// 몬스터 카탈로그 — 모든 몬스터의 단일 출처(이름/외형/스탯/레벨대).
// MonsterComponent(렌더/전투), WorldZones(섹터 스폰)이 공용으로 참조한다.
// 도트풍 절차적 렌더를 위해 shape(실루엣)·color·sizeFactor·speed 를 정의.
import 'combat_stats.dart';

// 절차적 렌더 실루엣 종류(알아볼 수 있는 형태 수준).
enum MonsterShape {
  blob, // 슬라임
  beast, // 4족 짐승(늑대/쥐)
  humanoidSmall, // 소형 인간형(고블린/코볼트/그렘린/임프)
  humanoid, // 인간형(오크/좀비/구울/리자드맨/뱀파이어)
  brute, // 거대 인간형(트롤/오우거)
  bat, // 박쥐
  skeleton, // 해골
  winged, // 날개 달린 인간형(서큐버스/하피/가고일)
  bull, // 뿔 달린 수인(미노타우로스)
  centaur, // 켄타우로스
  ghost, // 유령(천 모양)
  spectre, // 망령/레이스(누더기)
  block, // 골렘(돌덩이)
  mage, // 로브 마법사(리치)
  knight, // 갑옷 기사(듀라한, 머리 없음)
  serpent, // 뱀(바실리스크)
  chimera, // 키메라
  dragon, // 드래곤/와이번
  griffin, // 그리폰
}

class MonsterDef {
  final String id;
  final String name; // 한글 표시명
  final int color; // ARGB 본체색
  final double sizeFactor; // 기본 30px 기준 배수
  final double speed; // 이동 속도(px/s)
  final MonsterShape shape;
  final int baseHp;
  final CombatStats stats;
  final int minLv; // 등장 최저 존 레벨
  final int maxLv; // 등장 최고 존 레벨

  const MonsterDef({
    required this.id,
    required this.name,
    required this.color,
    required this.sizeFactor,
    required this.speed,
    required this.shape,
    required this.baseHp,
    required this.stats,
    required this.minLv,
    required this.maxLv,
  });
}

const List<MonsterDef> kMonsters = [
  // ── 초급(최하급~하급) ──
  MonsterDef(
      id: 'slime', name: '슬라임', color: 0xFF66BB6A, sizeFactor: 1.0, speed: 70, shape: MonsterShape.blob,
      baseHp: 38, minLv: 1, maxLv: 8,
      stats: CombatStats(attack: 10, defense: 2, armorPen: 0, critChance: 0.05, critMultiplier: 1.5, attackSpeed: 0.8)),
  MonsterDef(
      id: 'rat', name: '자이언트 랫', color: 0xFF8D6E63, sizeFactor: 0.75, speed: 130, shape: MonsterShape.beast,
      baseHp: 30, minLv: 1, maxLv: 7,
      stats: CombatStats(attack: 9, defense: 1, armorPen: 0, critChance: 0.08, critMultiplier: 1.5, attackSpeed: 1.7)),
  MonsterDef(
      id: 'kobold', name: '코볼트', color: 0xFFC0392B, sizeFactor: 0.85, speed: 95, shape: MonsterShape.humanoidSmall,
      baseHp: 50, minLv: 2, maxLv: 10,
      stats: CombatStats(attack: 13, defense: 3, armorPen: 1, critChance: 0.10, critMultiplier: 1.6, attackSpeed: 1.2)),
  MonsterDef(
      id: 'gremlin', name: '그렘린', color: 0xFF9CCC65, sizeFactor: 0.78, speed: 120, shape: MonsterShape.humanoidSmall,
      baseHp: 42, minLv: 2, maxLv: 9,
      stats: CombatStats(attack: 11, defense: 2, armorPen: 2, critChance: 0.14, critMultiplier: 1.6, attackSpeed: 1.5)),
  MonsterDef(
      id: 'goblin', name: '고블린', color: 0xFF8BC34A, sizeFactor: 0.95, speed: 90, shape: MonsterShape.humanoidSmall,
      baseHp: 65, minLv: 1, maxLv: 9,
      stats: CombatStats(attack: 16, defense: 5, armorPen: 2, critChance: 0.10, critMultiplier: 1.6, attackSpeed: 1.1)),
  MonsterDef(
      id: 'bat', name: '박쥐', color: 0xFF7E57C2, sizeFactor: 0.7, speed: 130, shape: MonsterShape.bat,
      baseHp: 40, minLv: 2, maxLv: 10,
      stats: CombatStats(attack: 12, defense: 1, armorPen: 1, critChance: 0.12, critMultiplier: 1.6, attackSpeed: 1.6)),

  // ── 하급~중급 ──
  MonsterDef(
      id: 'wolf', name: '늑대', color: 0xFF90A4AE, sizeFactor: 1.1, speed: 115, shape: MonsterShape.beast,
      baseHp: 85, minLv: 4, maxLv: 14,
      stats: CombatStats(attack: 19, defense: 4, armorPen: 3, critChance: 0.15, critMultiplier: 1.7, attackSpeed: 1.5)),
  MonsterDef(
      id: 'skeleton', name: '스켈레톤', color: 0xFFECEFF1, sizeFactor: 1.0, speed: 85, shape: MonsterShape.skeleton,
      baseHp: 100, minLv: 5, maxLv: 16,
      stats: CombatStats(attack: 22, defense: 9, armorPen: 5, critChance: 0.12, critMultiplier: 1.7, attackSpeed: 1.1)),
  MonsterDef(
      id: 'zombie', name: '좀비', color: 0xFF7CB342, sizeFactor: 1.05, speed: 52, shape: MonsterShape.humanoid,
      baseHp: 110, minLv: 5, maxLv: 15,
      stats: CombatStats(attack: 20, defense: 8, armorPen: 2, critChance: 0.06, critMultiplier: 1.5, attackSpeed: 0.7)),
  MonsterDef(
      id: 'lizardman', name: '리자드맨', color: 0xFF558B2F, sizeFactor: 1.1, speed: 95, shape: MonsterShape.humanoid,
      baseHp: 120, minLv: 6, maxLv: 16,
      stats: CombatStats(attack: 24, defense: 10, armorPen: 4, critChance: 0.12, critMultiplier: 1.7, attackSpeed: 1.2)),
  MonsterDef(
      id: 'orc', name: '오크', color: 0xFF4E7A33, sizeFactor: 1.25, speed: 75, shape: MonsterShape.humanoid,
      baseHp: 150, minLv: 8, maxLv: 20,
      stats: CombatStats(attack: 28, defense: 11, armorPen: 6, critChance: 0.10, critMultiplier: 1.8, attackSpeed: 0.9)),
  MonsterDef(
      id: 'ghoul', name: '구울', color: 0xFFAED581, sizeFactor: 1.0, speed: 100, shape: MonsterShape.humanoid,
      baseHp: 130, minLv: 8, maxLv: 18,
      stats: CombatStats(attack: 26, defense: 8, armorPen: 6, critChance: 0.14, critMultiplier: 1.7, attackSpeed: 1.2)),
  MonsterDef(
      id: 'harpy', name: '하피', color: 0xFF5C6BC0, sizeFactor: 1.0, speed: 120, shape: MonsterShape.winged,
      baseHp: 110, minLv: 9, maxLv: 19,
      stats: CombatStats(attack: 25, defense: 6, armorPen: 5, critChance: 0.18, critMultiplier: 1.8, attackSpeed: 1.6)),
  MonsterDef(
      id: 'imp', name: '임프', color: 0xFFE53935, sizeFactor: 0.78, speed: 120, shape: MonsterShape.winged,
      baseHp: 95, minLv: 9, maxLv: 19,
      stats: CombatStats(attack: 22, defense: 5, armorPen: 6, critChance: 0.16, critMultiplier: 1.7, attackSpeed: 1.5)),
  MonsterDef(
      id: 'gargoyle', name: '가고일', color: 0xFF78909C, sizeFactor: 1.1, speed: 85, shape: MonsterShape.winged,
      baseHp: 200, minLv: 10, maxLv: 22,
      stats: CombatStats(attack: 24, defense: 16, armorPen: 4, critChance: 0.08, critMultiplier: 1.6, attackSpeed: 0.9)),

  // ── 중급~상급 ──
  MonsterDef(
      id: 'troll', name: '트롤', color: 0xFF689F38, sizeFactor: 1.4, speed: 70, shape: MonsterShape.brute,
      baseHp: 280, minLv: 12, maxLv: 24,
      stats: CombatStats(attack: 34, defense: 14, armorPen: 5, critChance: 0.10, critMultiplier: 1.8, attackSpeed: 0.9)),
  MonsterDef(
      id: 'werewolf', name: '워울프', color: 0xFF5D4037, sizeFactor: 1.2, speed: 132, shape: MonsterShape.beast,
      baseHp: 190, minLv: 13, maxLv: 25,
      stats: CombatStats(attack: 36, defense: 10, armorPen: 8, critChance: 0.20, critMultiplier: 1.9, attackSpeed: 1.5)),
  MonsterDef(
      id: 'ogre', name: '오우거', color: 0xFFD7A87C, sizeFactor: 1.45, speed: 65, shape: MonsterShape.brute,
      baseHp: 320, minLv: 14, maxLv: 26,
      stats: CombatStats(attack: 40, defense: 16, armorPen: 6, critChance: 0.10, critMultiplier: 1.9, attackSpeed: 0.8)),
  MonsterDef(
      id: 'minotaur', name: '미노타우로스', color: 0xFF6D4C41, sizeFactor: 1.35, speed: 88, shape: MonsterShape.bull,
      baseHp: 300, minLv: 15, maxLv: 28,
      stats: CombatStats(attack: 42, defense: 15, armorPen: 8, critChance: 0.14, critMultiplier: 1.9, attackSpeed: 1.0)),
  MonsterDef(
      id: 'centaur', name: '켄타우로스', color: 0xFF8D6E63, sizeFactor: 1.3, speed: 122, shape: MonsterShape.centaur,
      baseHp: 240, minLv: 15, maxLv: 28,
      stats: CombatStats(attack: 38, defense: 12, armorPen: 10, critChance: 0.16, critMultiplier: 1.8, attackSpeed: 1.3)),

  // ── 언데드/마물(중~상급) ──
  MonsterDef(
      id: 'ghost', name: '고스트', color: 0xFFE0F7FA, sizeFactor: 0.95, speed: 80, shape: MonsterShape.ghost,
      baseHp: 150, minLv: 12, maxLv: 26,
      stats: CombatStats(attack: 30, defense: 5, armorPen: 20, critChance: 0.16, critMultiplier: 1.8, attackSpeed: 1.2)),
  MonsterDef(
      id: 'wraith', name: '레이스', color: 0xFF4DD0E1, sizeFactor: 1.1, speed: 95, shape: MonsterShape.spectre,
      baseHp: 180, minLv: 16, maxLv: 30,
      stats: CombatStats(attack: 32, defense: 6, armorPen: 12, critChance: 0.18, critMultiplier: 1.9, attackSpeed: 1.2)),
  MonsterDef(
      id: 'golem', name: '골렘', color: 0xFF795548, sizeFactor: 1.5, speed: 48, shape: MonsterShape.block,
      baseHp: 360, minLv: 18, maxLv: 32,
      stats: CombatStats(attack: 30, defense: 20, armorPen: 4, critChance: 0.06, critMultiplier: 1.6, attackSpeed: 0.7)),
  MonsterDef(
      id: 'stone_golem', name: '스톤 골렘', color: 0xFF9E9E9E, sizeFactor: 1.55, speed: 45, shape: MonsterShape.block,
      baseHp: 420, minLv: 20, maxLv: 34,
      stats: CombatStats(attack: 34, defense: 26, armorPen: 4, critChance: 0.05, critMultiplier: 1.6, attackSpeed: 0.6)),
  MonsterDef(
      id: 'basilisk', name: '바실리스크', color: 0xFF43A047, sizeFactor: 1.2, speed: 80, shape: MonsterShape.serpent,
      baseHp: 340, minLv: 22, maxLv: 38,
      stats: CombatStats(attack: 42, defense: 14, armorPen: 10, critChance: 0.16, critMultiplier: 1.9, attackSpeed: 1.0)),

  // ── 상급~보스급 ──
  MonsterDef(
      id: 'lich', name: '리치', color: 0xFF7E57C2, sizeFactor: 1.1, speed: 80, shape: MonsterShape.mage,
      baseHp: 300, minLv: 24, maxLv: 38,
      stats: CombatStats(attack: 44, defense: 12, armorPen: 16, critChance: 0.18, critMultiplier: 2.0, attackSpeed: 1.1)),
  MonsterDef(
      id: 'vampire', name: '뱀파이어', color: 0xFFB71C1C, sizeFactor: 1.05, speed: 100, shape: MonsterShape.humanoid,
      baseHp: 320, minLv: 25, maxLv: 40,
      stats: CombatStats(attack: 46, defense: 14, armorPen: 12, critChance: 0.22, critMultiplier: 2.0, attackSpeed: 1.3)),
  MonsterDef(
      id: 'dullahan', name: '듀라한', color: 0xFF455A64, sizeFactor: 1.2, speed: 92, shape: MonsterShape.knight,
      baseHp: 380, minLv: 26, maxLv: 40,
      stats: CombatStats(attack: 48, defense: 20, armorPen: 10, critChance: 0.16, critMultiplier: 1.9, attackSpeed: 1.0)),
  MonsterDef(
      id: 'succubus', name: '서큐버스', color: 0xFFD81B60, sizeFactor: 1.05, speed: 115, shape: MonsterShape.winged,
      baseHp: 280, minLv: 25, maxLv: 40,
      stats: CombatStats(attack: 44, defense: 10, armorPen: 14, critChance: 0.22, critMultiplier: 2.0, attackSpeed: 1.3)),
  MonsterDef(
      id: 'incubus', name: '인큐버스', color: 0xFF8E24AA, sizeFactor: 1.1, speed: 115, shape: MonsterShape.winged,
      baseHp: 290, minLv: 25, maxLv: 40,
      stats: CombatStats(attack: 46, defense: 11, armorPen: 14, critChance: 0.20, critMultiplier: 2.0, attackSpeed: 1.3)),
  MonsterDef(
      id: 'demon', name: '악마', color: 0xFFD32F2F, sizeFactor: 1.35, speed: 90, shape: MonsterShape.winged,
      baseHp: 360, minLv: 24, maxLv: 40,
      stats: CombatStats(attack: 40, defense: 14, armorPen: 10, critChance: 0.16, critMultiplier: 2.0, attackSpeed: 1.1)),

  // ── 환수/최종보스급 ──
  MonsterDef(
      id: 'chimera', name: '키메라', color: 0xFFEF6C00, sizeFactor: 1.4, speed: 90, shape: MonsterShape.chimera,
      baseHp: 520, minLv: 32, maxLv: 46,
      stats: CombatStats(attack: 54, defense: 18, armorPen: 12, critChance: 0.18, critMultiplier: 2.1, attackSpeed: 1.1)),
  MonsterDef(
      id: 'griffin', name: '그리폰', color: 0xFFC9A227, sizeFactor: 1.35, speed: 130, shape: MonsterShape.griffin,
      baseHp: 480, minLv: 33, maxLv: 48,
      stats: CombatStats(attack: 52, defense: 16, armorPen: 14, critChance: 0.20, critMultiplier: 2.0, attackSpeed: 1.4)),
  MonsterDef(
      id: 'wyvern', name: '와이번', color: 0xFF00897B, sizeFactor: 1.4, speed: 120, shape: MonsterShape.dragon,
      baseHp: 560, minLv: 35, maxLv: 50,
      stats: CombatStats(attack: 58, defense: 18, armorPen: 14, critChance: 0.18, critMultiplier: 2.1, attackSpeed: 1.2)),
  MonsterDef(
      id: 'dragon', name: '드래곤', color: 0xFFC62828, sizeFactor: 1.5, speed: 90, shape: MonsterShape.dragon,
      baseHp: 800, minLv: 38, maxLv: 50,
      stats: CombatStats(attack: 68, defense: 24, armorPen: 16, critChance: 0.20, critMultiplier: 2.2, attackSpeed: 1.1)),
];

final Map<String, MonsterDef> kMonsterById = {for (final m in kMonsters) m.id: m};

MonsterDef monsterDef(String id) =>
    kMonsterById[id] ??
    const MonsterDef(
        id: 'slime', name: '몬스터', color: 0xFF90A4AE, sizeFactor: 1.0, speed: 80, shape: MonsterShape.blob,
        baseHp: 40, minLv: 1, maxLv: 50,
        stats: CombatStats(attack: 12, defense: 3, armorPen: 0, critChance: 0.05, critMultiplier: 1.5, attackSpeed: 0.9));
