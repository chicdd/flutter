// 예쁜 아이템 아이콘 — 등급별 그라데이션 타일 + 직접 그린 벡터 글리프.
// 가방 격자/장비 슬롯/상세 시트에서 공용으로 사용.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/gear.dart';
import '../../models/items.dart';

enum ItemGlyph {
  sword, spear, bow, axe, staff,
  chest, helm, boot, ring, potion, crystal, coin, hide, scroll,
  pants, glove, pauldron, amulet, belt, bracelet,
}

ItemGlyph glyphForKind(GearKind k) => switch (k) {
      GearKind.weapon => ItemGlyph.sword,
      GearKind.helmet => ItemGlyph.helm,
      GearKind.shoulder => ItemGlyph.pauldron,
      GearKind.top => ItemGlyph.chest,
      GearKind.gloves => ItemGlyph.glove,
      GearKind.bottom => ItemGlyph.pants,
      GearKind.boots => ItemGlyph.boot,
      GearKind.necklace => ItemGlyph.amulet,
      GearKind.belt => ItemGlyph.belt,
      GearKind.bracelet => ItemGlyph.bracelet,
      GearKind.ring => ItemGlyph.ring,
    };

ItemGlyph glyphForSlot(EquipSlot s) => glyphForKind(s.kind);

ItemGlyph glyphForWeapon(WeaponType t) => switch (t) {
      WeaponType.sword => ItemGlyph.sword,
      WeaponType.spear => ItemGlyph.spear,
      WeaponType.bow => ItemGlyph.bow,
      WeaponType.axe => ItemGlyph.axe,
      WeaponType.staff => ItemGlyph.staff,
    };

ItemGlyph glyphForMisc(MiscKind k) => switch (k) {
      MiscKind.healthPotion || MiscKind.potionMedium || MiscKind.potionLarge => ItemGlyph.potion,
      MiscKind.townScroll => ItemGlyph.scroll,
      MiscKind.monsterHide => ItemGlyph.hide,
      MiscKind.magicCrystal => ItemGlyph.crystal,
      MiscKind.ancientCoin => ItemGlyph.coin,
    };

class ItemIcon extends StatelessWidget {
  final ItemGlyph glyph;
  final Rarity rarity;
  final double size;
  final int? quantity;

  const ItemIcon({
    super.key,
    required this.glyph,
    required this.rarity,
    required this.size,
    this.quantity,
  });

  factory ItemIcon.forItem(BagItem item, {required double size}) {
    if (item is GearItem) {
      final g = item.weaponType != null ? glyphForWeapon(item.weaponType!) : glyphForKind(item.kind);
      return ItemIcon(glyph: g, rarity: item.rarity, size: size);
    }
    final m = item as MiscItem;
    return ItemIcon(
      glyph: glyphForMisc(m.kind),
      rarity: m.rarity,
      size: size,
      quantity: m.quantity > 1 ? m.quantity : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = Color(rarity.colorValue);
    final high = rarity.index >= Rarity.epic.index;
    final r = size * 0.2;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(base, Colors.black, 0.45)!,
            const Color(0xFF12161C),
          ],
        ),
        border: Border.all(color: base, width: size < 40 ? 1.4 : 2),
        boxShadow: high
            ? [BoxShadow(color: base.withValues(alpha: 0.55), blurRadius: size * 0.18, spreadRadius: 0.5)]
            : null,
      ),
      child: Stack(
        children: [
          // 상단 광택.
          Positioned(
            left: r,
            right: size * 0.35,
            top: size * 0.06,
            child: Container(
              height: size * 0.10,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: high ? 0.22 : 0.12),
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ),
          // 글리프.
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(size * 0.16),
              child: CustomPaint(painter: _GlyphPainter(glyph, base)),
            ),
          ),
          // 등급 코너 보석.
          Positioned(
            right: size * 0.06,
            top: size * 0.06,
            child: Container(
              width: size * 0.12,
              height: size * 0.12,
              decoration: BoxDecoration(
                color: base,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white70, width: 0.8),
              ),
            ),
          ),
          // 수량 뱃지.
          if (quantity != null)
            Positioned(
              right: 2,
              bottom: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('$quantity',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}

// 빈 장비 슬롯용 — 글리프만 흐리게.
class EmptySlotIcon extends StatelessWidget {
  final EquipSlot slot;
  final double size;
  const EmptySlotIcon({super.key, required this.slot, required this.size});

  @override
  Widget build(BuildContext context) {
    final r = size * 0.2;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF15181E),
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: Colors.white12),
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.22),
        child: CustomPaint(painter: _GlyphPainter(glyphForSlot(slot), const Color(0xFF3A4049))),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  final ItemGlyph glyph;
  final Color base;

  _GlyphPainter(this.glyph, this.base);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final light = Color.lerp(base, Colors.white, 0.7)!;
    final mid = Color.lerp(base, Colors.white, 0.35)!;
    final dark = Color.lerp(base, Colors.black, 0.4)!;

    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = dark
      ..strokeWidth = s * 0.05;

    Offset p(double fx, double fy) => Offset(fx * s, fy * s);
    Path poly(List<List<double>> pts) {
      final path = Path()..moveTo(pts.first[0] * s, pts.first[1] * s);
      for (final pt in pts.skip(1)) {
        path.lineTo(pt[0] * s, pt[1] * s);
      }
      return path..close();
    }

    switch (glyph) {
      case ItemGlyph.sword:
        // 칼날.
        final blade = poly([
          [0.5, 0.05],
          [0.6, 0.2],
          [0.56, 0.66],
          [0.44, 0.66],
          [0.4, 0.2],
        ]);
        canvas.drawPath(blade, fill..shader = _v(light, mid, s));
        canvas.drawPath(blade, stroke);
        // 가드.
        fill.shader = null;
        fill.color = dark;
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(0.26 * s, 0.62 * s, 0.48 * s, 0.09 * s), Radius.circular(s * 0.03)),
            fill);
        // 손잡이 + 폼멜.
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(0.45 * s, 0.71 * s, 0.1 * s, 0.18 * s), Radius.circular(s * 0.03)),
            fill..color = mid);
        canvas.drawCircle(p(0.5, 0.92), s * 0.06, fill..color = light);
        break;

      case ItemGlyph.spear:
        final head = poly([
          [0.5, 0.05],
          [0.61, 0.24],
          [0.5, 0.34],
          [0.39, 0.24],
        ]);
        canvas.drawPath(head, fill..shader = _v(light, mid, s));
        canvas.drawPath(head, stroke);
        fill.shader = null;
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(0.46 * s, 0.3 * s, 0.08 * s, 0.62 * s), Radius.circular(s * 0.03)),
            fill..color = mid);
        break;

      case ItemGlyph.bow:
        final bow = Path()
          ..moveTo(0.66 * s, 0.1 * s)
          ..quadraticBezierTo(0.16 * s, 0.5 * s, 0.66 * s, 0.9 * s);
        canvas.drawPath(bow, Paint()
          ..style = PaintingStyle.stroke
          ..color = light
          ..strokeWidth = s * 0.07
          ..strokeCap = StrokeCap.round);
        canvas.drawLine(p(0.66, 0.1), p(0.66, 0.9), stroke..color = mid..strokeWidth = s * 0.025);
        // 화살.
        canvas.drawLine(p(0.36, 0.5), p(0.9, 0.5), stroke..color = dark..strokeWidth = s * 0.04);
        canvas.drawPath(poly([[0.9, 0.5], [0.8, 0.45], [0.8, 0.55]]), fill..shader = null..color = dark);
        break;

      case ItemGlyph.axe:
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(0.46 * s, 0.18 * s, 0.08 * s, 0.74 * s), Radius.circular(s * 0.03)),
            fill..shader = null..color = const Color(0xFF8D6E63));
        final blade = poly([
          [0.52, 0.2],
          [0.86, 0.3],
          [0.86, 0.52],
          [0.52, 0.46],
        ]);
        canvas.drawPath(blade, fill..color = light);
        canvas.drawPath(blade, stroke..color = dark..strokeWidth = s * 0.045);
        final blade2 = poly([
          [0.48, 0.2],
          [0.14, 0.3],
          [0.14, 0.52],
          [0.48, 0.46],
        ]);
        canvas.drawPath(blade2, fill..color = mid);
        canvas.drawPath(blade2, stroke);
        break;

      case ItemGlyph.staff:
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(0.46 * s, 0.32 * s, 0.08 * s, 0.6 * s), Radius.circular(s * 0.03)),
            fill..shader = null..color = const Color(0xFF8D6E63));
        canvas.drawCircle(p(0.5, 0.24), s * 0.16, fill..color = mid);
        canvas.drawCircle(p(0.5, 0.24), s * 0.16, stroke..color = dark..strokeWidth = s * 0.04);
        canvas.drawCircle(p(0.45, 0.2), s * 0.04, fill..color = Colors.white.withValues(alpha: 0.7));
        break;

      case ItemGlyph.chest:
        final body = poly([
          [0.22, 0.22],
          [0.4, 0.18],
          [0.5, 0.26],
          [0.6, 0.18],
          [0.78, 0.22],
          [0.72, 0.5],
          [0.5, 0.86],
          [0.28, 0.5],
        ]);
        canvas.drawPath(body, fill..shader = _v(mid, dark, s));
        canvas.drawPath(body, stroke);
        canvas.drawLine(p(0.5, 0.3), p(0.5, 0.8), stroke..color = light..strokeWidth = s * 0.035);
        break;

      case ItemGlyph.helm:
        final dome = Path()
          ..moveTo(0.22 * s, 0.6 * s)
          ..arcToPoint(Offset(0.78 * s, 0.6 * s), radius: Radius.circular(0.3 * s), clockwise: true)
          ..close();
        canvas.drawPath(dome, fill..shader = _v(light, mid, s));
        canvas.drawPath(dome, stroke);
        // 챙/면갑.
        fill.shader = null;
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(0.2 * s, 0.6 * s, 0.6 * s, 0.13 * s), Radius.circular(s * 0.04)),
            fill..color = dark);
        canvas.drawLine(p(0.5, 0.28), p(0.5, 0.6), stroke..color = dark..strokeWidth = s * 0.04);
        break;

      case ItemGlyph.boot:
        final boot = poly([
          [0.38, 0.16],
          [0.56, 0.16],
          [0.56, 0.58],
          [0.82, 0.58],
          [0.82, 0.8],
          [0.38, 0.8],
        ]);
        canvas.drawPath(boot, fill..shader = _v(mid, dark, s));
        canvas.drawPath(boot, stroke);
        canvas.drawLine(p(0.38, 0.72), p(0.82, 0.72), stroke..color = light..strokeWidth = s * 0.03);
        break;

      case ItemGlyph.ring:
        canvas.drawCircle(p(0.5, 0.62), s * 0.26,
            Paint()..style = PaintingStyle.stroke..strokeWidth = s * 0.1..shader = _v(light, mid, s, c: p(0.5, 0.62)));
        canvas.drawCircle(p(0.5, 0.62), s * 0.26,
            Paint()..style = PaintingStyle.stroke..strokeWidth = s * 0.1..color = dark.withValues(alpha: 0.4));
        // 보석.
        final gem = poly([
          [0.5, 0.1],
          [0.63, 0.26],
          [0.5, 0.4],
          [0.37, 0.26],
        ]);
        canvas.drawPath(gem, fill..shader = null..color = light);
        canvas.drawPath(gem, stroke..color = dark..strokeWidth = s * 0.04);
        break;

      case ItemGlyph.potion:
        // 빨간 액체 든 둥근 플라스크(아이템 고유색).
        canvas.drawCircle(p(0.5, 0.62), s * 0.26, fill..shader = null..color = const Color(0xFF1A1F26));
        final clip = Path()..addOval(Rect.fromCircle(center: p(0.5, 0.62), radius: s * 0.24));
        canvas.save();
        canvas.clipPath(clip);
        canvas.drawRect(Rect.fromLTWH(0.24 * s, 0.58 * s, 0.52 * s, 0.32 * s), fill..color = const Color(0xFFEF5350));
        canvas.drawRect(Rect.fromLTWH(0.24 * s, 0.58 * s, 0.52 * s, 0.05 * s), fill..color = const Color(0xFFFF8A80));
        canvas.restore();
        canvas.drawCircle(p(0.5, 0.62), s * 0.26, stroke..color = const Color(0xFFCFD8DC)..strokeWidth = s * 0.04);
        // 유리 광택.
        canvas.drawCircle(p(0.42, 0.55), s * 0.05, fill..color = Colors.white.withValues(alpha: 0.55));
        // 목 + 코르크.
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(0.42 * s, 0.18 * s, 0.16 * s, 0.22 * s), Radius.circular(s * 0.02)),
            fill..color = const Color(0xFFB0BEC5));
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(0.4 * s, 0.1 * s, 0.2 * s, 0.09 * s), Radius.circular(s * 0.02)),
            fill..color = const Color(0xFF6D4C41));
        break;

      case ItemGlyph.crystal:
        final outer = poly([
          [0.5, 0.1],
          [0.8, 0.42],
          [0.5, 0.9],
          [0.2, 0.42],
        ]);
        canvas.drawPath(outer, fill..shader = _v(const Color(0xFFB2EBF2), const Color(0xFF0097A7), s));
        canvas.drawPath(outer, stroke..color = const Color(0xFF006064)..strokeWidth = s * 0.04);
        // 면(facet) 라인.
        final facet = Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.white.withValues(alpha: 0.6)
          ..strokeWidth = s * 0.025;
        canvas.drawLine(p(0.2, 0.42), p(0.8, 0.42), facet);
        canvas.drawLine(p(0.5, 0.1), p(0.5, 0.9), facet);
        canvas.drawLine(p(0.35, 0.42), p(0.5, 0.9), facet);
        canvas.drawLine(p(0.65, 0.42), p(0.5, 0.9), facet);
        break;

      case ItemGlyph.coin:
        const gold = Color(0xFFFFC107);
        canvas.drawCircle(p(0.5, 0.5), s * 0.34, fill..shader = null..color = const Color(0xFFB8860B));
        canvas.drawCircle(p(0.5, 0.5), s * 0.34, fill..color = gold);
        canvas.drawCircle(p(0.5, 0.5), s * 0.34,
            Paint()..style = PaintingStyle.stroke..strokeWidth = s * 0.035..color = const Color(0xFF7A5200));
        canvas.drawCircle(p(0.5, 0.5), s * 0.22,
            Paint()..style = PaintingStyle.stroke..strokeWidth = s * 0.03..color = const Color(0xFF7A5200));
        // 별.
        canvas.drawPath(_star(p(0.5, 0.5), s * 0.13, s * 0.06),
            Paint()..color = const Color(0xFF7A5200));
        break;

      case ItemGlyph.hide:
        final pelt = poly([
          [0.28, 0.3],
          [0.45, 0.2],
          [0.62, 0.26],
          [0.78, 0.22],
          [0.72, 0.45],
          [0.8, 0.66],
          [0.55, 0.82],
          [0.26, 0.72],
          [0.2, 0.5],
        ]);
        canvas.drawPath(pelt, fill..shader = null..color = const Color(0xFF8D6E63));
        canvas.drawPath(pelt, stroke..color = const Color(0xFF4E342E)..strokeWidth = s * 0.04);
        // 스티치.
        final dot = Paint()..color = const Color(0xFFD7CCC8);
        for (final f in [0.4, 0.52, 0.64]) {
          canvas.drawCircle(p(f, 0.5), s * 0.022, dot);
        }
        break;

      case ItemGlyph.scroll:
        // 양피지.
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(0.28 * s, 0.2 * s, 0.44 * s, 0.6 * s), Radius.circular(s * 0.04)),
            fill..shader = null..color = const Color(0xFFFFF3E0));
        // 위/아래 말림.
        for (final cy in [0.2, 0.8]) {
          canvas.drawOval(Rect.fromCenter(center: p(0.5, cy), width: 0.5 * s, height: 0.12 * s),
              fill..color = const Color(0xFFD7B899));
        }
        // 글자 선.
        final ln = Paint()
          ..color = const Color(0xFF8D6E63)
          ..strokeWidth = s * 0.025;
        for (final ly in [0.38, 0.5, 0.62]) {
          canvas.drawLine(p(0.36, ly), p(0.64, ly), ln);
        }
        break;

      case ItemGlyph.pants:
        final body = poly([
          [0.3, 0.16], [0.7, 0.16], [0.7, 0.5], [0.62, 0.86],
          [0.52, 0.86], [0.5, 0.52], [0.48, 0.86], [0.38, 0.86], [0.3, 0.5],
        ]);
        canvas.drawPath(body, fill..shader = _v(mid, dark, s));
        canvas.drawPath(body, stroke);
        canvas.drawLine(p(0.3, 0.22), p(0.7, 0.22), stroke..color = light..strokeWidth = s * 0.03);
        break;

      case ItemGlyph.glove:
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(0.34 * s, 0.4 * s, 0.34 * s, 0.46 * s), Radius.circular(s * 0.06)),
            fill..shader = _v(mid, dark, s));
        // 손가락.
        for (final fx in [0.37, 0.46, 0.55]) {
          canvas.drawRRect(
              RRect.fromRectAndRadius(Rect.fromLTWH(fx * s, 0.2 * s, 0.08 * s, 0.24 * s), Radius.circular(s * 0.03)),
              fill..shader = null..color = mid);
        }
        // 엄지.
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(0.64 * s, 0.42 * s, 0.1 * s, 0.18 * s), Radius.circular(s * 0.03)),
            fill..color = mid);
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(0.34 * s, 0.4 * s, 0.34 * s, 0.46 * s), Radius.circular(s * 0.06)),
            stroke..color = dark..strokeWidth = s * 0.04);
        break;

      case ItemGlyph.pauldron:
        final dome = Path()
          ..moveTo(0.2 * s, 0.66 * s)
          ..arcToPoint(Offset(0.8 * s, 0.66 * s), radius: Radius.circular(0.34 * s), clockwise: true)
          ..close();
        canvas.drawPath(dome, fill..shader = _v(light, mid, s));
        canvas.drawPath(dome, stroke);
        // 가시/장식.
        canvas.drawPath(poly([[0.5, 0.06], [0.58, 0.3], [0.42, 0.3]]), fill..shader = null..color = dark);
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(0.2 * s, 0.66 * s, 0.6 * s, 0.1 * s), Radius.circular(s * 0.03)),
            fill..color = dark);
        break;

      case ItemGlyph.amulet:
        // 체인.
        canvas.drawArc(Rect.fromLTWH(0.22 * s, 0.1 * s, 0.56 * s, 0.7 * s), math.pi * 0.15, math.pi * 0.7, false,
            Paint()..style = PaintingStyle.stroke..color = mid..strokeWidth = s * 0.05);
        // 펜던트(보석).
        final gem = poly([[0.5, 0.5], [0.66, 0.66], [0.5, 0.88], [0.34, 0.66]]);
        canvas.drawPath(gem, fill..shader = _v(light, dark, s));
        canvas.drawPath(gem, stroke..color = dark..strokeWidth = s * 0.04);
        canvas.drawLine(p(0.34, 0.66), p(0.66, 0.66), Paint()..color = Colors.white.withValues(alpha: 0.5)..strokeWidth = s * 0.02);
        break;

      case ItemGlyph.belt:
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(0.1 * s, 0.4 * s, 0.8 * s, 0.2 * s), Radius.circular(s * 0.04)),
            fill..shader = null..color = const Color(0xFF6D4C41));
        // 버클.
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(0.42 * s, 0.34 * s, 0.16 * s, 0.32 * s), Radius.circular(s * 0.03)),
            fill..color = light);
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(0.42 * s, 0.34 * s, 0.16 * s, 0.32 * s), Radius.circular(s * 0.03)),
            stroke..color = dark..strokeWidth = s * 0.035);
        break;

      case ItemGlyph.bracelet:
        canvas.drawCircle(p(0.5, 0.5), s * 0.3,
            Paint()..style = PaintingStyle.stroke..strokeWidth = s * 0.12..shader = _v(light, mid, s, c: p(0.5, 0.5)));
        canvas.drawCircle(p(0.5, 0.5), s * 0.3,
            Paint()..style = PaintingStyle.stroke..strokeWidth = s * 0.12..color = dark.withValues(alpha: 0.35));
        canvas.drawCircle(p(0.5, 0.2), s * 0.06, fill..shader = null..color = light);
        break;
    }
  }

  // 세로 그라데이션 셰이더.
  Shader _v(Color a, Color b, double s, {Offset? c}) {
    final center = c ?? Offset(0.5 * s, 0.5 * s);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [a, b],
    ).createShader(Rect.fromCenter(center: center, width: s, height: s));
  }

  Path _star(Offset c, double outer, double inner) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / 5;
      final pt = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter old) => old.glyph != glyph || old.base != base;
}
