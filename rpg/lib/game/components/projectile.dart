// 투사체 — 원거리 무기(활/지팡이)의 시각 효과. 시작점에서 목표점까지 날아가 사라진다.
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

class ProjectileComponent extends PositionComponent {
  final Vector2 target;
  final Color color;
  final bool magic;
  static const double speed = 720;
  late final Vector2 _dir;
  double _remaining;

  ProjectileComponent({
    required Vector2 start,
    required this.target,
    required this.color,
    this.magic = false,
  })  : _remaining = start.distanceTo(target),
        super(position: start.clone(), anchor: Anchor.center, priority: 800) {
    final d = target - start;
    angle = atan2(d.y, d.x);
    _dir = d.length == 0 ? Vector2(1, 0) : (d.clone()..normalize());
  }

  @override
  void update(double dt) {
    super.update(dt);
    final step = speed * dt;
    position += _dir * step;
    _remaining -= step;
    if (_remaining <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (magic) {
      canvas.drawCircle(Offset.zero, 6, Paint()..color = color);
      canvas.drawCircle(Offset.zero, 9,
          Paint()..color = color.withValues(alpha: 0.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    } else {
      // 화살(가로 방향, angle 로 회전됨).
      canvas.drawLine(const Offset(-10, 0), const Offset(8, 0),
          Paint()..color = color..strokeWidth = 2.5..strokeCap = StrokeCap.round);
      canvas.drawPath(
        Path()
          ..moveTo(12, 0)
          ..lineTo(4, -4)
          ..lineTo(4, 4)
          ..close(),
        Paint()..color = color,
      );
    }
  }
}
