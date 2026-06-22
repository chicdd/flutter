// 좌측 상단 미니맵 — 전체 맵과 동일하게 5배 축소. 몬스터/플레이어/마을/접속자 표시.
// 마을은 범위를 벗어나면 가장자리에 클램프해 "항상" 방향이 보이도록 한다.
import 'dart:async';

import 'package:flutter/material.dart';

import '../game/rpg_game.dart';
import '../game/world/zones.dart';
import '../net/multiplayer.dart';

class Minimap extends StatefulWidget {
  final RpgGame game;
  final MultiplayerService? mp;
  final int playerLevel;
  final double size;

  const Minimap({super.key, required this.game, required this.mp, required this.playerLevel, this.size = 150});

  @override
  State<Minimap> createState() => _MinimapState();
}

class _MinimapState extends State<Minimap> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 280), (_) {
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
    final sz = widget.size;
    final player = widget.game.playerWorldPos;
    final visible = widget.game.camera.visibleWorldRect;
    final worldView = (visible.width > 0 ? visible.width : 1000) * 5;
    final scale = sz / worldView;

    final remotes = <Offset>[];
    final mp = widget.mp;
    if (mp != null) {
      for (final p in mp.players.values) {
        remotes.add(Offset((p.x - player.x) * scale, (p.y - player.y) * scale));
      }
    }

    return Container(
      width: sz,
      height: sz,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white38, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _MinimapPainter(
          px: player.x,
          py: player.y,
          scale: scale,
          playerLevel: widget.playerLevel,
          monsters: widget.game.monsterMarkers(),
          remotes: remotes,
        ),
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  final double px;
  final double py;
  final double scale;
  final int playerLevel;
  final List<({double x, double y, int level, bool elite})> monsters;
  final List<Offset> remotes;

  _MinimapPainter({
    required this.px,
    required this.py,
    required this.scale,
    required this.playerLevel,
    required this.monsters,
    required this.remotes,
  });

  Color _zoneColor(int z) {
    final diff = z - playerLevel;
    if (diff <= -3) return const Color(0xFF21505F);
    if (diff <= 2) return const Color(0xFF2E6B33);
    if (diff <= 6) return const Color(0xFFB07B1E);
    return const Color(0xFFB23030);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0B0F14));
    final center = Offset(size.width / 2, size.height / 2);

    // 존 배경(거친 샘플).
    const cell = 12.0;
    final paint = Paint();
    for (var sy = 0.0; sy < size.height; sy += cell) {
      for (var sx = 0.0; sx < size.width; sx += cell) {
        final wx = px + (sx + cell / 2 - center.dx) / scale;
        final wy = py + (sy + cell / 2 - center.dy) / scale;
        paint.color = _zoneColor(WorldZones.levelAt(wx, wy)).withValues(alpha: 0.55);
        canvas.drawRect(Rect.fromLTWH(sx, sy, cell + 0.5, cell + 0.5), paint);
      }
    }

    // 마을(보로노이) — 보이는 것은 모두, 하나도 없으면 가장 가까운 마을을 가장자리에 클램프.
    final span = scale > 0 ? size.width / scale : 6000.0;
    final towns = WorldZones.townsNear(px, py, span * 1.5);
    const margin = 8.0;
    var anyShown = false;
    Vector2like? nearest;
    var nd = double.infinity;
    for (final t in towns) {
      final dd = (t.x - px) * (t.x - px) + (t.y - py) * (t.y - py);
      if (dd < nd) {
        nd = dd;
        nearest = t;
      }
      final o = center + Offset((t.x - px) * scale, (t.y - py) * scale);
      if (o.dx < 0 || o.dx > size.width || o.dy < 0 || o.dy > size.height) continue;
      anyShown = true;
      canvas.drawCircle(o, WorldZones.townRadius * scale, Paint()..color = const Color(0x553F51B5));
      _townMark(canvas, o);
    }
    if (!anyShown && nearest != null) {
      final raw = center + Offset((nearest.x - px) * scale, (nearest.y - py) * scale);
      final cl = Offset(
        raw.dx.clamp(margin, size.width - margin),
        raw.dy.clamp(margin, size.height - margin),
      );
      _townMark(canvas, cl);
    }

    // 몬스터.
    for (final m in monsters) {
      final o = center + Offset((m.x - px) * scale, (m.y - py) * scale);
      if (o.dx < 0 || o.dx > size.width || o.dy < 0 || o.dy > size.height) continue;
      final danger = m.level - playerLevel;
      final col = danger >= 5
          ? const Color(0xFFFF5252)
          : danger >= 0
              ? const Color(0xFFFFCA28)
              : const Color(0xFFB0BEC5);
      canvas.drawCircle(o, m.elite ? 3.0 : 2.0, Paint()..color = col);
    }

    // 접속자.
    for (final r in remotes) {
      final o = center + r;
      if (o.dx < 0 || o.dx > size.width || o.dy < 0 || o.dy > size.height) continue;
      canvas.drawCircle(o, 3, Paint()..color = const Color(0xFF00E5FF));
    }

    // 내 위치.
    canvas.drawCircle(center, 4, Paint()..color = const Color(0xFFFFC107));
    canvas.drawCircle(center, 4,
        Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  void _townMark(Canvas canvas, Offset o) {
    canvas.drawRect(
        Rect.fromCenter(center: o, width: 9, height: 9),
        Paint()..color = const Color(0xFF7986CB));
    canvas.drawRect(
        Rect.fromCenter(center: o, width: 9, height: 9),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant _MinimapPainter old) => true;
}
