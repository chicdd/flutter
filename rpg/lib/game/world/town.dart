// 비전투 마을(안전지대) 시각 — 광장/건물/분수/울타리. 월드 좌표에 고정 렌더.
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

class TownComponent extends Component {
  final Vector2 center;
  final double radius;

  TownComponent({required this.center, required this.radius}) {
    priority = -5; // 지형 위, 엔티티 아래
  }

  @override
  void render(Canvas canvas) {
    final cx = center.x;
    final cy = center.y;

    // 광장 바닥(석재).
    canvas.drawCircle(Offset(cx, cy), radius, Paint()..color = const Color(0xFF6D6457));
    canvas.drawCircle(Offset(cx, cy), radius, Paint()..color = const Color(0xFF8D8475));
    canvas.drawCircle(
        Offset(cx, cy), radius - 8, Paint()..color = const Color(0xFF9E9483));
    // 경계선.
    canvas.drawCircle(
        Offset(cx, cy),
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = const Color(0xFF5D4037));

    // 길(중앙 십자).
    final road = Paint()..color = const Color(0xFFB6AC97);
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: radius * 2, height: 34), road);
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: 34, height: radius * 2), road);

    // 분수(중앙).
    canvas.drawCircle(Offset(cx, cy), 26, Paint()..color = const Color(0xFF455A64));
    canvas.drawCircle(Offset(cx, cy), 20, Paint()..color = const Color(0xFF4FC3F7));
    canvas.drawCircle(Offset(cx, cy), 20,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = const Color(0xFF263238));

    // 건물 4채(대각선 위치).
    const pal = [Color(0xFFA1887F), Color(0xFF8D6E63), Color(0xFF90A4AE), Color(0xFFBCAAA4)];
    for (var i = 0; i < 4; i++) {
      final a = pi / 4 + i * pi / 2;
      final bx = cx + cos(a) * radius * 0.6;
      final by = cy + sin(a) * radius * 0.6;
      _building(canvas, bx, by, pal[i]);
    }

    // 마을 이름.
    TextPaint(
      style: const TextStyle(
        color: Color(0xFFFFF8E1),
        fontSize: 18,
        fontWeight: FontWeight.bold,
        shadows: [Shadow(color: Color(0xFF000000), blurRadius: 3)],
      ),
    ).render(canvas, '🏰 평화 마을 (안전지대)', Vector2(cx, cy - radius + 6), anchor: Anchor.topCenter);
  }

  void _building(Canvas canvas, double x, double y, Color color) {
    const w = 56.0;
    const h = 44.0;
    final body = Rect.fromCenter(center: Offset(x, y + 6), width: w, height: h);
    canvas.drawRect(body, Paint()..color = color);
    canvas.drawRect(body,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0xFF3E2723));
    // 지붕.
    final roof = Path()
      ..moveTo(x - w / 2 - 6, y - h / 2 + 6)
      ..lineTo(x, y - h / 2 - 16)
      ..lineTo(x + w / 2 + 6, y - h / 2 + 6)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF8D4E3C));
    canvas.drawPath(roof,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0xFF3E2723));
    // 문.
    canvas.drawRect(Rect.fromCenter(center: Offset(x, y + 16), width: 14, height: 18),
        Paint()..color = const Color(0xFF4E342E));
  }
}
