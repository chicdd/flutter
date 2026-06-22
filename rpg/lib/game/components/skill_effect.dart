// 스킬 이펙트 — 확장하며 사라지는 원/링/부채꼴. 폭발·회전·노바 등에 사용.
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

enum BurstKind { explosion, ring, arc }

class SkillEffect extends PositionComponent {
  final Color color;
  final double maxRadius;
  final BurstKind kind;
  final double life;
  final double facingAngle; // arc 용
  final double arcSpan; // arc 반각(rad)
  double _t = 0;

  SkillEffect({
    required Vector2 position,
    required this.color,
    required this.maxRadius,
    this.kind = BurstKind.explosion,
    this.life = 0.32,
    this.facingAngle = 0,
    this.arcSpan = pi / 2,
  }) : super(position: position, anchor: Anchor.center, priority: 950);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t >= life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = (_t / life).clamp(0.0, 1.0);
    final r = maxRadius * (1 - (1 - p) * (1 - p)); // ease-out
    final alpha = (1 - p);

    switch (kind) {
      case BurstKind.explosion:
        canvas.drawCircle(Offset.zero, r,
            Paint()..color = color.withValues(alpha: alpha * 0.5));
        canvas.drawCircle(Offset.zero, r,
            Paint()..color = color.withValues(alpha: alpha)..style = PaintingStyle.stroke..strokeWidth = 3);
        break;
      case BurstKind.ring:
        canvas.drawCircle(Offset.zero, r,
            Paint()..color = color.withValues(alpha: alpha)..style = PaintingStyle.stroke..strokeWidth = 5 * (1 - p) + 1);
        break;
      case BurstKind.arc:
        final rect = Rect.fromCircle(center: Offset.zero, radius: r);
        canvas.drawArc(
          rect,
          facingAngle - arcSpan,
          arcSpan * 2,
          false,
          Paint()
            ..color = color.withValues(alpha: alpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6 * (1 - p) + 2
            ..strokeCap = StrokeCap.round,
        );
        break;
    }
  }
}
