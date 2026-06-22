// 몬스터 — 추격/근접 공격 AI + 종류별 도트풍 실루엣 + 엘리트 변종 + 레벨 비례 난이도.
// 외형/스탯/이름은 MonsterCatalog(monster_catalog.dart)에서 가져온다(단일 출처).
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../models/combat_stats.dart';
import '../../models/instance.dart';
import '../../models/monster_catalog.dart';
import '../../world/reward_calc.dart';
import 'player.dart';

class MonsterComponent extends PositionComponent {
  final InstanceMonster data;
  final PlayerComponent player;
  final bool elite;
  final double levelScale;
  final int level;
  final void Function(MonsterComponent monster) onMelee;
  final CombatStats stats;
  final MonsterDef def;

  // 지분제 보상용 기여도 장부(공격자 id별 누적 데미지).
  final ContributionLedger ledger = ContributionLedger();

  // 서버 권위 공유 몬스터 여부. true 면 AI/HP 를 서버가 소유하고 위치/HP 는 스냅샷으로 갱신.
  final bool networked;
  final int? netId;
  final Vector2 _netTarget = Vector2.zero();

  String get displayName => def.name;

  static const double aggroRange = 280;
  static const double meleeRange = 38;

  late int _hp;
  late int _maxHp; // 서버 권위 모드에서 갱신 가능.
  late final double _moveSpeed;
  late final double _attackInterval;
  double _attackTimer = 0;
  double _flash = 0;
  double _glow = 0;

  MonsterComponent({
    required this.data,
    required this.player,
    required this.elite,
    required this.levelScale,
    required this.level,
    required this.onMelee,
    this.networked = false,
    this.netId,
  })  : def = monsterDef(data.templateId),
        stats = monsterDef(data.templateId).stats.scaled(levelScale * (elite ? 1.8 : 1.0)),
        super(anchor: Anchor.center, position: Vector2(data.x, data.y)) {
    final baseSize = 30 * def.sizeFactor * (elite ? 1.5 : 1.0);
    size = Vector2.all(baseSize);
    // 권위 모드면 서버가 보낸 HP(=mhp)를 그대로 쓴다(이중 스케일 방지).
    _maxHp = networked ? data.hp : (data.hp * levelScale * (elite ? 2.6 : 1.0)).round();
    _hp = _maxHp;
    _moveSpeed = def.speed * (elite ? 0.9 : 1.0);
    _attackInterval = elite ? 1.3 : 1.1;
    _netTarget.setValues(data.x, data.y);
  }

  // 서버 스냅샷 반영(위치 보간 목표 + 권위 HP).
  void applyNet(double x, double y, int hp, int mhp) {
    _netTarget.setValues(x, y);
    _hp = hp;
    _maxHp = mhp;
  }

  bool get isDead => _hp <= 0;

  final Paint _outline = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  // 피해 기록 + 기여도 장부 누적(by = 공격자 id). 멀티에선 원격 기여도도 같은 방식으로 기록.
  void takeDamage(int amount, {String by = 'local'}) {
    _hp -= amount;
    if (_hp < 0) _hp = 0;
    _flash = 0.12;
    ledger.record(by, amount);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_flash > 0) _flash -= dt;
    _glow += dt * 3;
    if (isDead || player.isDead) return;

    // 권위 모드: 위치는 서버 스냅샷으로 보간(AI 이동 없음). 근접 피해는 클라가 적용.
    if (networked) {
      position += (_netTarget - position) * (10 * dt).clamp(0.0, 1.0);
    }

    final toPlayer = player.position - position;
    final dist = toPlayer.length;
    _attackTimer -= dt;

    if (dist <= meleeRange) {
      if (_attackTimer <= 0) {
        _attackTimer = _attackInterval;
        onMelee(this);
      }
    } else if (!networked && dist <= aggroRange) {
      toPlayer.normalize();
      position += toPlayer * _moveSpeed * dt;
    }
  }

  // ── 렌더 ──
  @override
  void render(Canvas canvas) {
    final s = size.x;
    final cc = Offset(s / 2, s / 2);

    // 그림자.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(s / 2, s - 2), width: s * 0.8, height: 6),
      Paint()..color = const Color(0x55000000),
    );

    // 엘리트 후광.
    if (elite) {
      final pulse = 0.5 + 0.5 * sin(_glow);
      canvas.drawCircle(
        cc,
        s * 0.62 + pulse * 4,
        Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: 0.18 + pulse * 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    final body = elite ? Color.lerp(Color(def.color), const Color(0xFFFFD54F), 0.22)! : Color(def.color);
    _outline.strokeWidth = elite ? 2.4 : 1.8;
    _paintShape(canvas, s, body);

    // 피격 플래시.
    if (_flash > 0) {
      canvas.drawCircle(cc, s * 0.46, Paint()..color = Color.fromRGBO(255, 255, 255, (_flash / 0.12) * 0.6));
    }

    // HP 바.
    final ratio = _maxHp == 0 ? 0.0 : _hp / _maxHp;
    final barH = elite ? 5.0 : 4.0;
    final barY = -barH - 4;
    canvas.drawRect(Rect.fromLTWH(0, barY, s, barH), Paint()..color = const Color(0xFF4E342E));
    canvas.drawRect(Rect.fromLTWH(0, barY, s * ratio, barH),
        Paint()..color = elite ? const Color(0xFFFFB300) : const Color(0xFFEF5350));

    // 이름 + 레벨.
    TextPaint(
      style: TextStyle(
        color: elite ? const Color(0xFFFFD54F) : const Color(0xFFFFFFFF),
        fontSize: elite ? 12 : 11,
        fontWeight: FontWeight.bold,
        shadows: const [Shadow(color: Color(0xFF000000), blurRadius: 2)],
      ),
    ).render(
      canvas,
      '${elite ? '★ ' : ''}$displayName Lv.$level',
      Vector2(s / 2, barY - 5),
      anchor: Anchor.bottomCenter,
    );
  }

  // 종류별 실루엣.
  void _paintShape(Canvas c, double s, Color body) {
    final dark = Color.lerp(body, const Color(0xFF000000), 0.55)!;
    final fill = Paint()..color = body;
    final ol = _outline..color = dark;

    void stroke(Offset a, Offset b, double w, [Color? col]) {
      c.drawLine(a, b, Paint()
        ..color = col ?? body
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round);
    }

    void eyes(double cx, double cy, double r, {Color col = const Color(0xFF1A1A1A)}) {
      c.drawCircle(Offset(cx - r * 1.6, cy), r, Paint()..color = col);
      c.drawCircle(Offset(cx + r * 1.6, cy), r, Paint()..color = col);
    }

    Path poly(List<Offset> pts) {
      final p = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final o in pts.skip(1)) {
        p.lineTo(o.dx, o.dy);
      }
      return p..close();
    }

    void fillPath(Path p, [Paint? f]) {
      c.drawPath(p, f ?? fill);
      c.drawPath(p, ol);
    }

    final cx = s / 2;

    switch (def.shape) {
      case MonsterShape.blob:
        final r = Rect.fromLTWH(s * 0.10, s * 0.30, s * 0.80, s * 0.62);
        c.drawOval(r, fill);
        c.drawOval(r, ol);
        eyes(cx, s * 0.52, s * 0.055);
        break;

      case MonsterShape.beast:
        // 몸통 + 4다리 + 머리 + 꼬리(오른쪽 바라봄).
        final bodyR = Rect.fromLTWH(s * 0.14, s * 0.42, s * 0.58, s * 0.30);
        c.drawRRect(RRect.fromRectAndRadius(bodyR, Radius.circular(s * 0.14)), fill);
        c.drawRRect(RRect.fromRectAndRadius(bodyR, Radius.circular(s * 0.14)), ol);
        for (final lx in [0.22, 0.36, 0.54, 0.66]) {
          stroke(Offset(s * lx, s * 0.68), Offset(s * lx, s * 0.92), s * 0.07, dark);
        }
        stroke(Offset(s * 0.14, s * 0.50), Offset(s * 0.02, s * 0.34), s * 0.06, dark); // 꼬리
        final head = Offset(s * 0.76, s * 0.46);
        c.drawCircle(head, s * 0.16, fill);
        c.drawCircle(head, s * 0.16, ol);
        fillPath(poly([Offset(s * 0.70, s * 0.32), Offset(s * 0.76, s * 0.20), Offset(s * 0.80, s * 0.33)])); // 귀
        c.drawCircle(Offset(s * 0.84, s * 0.46), s * 0.04, Paint()..color = const Color(0xFF1A1A1A)); // 눈
        break;

      case MonsterShape.humanoidSmall:
        _humanoid(c, s, fill, ol, eyes, stroke, headR: 0.15, bodyW: 0.34, top: 0.10);
        break;
      case MonsterShape.humanoid:
        _humanoid(c, s, fill, ol, eyes, stroke, headR: 0.14, bodyW: 0.40, top: 0.07);
        break;
      case MonsterShape.brute:
        _humanoid(c, s, fill, ol, eyes, stroke, headR: 0.13, bodyW: 0.54, top: 0.10);
        break;

      case MonsterShape.bat:
        final bc = Offset(cx, s * 0.5);
        // 날개.
        fillPath(poly([bc, Offset(s * 0.02, s * 0.30), Offset(s * 0.10, s * 0.52), Offset(s * 0.0, s * 0.62)]));
        fillPath(poly([bc, Offset(s * 0.98, s * 0.30), Offset(s * 0.90, s * 0.52), Offset(s * 1.0, s * 0.62)]));
        c.drawCircle(bc, s * 0.16, fill);
        c.drawCircle(bc, s * 0.16, ol);
        fillPath(poly([Offset(cx - s * 0.10, s * 0.38), Offset(cx - s * 0.06, s * 0.26), Offset(cx - s * 0.02, s * 0.38)]));
        fillPath(poly([Offset(cx + s * 0.10, s * 0.38), Offset(cx + s * 0.06, s * 0.26), Offset(cx + s * 0.02, s * 0.38)]));
        eyes(cx, s * 0.5, s * 0.035, col: const Color(0xFFFFEB3B));
        break;

      case MonsterShape.skeleton:
        // 두개골.
        final sk = Offset(cx, s * 0.26);
        c.drawCircle(sk, s * 0.16, Paint()..color = const Color(0xFFECEFF1));
        c.drawCircle(sk, s * 0.16, ol);
        c.drawCircle(Offset(cx - s * 0.06, s * 0.26), s * 0.04, Paint()..color = const Color(0xFF263238));
        c.drawCircle(Offset(cx + s * 0.06, s * 0.26), s * 0.04, Paint()..color = const Color(0xFF263238));
        c.drawRect(Rect.fromLTWH(cx - s * 0.04, s * 0.36, s * 0.08, s * 0.05), Paint()..color = const Color(0xFFCFD8DC)); // 턱
        // 척추 + 갈비뼈.
        stroke(Offset(cx, s * 0.42), Offset(cx, s * 0.74), s * 0.05, const Color(0xFFCFD8DC));
        for (final ry in [0.50, 0.58, 0.66]) {
          stroke(Offset(cx - s * 0.14, s * ry), Offset(cx + s * 0.14, s * ry), s * 0.045, const Color(0xFFECEFF1));
        }
        stroke(Offset(cx, s * 0.46), Offset(s * 0.20, s * 0.62), s * 0.045, const Color(0xFFECEFF1)); // 팔
        stroke(Offset(cx, s * 0.46), Offset(s * 0.80, s * 0.62), s * 0.045, const Color(0xFFECEFF1));
        stroke(Offset(cx - s * 0.05, s * 0.74), Offset(s * 0.32, s * 0.93), s * 0.05, const Color(0xFFCFD8DC)); // 다리
        stroke(Offset(cx + s * 0.05, s * 0.74), Offset(s * 0.68, s * 0.93), s * 0.05, const Color(0xFFCFD8DC));
        break;

      case MonsterShape.winged:
        // 날개(뒤) + 인간형.
        final wfill = Paint()..color = dark.withValues(alpha: 0.9);
        c.drawPath(poly([Offset(cx - s * 0.10, s * 0.40), Offset(s * 0.0, s * 0.18), Offset(s * 0.06, s * 0.42), Offset(s * 0.0, s * 0.58)]), wfill);
        c.drawPath(poly([Offset(cx + s * 0.10, s * 0.40), Offset(s * 1.0, s * 0.18), Offset(s * 0.94, s * 0.42), Offset(s * 1.0, s * 0.58)]), wfill);
        _humanoid(c, s, fill, ol, eyes, stroke, headR: 0.13, bodyW: 0.36, top: 0.10);
        // 작은 뿔.
        fillPath(poly([Offset(cx - s * 0.10, s * 0.13), Offset(cx - s * 0.14, s * 0.02), Offset(cx - s * 0.05, s * 0.12)]));
        fillPath(poly([Offset(cx + s * 0.10, s * 0.13), Offset(cx + s * 0.14, s * 0.02), Offset(cx + s * 0.05, s * 0.12)]));
        break;

      case MonsterShape.bull:
        _humanoid(c, s, fill, ol, eyes, stroke, headR: 0.16, bodyW: 0.52, top: 0.12);
        // 뿔(머리 좌우).
        final hy = s * 0.20;
        fillPath(poly([Offset(cx - s * 0.16, hy), Offset(cx - s * 0.30, s * 0.06), Offset(cx - s * 0.20, s * 0.14)]));
        fillPath(poly([Offset(cx + s * 0.16, hy), Offset(cx + s * 0.30, s * 0.06), Offset(cx + s * 0.20, s * 0.14)]));
        c.drawCircle(Offset(cx, s * 0.26), s * 0.03, Paint()..color = const Color(0xFF1A1A1A)); // 콧구멍
        break;

      case MonsterShape.centaur:
        // 말 하체(4다리) + 인간 상체.
        final horse = Rect.fromLTWH(s * 0.16, s * 0.46, s * 0.56, s * 0.26);
        c.drawRRect(RRect.fromRectAndRadius(horse, Radius.circular(s * 0.12)), fill);
        c.drawRRect(RRect.fromRectAndRadius(horse, Radius.circular(s * 0.12)), ol);
        for (final lx in [0.22, 0.34, 0.56, 0.68]) {
          stroke(Offset(s * lx, s * 0.70), Offset(s * lx, s * 0.92), s * 0.06, dark);
        }
        stroke(Offset(s * 0.16, s * 0.52), Offset(s * 0.04, s * 0.40), s * 0.05, dark); // 꼬리
        // 인간 상체(앞쪽 위).
        final torso = Rect.fromLTWH(s * 0.52, s * 0.24, s * 0.18, s * 0.26);
        c.drawRRect(RRect.fromRectAndRadius(torso, Radius.circular(s * 0.06)), fill);
        c.drawRRect(RRect.fromRectAndRadius(torso, Radius.circular(s * 0.06)), ol);
        final head = Offset(s * 0.61, s * 0.18);
        c.drawCircle(head, s * 0.10, fill);
        c.drawCircle(head, s * 0.10, ol);
        stroke(head + Offset(0, s * 0.06), Offset(s * 0.82, s * 0.30), s * 0.05, body); // 활 든 팔
        break;

      case MonsterShape.ghost:
        final g = Paint()..color = body.withValues(alpha: 0.88);
        final p = Path()
          ..moveTo(s * 0.16, s * 0.84)
          ..lineTo(s * 0.16, s * 0.40)
          ..arcToPoint(Offset(s * 0.84, s * 0.40), radius: Radius.circular(s * 0.34))
          ..lineTo(s * 0.84, s * 0.84)
          ..lineTo(s * 0.72, s * 0.74)
          ..lineTo(s * 0.60, s * 0.84)
          ..lineTo(s * 0.48, s * 0.74)
          ..lineTo(s * 0.36, s * 0.84)
          ..lineTo(s * 0.24, s * 0.74)
          ..close();
        c.drawPath(p, g);
        c.drawPath(p, ol);
        eyes(cx, s * 0.44, s * 0.05, col: const Color(0xFF37474F));
        c.drawOval(Rect.fromCenter(center: Offset(cx, s * 0.58), width: s * 0.08, height: s * 0.12), Paint()..color = const Color(0xFF37474F));
        break;

      case MonsterShape.spectre:
        // 누더기 후드.
        final p = Path()
          ..moveTo(cx, s * 0.08)
          ..lineTo(s * 0.84, s * 0.46)
          ..lineTo(s * 0.78, s * 0.92)
          ..lineTo(s * 0.66, s * 0.78)
          ..lineTo(s * 0.54, s * 0.92)
          ..lineTo(cx, s * 0.78)
          ..lineTo(s * 0.46, s * 0.92)
          ..lineTo(s * 0.34, s * 0.78)
          ..lineTo(s * 0.22, s * 0.92)
          ..lineTo(s * 0.16, s * 0.46)
          ..close();
        c.drawPath(p, Paint()..color = body.withValues(alpha: 0.92));
        c.drawPath(p, ol);
        c.drawCircle(Offset(cx, s * 0.36), s * 0.13, Paint()..color = const Color(0xCC0D2A30)); // 후드 안 어둠
        eyes(cx, s * 0.36, s * 0.045, col: const Color(0xFF00E5FF));
        break;

      case MonsterShape.block:
        final main = Rect.fromLTWH(s * 0.18, s * 0.16, s * 0.64, s * 0.72);
        final rr = RRect.fromRectAndRadius(main, Radius.circular(s * 0.10));
        c.drawRRect(rr, fill);
        c.drawRRect(rr, ol);
        // 어깨 블록.
        c.drawRect(Rect.fromLTWH(s * 0.06, s * 0.26, s * 0.16, s * 0.22), fill);
        c.drawRect(Rect.fromLTWH(s * 0.78, s * 0.26, s * 0.16, s * 0.22), fill);
        // 균열.
        stroke(Offset(s * 0.34, s * 0.24), Offset(s * 0.42, s * 0.50), s * 0.02, dark);
        stroke(Offset(s * 0.42, s * 0.50), Offset(s * 0.36, s * 0.78), s * 0.02, dark);
        eyes(cx, s * 0.36, s * 0.05, col: const Color(0xFFFFB300));
        break;

      case MonsterShape.mage:
        // 로브(사다리꼴) + 후드 + 지팡이.
        final robe = poly([Offset(cx, s * 0.24), Offset(s * 0.72, s * 0.90), Offset(s * 0.28, s * 0.90)]);
        fillPath(robe);
        c.drawCircle(Offset(cx, s * 0.24), s * 0.16, fill); // 후드
        c.drawCircle(Offset(cx, s * 0.24), s * 0.16, ol);
        c.drawCircle(Offset(cx, s * 0.26), s * 0.10, Paint()..color = const Color(0xCC120A1F));
        eyes(cx, s * 0.26, s * 0.035, col: const Color(0xFFB388FF));
        stroke(Offset(s * 0.80, s * 0.20), Offset(s * 0.80, s * 0.86), s * 0.04, const Color(0xFF6D4C41)); // 지팡이
        c.drawCircle(Offset(s * 0.80, s * 0.18), s * 0.07, Paint()..color = const Color(0xFFB388FF));
        break;

      case MonsterShape.knight:
        // 갑옷 몸통 + 어깨 + 머리 없음.
        final torso = Rect.fromLTWH(s * 0.30, s * 0.26, s * 0.40, s * 0.46);
        c.drawRRect(RRect.fromRectAndRadius(torso, Radius.circular(s * 0.08)), fill);
        c.drawRRect(RRect.fromRectAndRadius(torso, Radius.circular(s * 0.08)), ol);
        c.drawCircle(Offset(s * 0.30, s * 0.30), s * 0.10, fill); // 어깨
        c.drawCircle(Offset(s * 0.70, s * 0.30), s * 0.10, fill);
        c.drawCircle(Offset(s * 0.30, s * 0.30), s * 0.10, ol);
        c.drawCircle(Offset(s * 0.70, s * 0.30), s * 0.10, ol);
        c.drawRect(Rect.fromLTWH(cx - s * 0.05, s * 0.18, s * 0.10, s * 0.08), fill); // 목(머리 없음)
        stroke(Offset(cx, s * 0.72), Offset(s * 0.36, s * 0.92), s * 0.06, dark);
        stroke(Offset(cx, s * 0.72), Offset(s * 0.64, s * 0.92), s * 0.06, dark);
        // 들고 있는 자기 머리.
        c.drawCircle(Offset(s * 0.82, s * 0.66), s * 0.10, fill);
        c.drawCircle(Offset(s * 0.82, s * 0.66), s * 0.10, ol);
        eyes(s * 0.82, s * 0.66, s * 0.025, col: const Color(0xFF00E5FF));
        break;

      case MonsterShape.serpent:
        // 똬리 튼 뱀.
        final coil = Path()
          ..moveTo(s * 0.10, s * 0.86)
          ..quadraticBezierTo(s * 0.10, s * 0.50, s * 0.50, s * 0.50)
          ..quadraticBezierTo(s * 0.92, s * 0.50, s * 0.74, s * 0.78)
          ..quadraticBezierTo(s * 0.60, s * 0.96, s * 0.40, s * 0.84);
        c.drawPath(
            coil,
            Paint()
              ..color = body
              ..style = PaintingStyle.stroke
              ..strokeWidth = s * 0.16
              ..strokeCap = StrokeCap.round);
        c.drawPath(
            coil,
            Paint()
              ..color = dark
              ..style = PaintingStyle.stroke
              ..strokeWidth = s * 0.16
              ..strokeJoin = StrokeJoin.round
              ..strokeCap = StrokeCap.round
              ..maskFilter = const MaskFilter.blur(BlurStyle.inner, 1));
        // 머리.
        final head = Offset(s * 0.16, s * 0.30);
        c.drawCircle(head, s * 0.13, fill);
        c.drawCircle(head, s * 0.13, ol);
        eyes(head.dx, head.dy, s * 0.03, col: const Color(0xFFFFEB3B));
        stroke(head + Offset(-s * 0.10, 0), Offset(s * 0.0, s * 0.30), s * 0.02, const Color(0xFFD32F2F)); // 혀
        break;

      case MonsterShape.chimera:
        // 사자 몸 + 갈기 + 보조 머리 + 뱀꼬리.
        final bodyR = Rect.fromLTWH(s * 0.18, s * 0.44, s * 0.52, s * 0.28);
        c.drawRRect(RRect.fromRectAndRadius(bodyR, Radius.circular(s * 0.12)), fill);
        c.drawRRect(RRect.fromRectAndRadius(bodyR, Radius.circular(s * 0.12)), ol);
        for (final lx in [0.24, 0.36, 0.56, 0.66]) {
          stroke(Offset(s * lx, s * 0.68), Offset(s * lx, s * 0.92), s * 0.06, dark);
        }
        c.drawCircle(Offset(s * 0.72, s * 0.42), s * 0.16, Paint()..color = dark); // 갈기
        c.drawCircle(Offset(s * 0.74, s * 0.42), s * 0.12, fill); // 사자 머리
        c.drawCircle(Offset(s * 0.74, s * 0.42), s * 0.12, ol);
        eyes(s * 0.76, s * 0.42, s * 0.028, col: const Color(0xFFFFEB3B));
        // 염소(보조) 머리.
        c.drawCircle(Offset(s * 0.40, s * 0.34), s * 0.09, fill);
        c.drawCircle(Offset(s * 0.40, s * 0.34), s * 0.09, ol);
        fillPath(poly([Offset(s * 0.34, s * 0.28), Offset(s * 0.30, s * 0.16), Offset(s * 0.40, s * 0.26)])); // 뿔
        // 뱀 꼬리.
        stroke(Offset(s * 0.18, s * 0.56), Offset(s * 0.04, s * 0.34), s * 0.05, const Color(0xFF2E7D32));
        break;

      case MonsterShape.dragon:
        // 큰 날개 + 몸 + 목/머리 + 꼬리.
        final wfill = Paint()..color = dark;
        c.drawPath(poly([Offset(cx, s * 0.42), Offset(s * 0.04, s * 0.10), Offset(s * 0.10, s * 0.40), Offset(s * 0.02, s * 0.56)]), wfill);
        c.drawPath(poly([Offset(cx, s * 0.42), Offset(s * 0.96, s * 0.10), Offset(s * 0.90, s * 0.40), Offset(s * 0.98, s * 0.56)]), wfill);
        final bodyR = Rect.fromLTWH(s * 0.34, s * 0.44, s * 0.32, s * 0.30);
        c.drawRRect(RRect.fromRectAndRadius(bodyR, Radius.circular(s * 0.12)), fill);
        c.drawRRect(RRect.fromRectAndRadius(bodyR, Radius.circular(s * 0.12)), ol);
        stroke(Offset(s * 0.34, s * 0.60), Offset(s * 0.06, s * 0.84), s * 0.05, body); // 꼬리
        stroke(Offset(s * 0.40, s * 0.92), Offset(s * 0.40, s * 0.74), s * 0.06, dark); // 다리
        stroke(Offset(s * 0.60, s * 0.92), Offset(s * 0.60, s * 0.74), s * 0.06, dark);
        // 목 + 머리.
        stroke(Offset(s * 0.58, s * 0.48), Offset(s * 0.74, s * 0.26), s * 0.10, body);
        final head = Offset(s * 0.78, s * 0.22);
        c.drawCircle(head, s * 0.11, fill);
        c.drawCircle(head, s * 0.11, ol);
        fillPath(poly([head + Offset(-s * 0.02, -s * 0.08), head + Offset(-s * 0.10, -s * 0.18), head + Offset(s * 0.04, -s * 0.10)])); // 뿔
        c.drawCircle(head + Offset(s * 0.05, -s * 0.02), s * 0.028, Paint()..color = const Color(0xFFFFEB3B)); // 눈
        break;

      case MonsterShape.griffin:
        // 사자 몸 + 날개 + 독수리 머리(부리).
        c.drawPath(poly([Offset(cx, s * 0.42), Offset(s * 0.04, s * 0.12), Offset(s * 0.12, s * 0.42), Offset(s * 0.02, s * 0.56)]), Paint()..color = dark);
        c.drawPath(poly([Offset(cx, s * 0.42), Offset(s * 0.96, s * 0.12), Offset(s * 0.88, s * 0.42), Offset(s * 0.98, s * 0.56)]), Paint()..color = dark);
        final bodyR = Rect.fromLTWH(s * 0.28, s * 0.46, s * 0.40, s * 0.26);
        c.drawRRect(RRect.fromRectAndRadius(bodyR, Radius.circular(s * 0.12)), fill);
        c.drawRRect(RRect.fromRectAndRadius(bodyR, Radius.circular(s * 0.12)), ol);
        for (final lx in [0.34, 0.46, 0.60]) {
          stroke(Offset(s * lx, s * 0.70), Offset(s * lx, s * 0.92), s * 0.06, dark);
        }
        // 독수리 머리(밝은 색).
        final hc = Offset(s * 0.72, s * 0.36);
        c.drawCircle(hc, s * 0.12, Paint()..color = const Color(0xFFF5F5F5));
        c.drawCircle(hc, s * 0.12, ol);
        fillPath(poly([hc + Offset(s * 0.08, -s * 0.02), hc + Offset(s * 0.22, s * 0.02), hc + Offset(s * 0.08, s * 0.06)]), Paint()..color = const Color(0xFFFFB300)); // 부리
        c.drawCircle(hc + Offset(s * 0.02, -s * 0.02), s * 0.026, Paint()..color = const Color(0xFF1A1A1A));
        break;
    }
  }

  // 공용 인간형(머리+몸통+팔다리). headR/bodyW/top 은 s 비율.
  void _humanoid(
    Canvas c,
    double s,
    Paint fill,
    Paint ol,
    void Function(double, double, double, {Color col}) eyes,
    void Function(Offset, Offset, double, [Color?]) stroke, {
    required double headR,
    required double bodyW,
    required double top,
  }) {
    final cx = s / 2;
    final dark = (ol.color);
    final headC = Offset(cx, s * (top + headR));
    // 몸통.
    final torso = Rect.fromLTWH(cx - s * bodyW / 2, s * (top + headR * 1.7), s * bodyW, s * 0.40);
    c.drawRRect(RRect.fromRectAndRadius(torso, Radius.circular(s * 0.08)), fill);
    c.drawRRect(RRect.fromRectAndRadius(torso, Radius.circular(s * 0.08)), ol);
    // 팔.
    stroke(Offset(cx - s * bodyW / 2, s * 0.46), Offset(cx - s * (bodyW / 2 + 0.10), s * 0.66), s * 0.07, dark);
    stroke(Offset(cx + s * bodyW / 2, s * 0.46), Offset(cx + s * (bodyW / 2 + 0.10), s * 0.66), s * 0.07, dark);
    // 다리.
    stroke(Offset(cx - s * 0.08, s * 0.74), Offset(cx - s * 0.10, s * 0.94), s * 0.08, dark);
    stroke(Offset(cx + s * 0.08, s * 0.74), Offset(cx + s * 0.10, s * 0.94), s * 0.08, dark);
    // 머리.
    c.drawCircle(headC, s * headR, fill);
    c.drawCircle(headC, s * headR, ol);
    eyes(cx, headC.dy, s * 0.035);
  }
}
