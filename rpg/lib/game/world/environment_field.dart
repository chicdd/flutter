// ── 클라이언트측 에셋 스폰/해제 관리(런타임 절차적 배치 + 뷰포트 GC) ──
// 포아송 디스크 샘플링으로 청크마다 나무/돌/건물을 서로 겹치지 않게 배치한다.
//  - 시드 = (월드 시드 ^ 청크좌표) → 전 클라이언트 동일 배치(결정론).
//  - 마을 중심/주요 이동로(도로)에는 생성 차단(Exclusion Zone).
//  - 좌표의 위험 등급(WorldZones.dangerTier)으로 외형(StructureKind/tier)을 결정.
//  - 시야(Viewport+여유)를 벗어난 청크의 컴포넌트는 자동 파괴(GC)로 메모리/CPU 회수.
import 'dart:math';
import 'dart:ui' show Offset;

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../components/structure.dart';
import 'zones.dart';

class EnvironmentField extends Component with HasGameReference<FlameGame> {
  final int seed;
  final double chunkSize;
  final double minDist; // 포아송 최소 간격(겹침 방지)
  final double viewMargin; // 시야 밖 여유(미리 생성/늦게 해제)
  final double roadWidth; // 도로 차단 폭
  final double refreshInterval;

  EnvironmentField({
    required this.seed,
    this.chunkSize = 512,
    this.minDist = 130,
    this.viewMargin = 300,
    this.roadWidth = 120,
    this.refreshInterval = 0.25,
  }) {
    priority = -8; // 지형(-10) 위, 캐릭터 아래
  }

  // 로드된 청크 → 그 청크의 구조물 컴포넌트들.
  final Map<int, List<StructureComponent>> _loaded = {};
  double _timer = 0;

  int _chunkKey(int cx, int cy) => (cx & 0xFFFF) | ((cy & 0xFFFF) << 16);

  @override
  void update(double dt) {
    super.update(dt);
    _timer -= dt;
    if (_timer > 0) return;
    _timer = refreshInterval;
    _refresh();
  }

  void _refresh() {
    final view = game.camera.visibleWorldRect.inflate(viewMargin);
    final c0 = (view.left / chunkSize).floor();
    final c1 = (view.right / chunkSize).ceil();
    final r0 = (view.top / chunkSize).floor();
    final r1 = (view.bottom / chunkSize).ceil();

    // 1) 보이는 청크 생성.
    final wanted = <int>{};
    for (var cy = r0; cy <= r1; cy++) {
      for (var cx = c0; cx <= c1; cx++) {
        final key = _chunkKey(cx, cy);
        wanted.add(key);
        if (!_loaded.containsKey(key)) _loadChunk(cx, cy, key);
      }
    }

    // 2) 시야 밖 청크 해제(GC).
    final stale = _loaded.keys.where((k) => !wanted.contains(k)).toList();
    for (final k in stale) {
      for (final comp in _loaded[k]!) {
        comp.removeFromParent();
      }
      _loaded.remove(k);
    }
  }

  void _loadChunk(int cx, int cy, int key) {
    final originX = cx * chunkSize;
    final originY = cy * chunkSize;
    final rng = Random(seed ^ (cx * 73856093) ^ (cy * 19349663));
    final points = _poissonDisk(rng);

    final comps = <StructureComponent>[];
    for (final p in points) {
      final wx = originX + p.dx;
      final wy = originY + p.dy;
      // 차단 구역: 마을 안전지대 / 주요 이동로.
      if (WorldZones.inSafeZone(wx, wy)) continue;
      if (WorldZones.onRoad(wx, wy, roadWidth)) continue;

      final tier = WorldZones.dangerTier(WorldZones.levelAt(wx, wy));
      final kind = _pickKind(tier, rng);
      final scale = 0.8 + rng.nextDouble() * 0.5;
      final comp = StructureComponent(
        kind: kind,
        tier: tier,
        variantSeed: (wx * 31 + wy * 17).toInt(),
        worldPos: Vector2(wx, wy),
        scale: scale,
      );
      comps.add(comp);
      add(comp);
    }
    _loaded[key] = comps;
  }

  StructureKind _pickKind(int tier, Random rng) {
    final r = rng.nextDouble();
    // 등급별 가중치(고위험일수록 폐허/바위 비중↑).
    final treeW = tier == 2 ? 0.45 : 0.60;
    final rockW = tier == 2 ? 0.35 : (tier == 1 ? 0.30 : 0.25);
    if (r < treeW) return StructureKind.tree;
    if (r < treeW + rockW) return StructureKind.rock;
    return StructureKind.building;
  }

  // Bridson 포아송 디스크 샘플링(청크 로컬 좌표). 결정론적(rng 주입).
  List<Offset> _poissonDisk(Random rng) {
    final r = minDist;
    final cell = r / sqrt2;
    final cols = (chunkSize / cell).ceil();
    final rows = (chunkSize / cell).ceil();
    final grid = List<Offset?>.filled(cols * rows, null);
    final active = <Offset>[];
    final out = <Offset>[];

    int gi(double x, double y) => (y / cell).floor() * cols + (x / cell).floor();

    bool fits(Offset c) {
      if (c.dx < 0 || c.dx >= chunkSize || c.dy < 0 || c.dy >= chunkSize) return false;
      final gx = (c.dx / cell).floor();
      final gy = (c.dy / cell).floor();
      for (var yy = max(0, gy - 2); yy <= min(rows - 1, gy + 2); yy++) {
        for (var xx = max(0, gx - 2); xx <= min(cols - 1, gx + 2); xx++) {
          final o = grid[yy * cols + xx];
          if (o != null && (o - c).distance < r) return false;
        }
      }
      return true;
    }

    final first = Offset(rng.nextDouble() * chunkSize, rng.nextDouble() * chunkSize);
    active.add(first);
    out.add(first);
    grid[gi(first.dx, first.dy)] = first;

    const k = 20;
    while (active.isNotEmpty) {
      final idx = rng.nextInt(active.length);
      final center = active[idx];
      var found = false;
      for (var i = 0; i < k; i++) {
        final ang = rng.nextDouble() * 2 * pi;
        final rad = r * (1 + rng.nextDouble());
        final cand = Offset(center.dx + cos(ang) * rad, center.dy + sin(ang) * rad);
        if (fits(cand)) {
          active.add(cand);
          out.add(cand);
          grid[gi(cand.dx, cand.dy)] = cand;
          found = true;
          break;
        }
      }
      if (!found) active.removeAt(idx);
    }
    return out;
  }
}
