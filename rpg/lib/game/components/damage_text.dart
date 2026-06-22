// 데미지 표시 — 대상 위에서 위로 떠오르며 페이드아웃.
// 색상으로 주체 구분: 플레이어가 입힌 피해 vs 플레이어가 받은 피해(서로 다른 색).
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

class DamageText extends PositionComponent {
  final String text;
  final Color color;
  final double fontSize;

  static const double _life = 0.8; // 표시 시간(s)
  static const double _rise = 36; // 상승 속도(px/s)
  double _t = 0;

  DamageText({
    required this.text,
    required this.color,
    required Vector2 position,
    this.fontSize = 16,
  }) : super(position: position, anchor: Anchor.center, priority: 1000);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    position.y -= _rise * dt;
    if (_t >= _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (1 - _t / _life).clamp(0.0, 1.0);
    TextPaint(
      style: TextStyle(
        color: color.withValues(alpha: alpha),
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(color: const Color(0xFF000000).withValues(alpha: alpha), blurRadius: 2),
        ],
      ),
    ).render(canvas, text, Vector2.zero(), anchor: Anchor.center);
  }
}
