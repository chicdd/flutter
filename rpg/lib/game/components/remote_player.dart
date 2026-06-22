// 다른 플레이어 — 멀티플레이어 위치를 보간하며 렌더(이름/레벨/아바타 표시).
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

class RemotePlayerComponent extends PositionComponent {
  final String sessionId;
  String playerName;
  int level;
  final Vector2 target = Vector2.zero();

  ui.Image? avatar;
  int avatarVersion = -1; // 디코드된 아바타 버전

  RemotePlayerComponent({
    required this.sessionId,
    required this.playerName,
    required this.level,
    required Vector2 position,
  }) : super(size: Vector2.all(30), anchor: Anchor.center, position: position) {
    target.setFrom(position);
  }

  void setTarget(double x, double y, int lv, String name) {
    target.setValues(x, y);
    level = lv;
    playerName = name;
  }

  @override
  void update(double dt) {
    super.update(dt);
    // 부드러운 보간.
    position += (target - position) * (10 * dt).clamp(0.0, 1.0);
  }

  static final _label = TextPaint(
    style: const TextStyle(
      color: Color(0xFF90CAF9),
      fontSize: 11,
      fontWeight: FontWeight.bold,
      shadows: [Shadow(color: Color(0xFF000000), blurRadius: 2)],
    ),
  );

  @override
  void render(Canvas canvas) {
    final c = size.x / 2;
    final center = Offset(c, c);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(c, size.y - 3), width: size.x * 0.8, height: 7),
      Paint()..color = const Color(0x55000000),
    );

    final img = avatar;
    if (img != null) {
      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: c - 2)));
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..filterQuality = FilterQuality.medium,
      );
      canvas.restore();
      canvas.drawCircle(center, c - 2,
          Paint()..color = const Color(0xFF0D47A1)..style = PaintingStyle.stroke..strokeWidth = 2);
    } else {
      // 몸체(파란 톤 — 본인과 구분).
      final body = Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF90CAF9), Color(0xFF1E88E5)],
        ).createShader(Rect.fromCircle(center: center, radius: c));
      canvas.drawCircle(center, c - 2, body);
      canvas.drawCircle(
        center,
        c - 2,
        Paint()
          ..color = const Color(0xFF0D47A1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    _label.render(canvas, '$playerName Lv.$level', Vector2(c, -8), anchor: Anchor.bottomCenter);
  }
}
