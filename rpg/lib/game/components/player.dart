// 플레이어 — 키보드/조이스틱 이동 + 향상된 렌더(그림자/방향/무기).
// 전투 수치·체력은 PlayerProfile 이 단일 출처. 이 컴포넌트는 이동/표현만 담당한다.
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import '../../state/player_profile.dart';

class PlayerComponent extends PositionComponent {
  static const double speed = 220; // px/s

  final PlayerProfile profile;
  final Vector2 _keyboardDir = Vector2.zero();
  final Vector2 _joystickDir = Vector2.zero();
  final Vector2 _facing = Vector2(1, 0);
  double _attackAnim = 0; // 공격 모션 타이머

  ui.Image? avatar; // 업로드한 아바타(있으면 기본 외형 대체, 캐릭터 크기 내로 렌더)
  double invuln = 0; // 피격 후 무적 시간(초)

  PlayerComponent({required this.profile})
      : super(size: Vector2.all(30), anchor: Anchor.center);

  bool get isDead => profile.isDead;
  Vector2 get facing => _facing;

  // 이동은 화살표 키 전용(A/S/D/F/G/H 는 스킬 키로 사용).
  void setMovement(Set<LogicalKeyboardKey> keys) {
    var dx = 0.0;
    var dy = 0.0;
    if (keys.contains(LogicalKeyboardKey.arrowLeft)) dx -= 1;
    if (keys.contains(LogicalKeyboardKey.arrowRight)) dx += 1;
    if (keys.contains(LogicalKeyboardKey.arrowUp)) dy -= 1;
    if (keys.contains(LogicalKeyboardKey.arrowDown)) dy += 1;
    _keyboardDir.setValues(dx, dy);
  }

  void setJoystick(Vector2 dir) => _joystickDir.setFrom(dir);

  void triggerAttackAnim() => _attackAnim = 0.18;

  @override
  void update(double dt) {
    super.update(dt);
    if (_attackAnim > 0) _attackAnim -= dt;
    if (invuln > 0) invuln -= dt;
    final move = _keyboardDir + _joystickDir;
    if (!move.isZero()) {
      move.normalize();
      _facing.setFrom(move);
      position += move * speed * dt;
    }
  }

  final Paint _shadow = Paint()..color = const Color(0x55000000);

  @override
  void render(Canvas canvas) {
    // 무적 중 깜빡임(이 프레임 스킵).
    if (invuln > 0 && ((invuln * 10).floor() % 2 == 0)) return;

    final c = size.x / 2;
    final center = Offset(c, c);

    // 그림자.
    canvas.drawOval(Rect.fromCenter(center: Offset(c, size.y - 3), width: size.x * 0.8, height: 7), _shadow);

    // 무기(방향 표시) — 공격 시 앞으로 뻗는 모션.
    final reach = 16.0 + (_attackAnim > 0 ? 14.0 : 0.0);
    final tip = center + Offset(_facing.x, _facing.y) * reach;
    canvas.drawLine(
      center,
      tip,
      Paint()
        ..color = const Color(0xFFECEFF1)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    final img = avatar;
    if (img != null) {
      // 아바타: 캐릭터 원형 안에 맞춰 그림(크기 초과 불가).
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
          Paint()..color = const Color(0xFF5D4037)..style = PaintingStyle.stroke..strokeWidth = 2);
      return;
    }

    // 몸체(그라데이션 원).
    final body = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFE082), Color(0xFFFFA000)],
      ).createShader(Rect.fromCircle(center: center, radius: c));
    canvas.drawCircle(center, c - 2, body);
    canvas.drawCircle(
      center,
      c - 2,
      Paint()
        ..color = const Color(0xFF5D4037)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 눈(방향).
    final eye = center + Offset(_facing.x, _facing.y) * 4;
    canvas.drawCircle(eye + const Offset(-3, -2), 1.8, Paint()..color = const Color(0xFF3E2723));
    canvas.drawCircle(eye + const Offset(3, -2), 1.8, Paint()..color = const Color(0xFF3E2723));
  }
}
