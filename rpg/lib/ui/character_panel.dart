// 장비창(E / 내정보) — 사람 실루엣 종이인형 + 각 부위 슬롯 + 능력치.
// 슬롯 탭 → 상세/해제. 장착은 인벤토리에서 아이템을 탭해서 수행.
import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/gear.dart';
import '../state/player_profile.dart';
import 'widgets/gear_tooltip.dart';
import 'widgets/item_icon.dart';

class CharacterPanel extends StatelessWidget {
  final PlayerProfile profile;
  final String playerName;
  final VoidCallback? onClose;
  final Map<EquipSlot, GlobalKey>? slotKeys; // 드래그 놓기 hit-test 용(빈 슬롯 포함)
  final void Function(EquipSlot slot)? onUnequip; // 더블클릭=장착 해제
  final void Function(EquipSlot slot, GearItem gear, Offset globalPos)? onSlotMenu; // 우클릭=메뉴(해제/버리기)

  const CharacterPanel({
    super.key,
    required this.profile,
    required this.playerName,
    this.onClose,
    this.slotKeys,
    this.onUnequip,
    this.onSlotMenu,
  });

  // 슬롯의 종이인형 상 위치(가로,세로 비율).
  static const Map<EquipSlot, Offset> _layout = {
    EquipSlot.helmet: Offset(0.5, 0.06),
    EquipSlot.top: Offset(0.5, 0.32),
    EquipSlot.belt: Offset(0.5, 0.50),
    EquipSlot.bottom: Offset(0.5, 0.66),
    EquipSlot.boots: Offset(0.5, 0.90),
    EquipSlot.necklace: Offset(0.14, 0.16),
    EquipSlot.shoulder: Offset(0.14, 0.36),
    EquipSlot.gloves: Offset(0.14, 0.56),
    EquipSlot.bracelet: Offset(0.14, 0.76),
    EquipSlot.weapon: Offset(0.86, 0.16),
    EquipSlot.ring1: Offset(0.86, 0.36),
    EquipSlot.ring2: Offset(0.86, 0.52),
    EquipSlot.ring3: Offset(0.86, 0.68),
    EquipSlot.ring4: Offset(0.86, 0.84),
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: profile,
      builder: (context, _) => SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            const SizedBox(height: 12),
            _paperDoll(context),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('능력치', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            const SizedBox(height: 8),
            _statBlock(),
          ],
        ),
      ),
    );
  }

  Widget _avatarCircle() {
    final b64 = profile.avatarBase64;
    if (b64 != null) {
      return CircleAvatar(radius: 26, backgroundImage: MemoryImage(base64Decode(b64)));
    }
    return CircleAvatar(
      radius: 26,
      backgroundColor: const Color(0xFFFFA000),
      child: Text('${profile.level}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16)),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0x66202833), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          _avatarCircle(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(playerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text('Lv.${profile.level}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFFFFD54F), fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: profile.expRatio,
                    minHeight: 5,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF7E57C2)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(children: [
                const Icon(Icons.monetization_on, color: Color(0xFFFFD54F), size: 15),
                const SizedBox(width: 3),
                Text('${profile.gold}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFD54F))),
              ]),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.favorite, color: Color(0xFFEF5350), size: 14),
                const SizedBox(width: 3),
                Text('${profile.hp}/${profile.maxHp}', style: const TextStyle(fontSize: 12)),
              ]),
            ],
          ),
          if (onClose != null)
            IconButton(onPressed: onClose, icon: const Icon(Icons.close), tooltip: '닫기 (E)'),
        ],
      ),
    );
  }

  Widget _paperDoll(BuildContext context) {
    const double slot = 46;
    return AspectRatio(
      aspectRatio: 0.8,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth, h = c.maxHeight;
          return Stack(
            children: [
              // 배경.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x33161B22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                ),
              ),
              // 사람 실루엣.
              Positioned.fill(child: CustomPaint(painter: _SilhouettePainter())),
              // 슬롯들.
              for (final entry in _layout.entries)
                Positioned(
                  left: entry.value.dx * w - slot / 2,
                  top: entry.value.dy * h - slot / 2,
                  child: _slot(context, entry.key, slot),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _slot(BuildContext context, EquipSlot s, double size) {
    final g = profile.equipped[s];
    final Widget inner = g == null
        ? EmptySlotIcon(slot: s, size: size)
        // hover=정보 카드(데스크탑) / 더블클릭=장착 해제 / 우클릭=메뉴(해제·버리기) / 단일탭=상세(모바일 폴백).
        : ItemHoverTooltip(
            item: g,
            child: GestureDetector(
              onTap: () => _gearDialog(context, s, g),
              onDoubleTap: () => onUnequip?.call(s),
              onSecondaryTapDown:
                  onSlotMenu != null ? (d) => onSlotMenu!(s, g, d.globalPosition) : null,
              child: ItemIcon(
                glyph: g.weaponType != null ? glyphForWeapon(g.weaponType!) : glyphForKind(g.kind),
                rarity: g.rarity,
                size: size,
              ),
            ),
          );
    // 빈 슬롯도 드래그 놓기 대상이 되도록 key 부여.
    return SizedBox(key: slotKeys?[s], width: size, height: size, child: inner);
  }

  Widget _statBlock() {
    final s = profile.total;
    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(k, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text(v, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
        );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0x66202020), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        row('최대 체력', '${s.maxHp.round()}'),
        row('공격력', '${s.attack.round()}'),
        row('방어력', '${s.defense.round()}'),
        row('방어구 관통', '${s.armorPen.round()}'),
        row('크리티컬', '${(s.critChance * 100).toStringAsFixed(0)}% / x${s.critMultiplier.toStringAsFixed(2)}'),
        row('공격 속도', '${s.attackSpeed.toStringAsFixed(2)}/s'),
      ]),
    );
  }

  void _gearDialog(BuildContext context, EquipSlot slot, GearItem g) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 강화 반영 능력치 카드(총합 + 기본/강화증가 분리).
            GearStatsCard(gear: g, width: 290),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    profile.unequip(slot);
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('해제'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('닫기')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 사람 실루엣(장비창 배경).
class _SilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w * 0.5;
    final paint = Paint()..color = const Color(0x3354627B);
    // 머리.
    canvas.drawCircle(Offset(cx, h * 0.10), w * 0.08, paint);
    // 몸통.
    final body = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - w * 0.14, h * 0.18, w * 0.28, h * 0.34), Radius.circular(w * 0.06));
    canvas.drawRRect(body, paint);
    // 팔.
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cx - w * 0.22, h * 0.2, w * 0.07, h * 0.28), Radius.circular(w * 0.03)), paint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cx + w * 0.15, h * 0.2, w * 0.07, h * 0.28), Radius.circular(w * 0.03)), paint);
    // 다리.
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cx - w * 0.12, h * 0.52, w * 0.10, h * 0.40), Radius.circular(w * 0.04)), paint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cx + w * 0.02, h * 0.52, w * 0.10, h * 0.40), Radius.circular(w * 0.04)), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
