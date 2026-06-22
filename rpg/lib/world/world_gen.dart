// ── 서버측 월드 데이터 연산(순수 로직, Flame/Flutter 비의존) ──
// 보로노이 셀 기반 오픈월드:
//  - 세계를 격자+지터로 흩뿌린 "마을(안전지대)" 중심점들로 분할(각 점이 셀 중심).
//  - 임의 좌표의 레벨 = "가장 가까운 마을"로부터의 거리에 비례(1→50) + 퍼린 노이즈.
//  - 셀 경계를 넘으면 다음 마을이 nearest 가 되어 거리가 줄고 레벨이 다시 낮아진다(순환).
//  - 경계 부근에서는 노이즈 진폭을 0으로 수렴시켜 인접 군락 간 급변을 막는다(평활화).
// 고정 시드를 쓰므로 모든 클라이언트가 동일한 월드를 본다(서버가 없어도 결정론적으로 일치).
import 'dart:math';

import 'package:fast_noise/fast_noise.dart';

class TownPoint {
  final int gx;
  final int gy;
  final double x;
  final double y;
  const TownPoint(this.gx, this.gy, this.x, this.y);

  double distTo(double px, double py) {
    final dx = x - px, dy = y - py;
    return sqrt(dx * dx + dy * dy);
  }
}

class WorldGen {
  final int seed;
  final double cellSize; // 마을 간격(보로노이 격자 피치)
  final double townRadius; // 안전지대 반경
  final double maxLevelRadius; // 이 거리에서 레벨이 최대치에 근접
  final double jitter; // 격자 지터 비율(0~0.5)
  final int maxLevel;
  final double homeX;
  final double homeY;

  late final PerlinNoise _noise;

  WorldGen({
    this.seed = 0x5A0E,
    this.cellSize = 6400,
    this.townRadius = 360,
    this.jitter = 0.30,
    this.maxLevel = 50,
    this.homeX = 1000,
    this.homeY = 1000,
    double? maxLevelRadius,
  }) : maxLevelRadius = maxLevelRadius ?? cellSize * 0.55 {
    _noise = PerlinNoise(seed: seed & 0x7FFFFFFF, frequency: 0.00045);
  }

  // 격자 셀(gx,gy)의 마을 좌표(결정론적 지터). 홈 셀(0,0)은 지터 없이 정확히 home.
  TownPoint townForCell(int gx, int gy) {
    if (gx == 0 && gy == 0) return TownPoint(0, 0, homeX, homeY);
    final h = _hash(gx, gy);
    final jx = ((h & 0xFFFF) / 65535.0 - 0.5) * cellSize * jitter * 2;
    final jy = (((h >> 16) & 0xFFFF) / 65535.0 - 0.5) * cellSize * jitter * 2;
    return TownPoint(gx, gy, homeX + gx * cellSize + jx, homeY + gy * cellSize + jy);
  }

  int _hash(int gx, int gy) {
    var h = seed ^ (gx * 73856093) ^ (gy * 19349663);
    h = (h ^ (h >> 13)) * 1274126177;
    return h & 0x7FFFFFFF;
  }

  // 가장 가까운/두번째로 가까운 마을(보로노이 셀 판정 + 경계 평활화용).
  ({TownPoint near, double dNear, TownPoint second, double dSecond}) nearest2(double x, double y) {
    final cgx = ((x - homeX) / cellSize).round();
    final cgy = ((y - homeY) / cellSize).round();
    TownPoint near = townForCell(cgx, cgy);
    double dNear = double.infinity, dSecond = double.infinity;
    TownPoint second = near;
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        final t = townForCell(cgx + dx, cgy + dy);
        final d = t.distTo(x, y);
        if (d < dNear) {
          dSecond = dNear;
          second = near;
          dNear = d;
          near = t;
        } else if (d < dSecond) {
          dSecond = d;
          second = t;
        }
      }
    }
    return (near: near, dNear: dNear, second: second, dSecond: dSecond);
  }

  bool inSafeZone(double x, double y) => nearest2(x, y).dNear <= townRadius;

  static double _smoothstep(double t) {
    t = t.clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  // 연속 레벨(1.0~maxLevel). 경계에서 진폭 0 → 평활.
  double levelRaw(double x, double y) {
    final r = nearest2(x, y);
    if (r.dNear <= townRadius) return 1;

    // 거리 비례 기본 레벨(마을→경계 = 1→max).
    final ramp = ((r.dNear - townRadius) / (maxLevelRadius - townRadius)).clamp(0.0, 1.0);
    var level = 1 + (maxLevel - 1) * _smoothstep(ramp);

    // 퍼린 변동 — 마을 근처/셀 경계 근처에서는 진폭을 줄여 인접 군락 급변 차단(평활화).
    final amp = maxLevel * 0.12;
    final edge = ((r.dSecond - r.dNear) / (cellSize * 0.5)).clamp(0.0, 1.0); // 경계서 0
    final townFade = ((r.dNear - townRadius) / (maxLevelRadius * 0.35)).clamp(0.0, 1.0);
    final n = _noise.getNoise2(x, y); // -1..1
    level += n * amp * edge * townFade;

    return level.clamp(1.0, maxLevel.toDouble());
  }

  int levelAt(double x, double y) => levelRaw(x, y).round().clamp(1, maxLevel);

  // 위험 등급(에셋/UI 연동): 0=초급(1~10) 1=중급(11~30) 2=고급(31~50).
  int dangerTier(int level) => level <= 10 ? 0 : (level <= 30 ? 1 : 2);

  // 렌더 영역 내 마을들(맵/미니맵 표시 · 에셋 차단구역 판정).
  List<TownPoint> townsNear(double cx, double cy, double radius) {
    final out = <TownPoint>[];
    final span = (radius / cellSize).ceil() + 1;
    final cgx = ((cx - homeX) / cellSize).round();
    final cgy = ((cy - homeY) / cellSize).round();
    for (var dy = -span; dy <= span; dy++) {
      for (var dx = -span; dx <= span; dx++) {
        final t = townForCell(cgx + dx, cgy + dy);
        final ddx = t.x - cx, ddy = t.y - cy;
        if (ddx * ddx + ddy * ddy <= radius * radius) out.add(t);
      }
    }
    return out;
  }

  // 주요 이동로(인접 마을을 잇는 길) 근처인지 — 에셋 생성 차단 구역.
  bool onRoad(double x, double y, double width) {
    final r = nearest2(x, y);
    // 가장 가까운 마을과 4방향 이웃 마을을 잇는 선분까지의 거리.
    for (final nb in const [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
      final t2 = townForCell(r.near.gx + nb[0], r.near.gy + nb[1]);
      if (_distToSegment(x, y, r.near.x, r.near.y, t2.x, t2.y) < width) return true;
    }
    return false;
  }

  double _distToSegment(double px, double py, double ax, double ay, double bx, double by) {
    final dx = bx - ax, dy = by - ay;
    final len2 = dx * dx + dy * dy;
    if (len2 == 0) return sqrt((px - ax) * (px - ax) + (py - ay) * (py - ay));
    var t = ((px - ax) * dx + (py - ay) * dy) / len2;
    t = t.clamp(0.0, 1.0);
    final cx = ax + t * dx, cy = ay + t * dy;
    return sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy));
  }
}
