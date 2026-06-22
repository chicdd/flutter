// 타격 이펙트 — 대상 위치에서 확장하며 사라지는 슬래시 링.
import 'dart:ui';

import 'package:flame/components.dart';

class AttackEffect extends PositionComponent {
  final Color color;
  static const double _life = 0.22;
  double _t = 0;

  AttackEffect({required Vector2 position, this.color = const Color(0xFFFFFFFF)})
      : super(position: position, anchor: Anchor.center, priority: 900);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t >= _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = (_t / _life).clamp(0.0, 1.0);
    final radius = 6 + p * 26;
    final alpha = (1 - p);
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = color.withValues(alpha: alpha * 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * (1 - p) + 1,
    );
  }
}
