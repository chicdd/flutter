// 전체 맵 오버레이(M 키) — 현재 화면보다 5배 넓은 영역을 한눈에.
//  - 배경: 섹터 존 레벨을 내 레벨과 비교해 색칠(파랑=안전, 초록=적정, 주황=주의, 빨강=위험)
//  - 위험 구역(내 레벨보다 한참 높은 곳 + 몬스터 밀집)은 빨간 경고 범위로 강조
//  - 접속한 다른 플레이어는 점으로 표시, 마우스를 올리면 닉네임/레벨 툴팁
//  - 몬스터는 작은 점으로 표시
import 'dart:async';

import 'package:flutter/material.dart';

import '../game/rpg_game.dart';
import '../game/world/zones.dart';
import '../net/multiplayer.dart';

class WorldMapOverlay extends StatefulWidget {
  final RpgGame game;
  final MultiplayerService? mp;
  final int playerLevel;
  final String playerName;
  final VoidCallback onClose;

  const WorldMapOverlay({
    super.key,
    required this.game,
    required this.mp,
    required this.playerLevel,
    required this.playerName,
    required this.onClose,
  });

  @override
  State<WorldMapOverlay> createState() => _WorldMapOverlayState();
}

class _Dot {
  final String name;
  final int level;
  final Offset screen;
  const _Dot(this.name, this.level, this.screen);
}

class _WorldMapOverlayState extends State<WorldMapOverlay> {
  Timer? _ticker;
  _Dot? _hovered;
  Offset _cursor = Offset.zero;

  @override
  void initState() {
    super.initState();
    // 플레이어/몬스터가 움직이므로 주기적으로 갱신.
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final mapArea = Rect.fromLTWH(0, 0, size.width, size.height);

    final player = widget.game.playerWorldPos;
    final visible = widget.game.camera.visibleWorldRect;
    // 현재 보이는 영역의 5배를 같은 화면에 → 5배 축소.
    final worldViewW = visible.width * 5;
    final scale = (worldViewW <= 0) ? 0.05 : mapArea.width / worldViewW;

    Offset w2s(double wx, double wy) =>
        mapArea.center + Offset((wx - player.x) * scale, (wy - player.y) * scale);

    // 접속한 다른 플레이어(같은 매치 릴레이).
    final dots = <_Dot>[];
    final mp = widget.mp;
    if (mp != null) {
      for (final p in mp.players.values) {
        dots.add(_Dot(p.name, p.level, w2s(p.x, p.y)));
      }
    }

    // 호버 판정(가장 가까운 점, 14px 이내).
    _Dot? hov;
    var best = 16.0;
    for (final d in dots) {
      final dist = (d.screen - _cursor).distance;
      if (dist < best) {
        best = dist;
        hov = d;
      }
    }
    _hovered = hov;

    final monsters = widget.game.monsterMarkers();

    return Positioned.fill(
      child: MouseRegion(
        onHover: (e) => setState(() => _cursor = e.localPosition),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _MapPainter(
                  mapArea: mapArea,
                  player: player,
                  scale: scale,
                  playerLevel: widget.playerLevel,
                  monsters: monsters,
                  dots: dots,
                ),
              ),
            ),

            // 상단 바: 제목 + 범례 + 닫기.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.map, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text('전체 지도',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 16),
                      Expanded(child: _legend()),
                      IconButton(
                        tooltip: '닫기 (M)',
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 호버 툴팁.
            if (_hovered != null)
              Positioned(
                left: (_hovered!.screen.dx + 12).clamp(0.0, size.width - 160),
                top: (_hovered!.screen.dy - 8).clamp(0.0, size.height - 60),
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF64B5F6)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_hovered!.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('Lv.${_hovered!.level}',
                            style: const TextStyle(color: Color(0xFF90CAF9), fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),

            // 하단 안내.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    '내 위치를 중심으로 주변 5배 영역 · 빨간 구역=고레벨 위험지대 · 점=접속 유저(마우스 오버) · M 닫기',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend() {
    Widget item(Color c, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 4),
          Text(t, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ]);
    return Wrap(spacing: 12, runSpacing: 4, children: [
      item(const Color(0xFF2E7D9A), '안전'),
      item(const Color(0xFF388E3C), '적정'),
      item(const Color(0xFFF9A825), '주의'),
      item(const Color(0xFFD32F2F), '위험'),
    ]);
  }
}

class _MapPainter extends CustomPainter {
  final Rect mapArea;
  final dynamic player; // Vector2 (x,y)
  final double scale;
  final int playerLevel;
  final List<({double x, double y, int level, bool elite})> monsters;
  final List<_Dot> dots;

  _MapPainter({
    required this.mapArea,
    required this.player,
    required this.scale,
    required this.playerLevel,
    required this.monsters,
    required this.dots,
  });

  // 존 레벨과 내 레벨 차이로 색 결정.
  Color _zoneColor(int zoneLevel) {
    final diff = zoneLevel - playerLevel;
    if (diff <= -3) return const Color(0xFF2E7D9A); // 안전(파랑)
    if (diff <= 2) return const Color(0xFF388E3C); // 적정(초록)
    if (diff <= 6) return const Color(0xFFF9A825); // 주의(주황)
    return const Color(0xFFD32F2F); // 위험(빨강)
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0B0F14));

    final px = player.x as double;
    final py = player.y as double;
    Offset w2s(double wx, double wy) =>
        mapArea.center + Offset((wx - px) * scale, (wy - py) * scale);

    // 1) 배경 존 색칠(격자 샘플).
    const cell = 16.0;
    final paint = Paint();
    for (var sy = 0.0; sy < size.height; sy += cell) {
      for (var sx = 0.0; sx < size.width; sx += cell) {
        // 화면 → 월드 역변환(셀 중심).
        final wx = px + (sx + cell / 2 - mapArea.center.dx) / scale;
        final wy = py + (sy + cell / 2 - mapArea.center.dy) / scale;
        final lvl = WorldZones.levelAt(wx, wy);
        paint.color = _zoneColor(lvl).withValues(alpha: 0.5);
        canvas.drawRect(Rect.fromLTWH(sx, sy, cell + 0.5, cell + 0.5), paint);
      }
    }

    // 2) 마을(안전지대) 표시 — 보로노이 월드의 인근 마을 모두.
    final worldSpan = scale > 0 ? size.width / scale : 6000.0;
    for (final t in WorldZones.townsNear(px, py, worldSpan)) {
      final ts = w2s(t.x, t.y);
      final tr = WorldZones.townRadius * scale;
      final rr = tr < 4 ? 4.0 : tr;
      canvas.drawCircle(ts, rr, Paint()..color = const Color(0x553F51B5));
      canvas.drawCircle(
          ts,
          rr,
          Paint()
            ..color = const Color(0xFF7986CB)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      _text(canvas, '마을', ts, const Color(0xFFE8EAF6), 11);
    }

    // 3) 위험 구역 강조: 고레벨 몬스터(내 레벨+5 이상)가 밀집한 곳에 빨간 후광.
    final glow = Paint()
      ..color = const Color(0x33FF1744)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    for (final m in monsters) {
      if (m.level - playerLevel >= 5) {
        canvas.drawCircle(w2s(m.x, m.y), 26, glow);
      }
    }

    // 4) 몬스터 점.
    for (final m in monsters) {
      final s = w2s(m.x, m.y);
      final danger = m.level - playerLevel;
      final c = danger >= 5
          ? const Color(0xFFFF5252)
          : danger >= 0
              ? const Color(0xFFFFCA28)
              : const Color(0xFFB0BEC5);
      canvas.drawCircle(s, m.elite ? 4.0 : 2.6, Paint()..color = c);
    }

    // 5) 다른 플레이어 점(시안).
    for (final d in dots) {
      canvas.drawCircle(d.screen, 5, Paint()..color = const Color(0xFF00E5FF));
      canvas.drawCircle(
          d.screen,
          5,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }

    // 6) 내 위치(중앙, 노란 별표).
    final me = mapArea.center;
    canvas.drawCircle(me, 7, Paint()..color = const Color(0xFFFFC107));
    canvas.drawCircle(
        me,
        7,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    _text(canvas, '나', me + const Offset(0, -18), Colors.white, 12);
  }

  void _text(Canvas canvas, String s, Offset at, Color color, double size) {
    final tp = TextPainter(
      text: TextSpan(
          text: s,
          style: TextStyle(
              color: color,
              fontSize: size,
              fontWeight: FontWeight.bold,
              shadows: const [Shadow(color: Colors.black, blurRadius: 2)])),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => true;
}
