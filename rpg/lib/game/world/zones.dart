// 게임용 존 파사드 — 서버측 WorldGen(보로노이 월드)을 감싸 기존 호출부와 호환 유지.
// 레벨/마을/안전지대 판정은 모두 WorldGen 결정론 로직에 위임(전 클라이언트 동일).
import 'dart:math';

import '../../models/monster_catalog.dart';
import '../../world/world_gen.dart';

class WorldZones {
  // 모든 클라이언트가 같은 월드를 보도록 고정 시드.
  static final WorldGen gen = WorldGen(seed: 0x5A0E);

  static int get seed => gen.seed;
  static int get maxLevel => gen.maxLevel;

  // 홈 마을(기존 TownComponent/NPC 위치와 일치).
  static Vector2like get townCenter => Vector2like(gen.homeX, gen.homeY);
  static double get townRadius => gen.townRadius;

  // 위치 → 몬스터 레벨대(1~50). 보로노이 거리 비례 + 퍼린 + 경계 평활화.
  static int levelAt(double x, double y) => gen.levelAt(x, y);

  static int dangerTier(int level) => gen.dangerTier(level);
  static bool inSafeZone(double x, double y) => gen.inSafeZone(x, y);
  static bool onRoad(double x, double y, double width) => gen.onRoad(x, y, width);

  // 렌더 영역 내 마을 목록(맵/미니맵).
  static List<Vector2like> townsNear(double cx, double cy, double radius) =>
      [for (final t in gen.townsNear(cx, cy, radius)) Vector2like(t.x, t.y)];

  // 몬스터 레벨대 → 난이도 배수(MonsterComponent.levelScale 과 동일 공식).
  static double scaleForLevel(int level) => 1 + (level - 1) * 0.14;

  // 존 레벨에 맞는 몬스터 선택(카탈로그의 minLv~maxLv 범위로 필터). (templateId, baseHp).
  static (String, int) pickMonster(int level, Random rng) {
    var candidates = kMonsters.where((m) => level >= m.minLv && level <= m.maxLv).toList();
    if (candidates.isEmpty) {
      candidates = kMonsters.where((m) => level >= m.minLv).toList();
      if (candidates.isEmpty) candidates = [kMonsters.first];
    }
    final pick = candidates[rng.nextInt(candidates.length)];
    return (pick.id, pick.baseHp);
  }
}

// flame 의존 없이 좌표만 담는 가벼운 구조(맵 오버레이/존 계산 공용).
class Vector2like {
  final double x;
  final double y;
  const Vector2like(this.x, this.y);
}
