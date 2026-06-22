// 환경 구조물 컴포넌트(클라이언트 렌더) — 나무/돌/건물.
// 배치 좌표의 위험 등급(tier)에 따라 외형이 달라진다:
//  tier 0(1~10): 깨끗한 가옥 · 푸른 나무 · 일반 바위
//  tier 1(11~30): 낡은 집 · 이끼 낀 빽빽한 숲
//  tier 2(31~50): 부서진 폐허 · 불탄 고목 · 날카로운 기암괴석
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

enum StructureKind { tree, rock, building }

class StructureComponent extends PositionComponent {
  final StructureKind kind;
  final int tier; // 0,1,2
  final int variantSeed; // 같은 종류라도 약간씩 다른 모양

  StructureComponent({
    required this.kind,
    required this.tier,
    required this.variantSeed,
    required Vector2 worldPos,
    required double scale,
  }) : super(anchor: Anchor.bottomCenter, position: worldPos) {
    priority = -1; // 지형 위, 캐릭터 아래
    final base = switch (kind) {
      StructureKind.tree => 64.0,
      StructureKind.rock => 40.0,
      StructureKind.building => 96.0,
    };
    size = Vector2.all(base * scale);
  }

  @override
  void render(Canvas canvas) {
    final s = size.x;
    // 접지 그림자.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(s / 2, s - 4), width: s * 0.7, height: 8),
      Paint()..color = const Color(0x44000000),
    );
    switch (kind) {
      case StructureKind.tree:
        _tree(canvas, s);
        break;
      case StructureKind.rock:
        _rock(canvas, s);
        break;
      case StructureKind.building:
        _building(canvas, s);
        break;
    }
  }

  Paint _fill(Color c) => Paint()..color = c;
  Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w;

  void _tree(Canvas c, double s) {
    final trunkColor = tier == 2 ? const Color(0xFF3E2723) : const Color(0xFF6D4C41);
    // 줄기.
    c.drawRect(Rect.fromLTWH(s * 0.43, s * 0.5, s * 0.14, s * 0.5), _fill(trunkColor));
    if (tier == 2) {
      // 불탄 고목 — 잎 없이 앙상한 가지.
      final br = _stroke(const Color(0xFF2E2622), s * 0.05);
      final cx = s * 0.5, top = s * 0.5;
      c.drawLine(Offset(cx, top), Offset(s * 0.28, s * 0.26), br);
      c.drawLine(Offset(cx, top), Offset(s * 0.72, s * 0.30), br);
      c.drawLine(Offset(cx, s * 0.42), Offset(s * 0.40, s * 0.16), br);
      c.drawLine(Offset(cx, s * 0.42), Offset(s * 0.64, s * 0.18), br);
      return;
    }
    // 수관.
    final green = tier == 0 ? const Color(0xFF43A047) : const Color(0xFF2E5D34); // 이끼낀 짙은 숲
    final canopy = Offset(s * 0.5, s * 0.36);
    final r = s * (tier == 1 ? 0.40 : 0.34);
    c.drawCircle(canopy, r, _fill(green));
    c.drawCircle(canopy + Offset(-r * 0.5, r * 0.2), r * 0.7, _fill(green));
    c.drawCircle(canopy + Offset(r * 0.5, r * 0.15), r * 0.7, _fill(green));
    if (tier == 1) {
      // 이끼 점.
      final moss = _fill(const Color(0xFF7CB342));
      final rng = Random(variantSeed);
      for (var i = 0; i < 4; i++) {
        c.drawCircle(canopy + Offset((rng.nextDouble() - 0.5) * r, (rng.nextDouble() - 0.5) * r), s * 0.04, moss);
      }
    }
  }

  void _rock(Canvas c, double s) {
    final base = tier == 1 ? const Color(0xFF6E7B6E) : const Color(0xFF8D9499);
    if (tier == 2) {
      // 날카로운 기암괴석.
      final p = Path()
        ..moveTo(s * 0.1, s)
        ..lineTo(s * 0.25, s * 0.3)
        ..lineTo(s * 0.45, s * 0.6)
        ..lineTo(s * 0.6, s * 0.15)
        ..lineTo(s * 0.78, s * 0.55)
        ..lineTo(s * 0.92, s)
        ..close();
      c.drawPath(p, _fill(const Color(0xFF5A5550)));
      c.drawPath(p, _stroke(const Color(0xFF2E2A26), s * 0.04));
      return;
    }
    final r = Rect.fromLTWH(s * 0.12, s * 0.34, s * 0.76, s * 0.62);
    c.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(s * 0.28)), _fill(base));
    c.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(s * 0.28)), _stroke(const Color(0xFF455A50), s * 0.03));
    if (tier == 1) {
      // 이끼.
      c.drawArc(r, pi, pi, false, _fill(const Color(0x886B8E23)));
    }
  }

  void _building(Canvas c, double s) {
    if (tier == 2) {
      // 부서진 폐허 — 무너진 벽 잔해.
      final wall = _fill(const Color(0xFF6D6258));
      c.drawRect(Rect.fromLTWH(s * 0.12, s * 0.55, s * 0.20, s * 0.45), wall);
      c.drawRect(Rect.fromLTWH(s * 0.40, s * 0.40, s * 0.16, s * 0.60), wall);
      c.drawRect(Rect.fromLTWH(s * 0.66, s * 0.62, s * 0.22, s * 0.38), wall);
      // 잔해.
      c.drawRect(Rect.fromLTWH(s * 0.34, s * 0.88, s * 0.10, s * 0.10), wall);
      final ol = _stroke(const Color(0xFF34302B), s * 0.025);
      c.drawRect(Rect.fromLTWH(s * 0.40, s * 0.40, s * 0.16, s * 0.60), ol);
      return;
    }
    final wallColor = tier == 0 ? const Color(0xFFE8D5B0) : const Color(0xFFB7A98C); // 낡은 집
    final roofColor = tier == 0 ? const Color(0xFFC0392B) : const Color(0xFF7A5C3E);
    // 벽.
    final body = Rect.fromLTWH(s * 0.18, s * 0.45, s * 0.64, s * 0.55);
    c.drawRect(body, _fill(wallColor));
    c.drawRect(body, _stroke(const Color(0xFF6D4C41), s * 0.02));
    // 지붕.
    final roof = Path()
      ..moveTo(s * 0.10, s * 0.47)
      ..lineTo(s * 0.5, s * 0.16)
      ..lineTo(s * 0.90, s * 0.47)
      ..close();
    c.drawPath(roof, _fill(roofColor));
    // 문/창.
    c.drawRect(Rect.fromLTWH(s * 0.43, s * 0.70, s * 0.14, s * 0.30), _fill(const Color(0xFF5D4037)));
    if (tier == 1) {
      // 균열.
      c.drawLine(Offset(s * 0.30, s * 0.50), Offset(s * 0.36, s * 0.86), _stroke(const Color(0xFF6D4C41), s * 0.015));
    }
  }
}
