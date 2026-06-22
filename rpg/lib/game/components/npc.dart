// NPC — 마을 비전투 캐릭터. 탭(클릭)하면 상호작용(상점 등) 콜백 호출.
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';

class NpcComponent extends PositionComponent with TapCallbacks {
  final String npcType; // merchant / blacksmith / villager
  final String npcName;
  final Color color;
  final void Function(String type, String name) onInteract;

  NpcComponent({
    required this.npcType,
    required this.npcName,
    required this.color,
    required this.onInteract,
    required Vector2 position,
  }) : super(size: Vector2.all(30), anchor: Anchor.center, position: position);

  @override
  void onTapDown(TapDownEvent event) => onInteract(npcType, npcName);

  static final _label = TextPaint(
    style: const TextStyle(
      color: Color(0xFFFFE082),
      fontSize: 11,
      fontWeight: FontWeight.bold,
      shadows: [Shadow(color: Color(0xFF000000), blurRadius: 2)],
    ),
  );

  @override
  void render(Canvas canvas) {
    final s = size.x;
    final cx = s / 2;

    canvas.drawOval(Rect.fromCenter(center: Offset(cx, s - 2), width: s * 0.8, height: 6),
        Paint()..color = const Color(0x55000000));

    // 몸통 + 머리.
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(s * 0.22, s * 0.4, s * 0.56, s * 0.55), Radius.circular(s * 0.12)),
        Paint()..color = color);
    canvas.drawCircle(Offset(cx, s * 0.32), s * 0.2, Paint()..color = const Color(0xFFFFCC80));
    canvas.drawCircle(Offset(cx, s * 0.32), s * 0.2,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = const Color(0xFF5D4037));

    // 상호작용 표식(!).
    TextPaint(
      style: const TextStyle(color: Color(0xFFFFF176), fontSize: 16, fontWeight: FontWeight.bold),
    ).render(canvas, '!', Vector2(cx, -2), anchor: Anchor.bottomCenter);

    _label.render(canvas, npcName, Vector2(cx, s + 2), anchor: Anchor.topCenter);
  }
}
