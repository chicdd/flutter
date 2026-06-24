// 인벤토리 내용 위젯 — 모바일 전체화면(CharacterScreen)과 데스크탑 우측 오버레이 양쪽에서 공용.
// 기능: 아바타 변경, 장비 장착/해제, 격자 가방, 우클릭 잠금, 롱프레스 즉시판매, 비교 화살표,
//       약한장비/잡템 일괄판매, 포션/귀환주문서 사용.
import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/gear.dart';
import '../models/items.dart';
import '../state/player_profile.dart';
import '../util/avatar.dart';
import 'widgets/gear_name.dart';
import 'widgets/gear_tooltip.dart';
import 'widgets/item_icon.dart';

class InventoryPanel extends StatelessWidget {
  final PlayerProfile profile;
  final VoidCallback? onClose;
  final VoidCallback? onUseTownScroll; // 게임에서 텔레포트 처리
  // 클릭-투-무브 드래그(데스크탑). 이 콜백들이 없으면 기존 탭=상세시트 동작(모바일).
  final List<GlobalKey>? cellKeys; // 칸 i 의 hit-test 키
  final void Function(int bagIndex)? onPickCell; // 단일클릭=집기
  final void Function(GearItem gear)? onEquipItem; // 더블클릭=착용
  final void Function(MiscItem misc)? onUseItem; // 더블클릭=사용
  final void Function(BagItem item, Offset globalPos)? onItemMenu; // 우클릭=컨텍스트 메뉴(판매/잠금)
  final int? hiddenIndex; // 드래그로 집어든 칸 — 비어 보이게 한다

  const InventoryPanel({
    super.key,
    required this.profile,
    this.onClose,
    this.onUseTownScroll,
    this.cellKeys,
    this.onPickCell,
    this.onEquipItem,
    this.onUseItem,
    this.onItemMenu,
    this.hiddenIndex,
  });

  bool get _dragMode => onPickCell != null;

  static IconData miscIcon(MiscKind k) => switch (k) {
        MiscKind.healthPotion || MiscKind.potionMedium || MiscKind.potionLarge => Icons.local_drink,
        MiscKind.townScroll => Icons.auto_stories,
        MiscKind.monsterHide => Icons.cruelty_free,
        MiscKind.magicCrystal => Icons.diamond,
        MiscKind.ancientCoin => Icons.paid,
        MiscKind.skillReset => Icons.restart_alt,
        MiscKind.skillRefund => Icons.undo,
      };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: profile,
      builder: (context, _) => SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context),
            const SizedBox(height: 10),
            _actions(context),
            const SizedBox(height: 14),
            Row(children: [
              const Text('가방', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text('${profile.bag.length}/${PlayerProfile.bagCapacity}',
                  style: const TextStyle(color: Colors.white54)),
              const Spacer(),
              const Text('우클릭=잠금', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ]),
            const SizedBox(height: 8),
            _bagGrid(context),
          ],
        ),
      ),
    );
  }

  Future<void> _changeAvatar(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final b64 = await pickAvatarBase64();
    if (b64 == null) return;
    profile.setAvatar(b64);
    messenger.showSnackBar(const SnackBar(content: Text('아바타가 변경되었습니다.')));
  }

  Widget _avatarCircle() {
    final b64 = profile.avatarBase64;
    if (b64 != null) {
      return CircleAvatar(radius: 22, backgroundImage: MemoryImage(base64Decode(b64)));
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFFFFA000),
      child: Text('${profile.level}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xCC2C2C2C), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _changeAvatar(context),
            child: Stack(children: [
              _avatarCircle(),
              const Positioned(
                right: 0,
                bottom: 0,
                child: CircleAvatar(radius: 8, backgroundColor: Color(0xFF1E1E1E), child: Icon(Icons.photo_camera, size: 11, color: Colors.white)),
              ),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lv.${profile.level}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: profile.expRatio,
                    minHeight: 6,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF7E57C2)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Row(children: [
              const Icon(Icons.monetization_on, color: Color(0xFFFFD54F), size: 16),
              const SizedBox(width: 3),
              Text('${profile.gold}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFD54F))),
            ]),
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.local_drink, color: Color(0xFF69F0AE), size: 16),
              const SizedBox(width: 3),
              Text('${profile.potions}'),
              const SizedBox(width: 8),
              const Icon(Icons.auto_stories, color: Color(0xFF80CBC4), size: 16),
              const SizedBox(width: 3),
              Text('${profile.townScrolls}'),
            ]),
          ]),
          if (onClose != null)
            IconButton(onPressed: onClose, icon: const Icon(Icons.close), tooltip: '닫기 (I)'),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context) {
    void snack(String m) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m), duration: const Duration(milliseconds: 1000)));
    return Row(children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () {
            final g = profile.sellWeakerThanEquipped();
            snack(g > 0 ? '약한 장비 판매: +${g}G' : '판매할 약한 장비가 없습니다.');
          },
          icon: const Icon(Icons.trending_down, size: 18),
          label: const Text('약한장비 판매', style: TextStyle(fontSize: 12)),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () {
            final g = profile.sellBulk();
            snack(g > 0 ? '잡템 판매: +${g}G' : '판매할 잡템이 없습니다.');
          },
          icon: const Icon(Icons.delete_sweep, size: 18),
          label: const Text('잡템 판매', style: TextStyle(fontSize: 12)),
        ),
      ),
      const SizedBox(width: 8),
      // 정렬: 클릭 또는 hover 시 가방 정렬(기본은 정렬 안 함).
      MouseRegion(
        onEnter: (_) => profile.sortBag(),
        child: Tooltip(
          message: '아이템 정렬 (등급순)',
          child: OutlinedButton(
            onPressed: profile.sortBag,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 40),
            ),
            child: const Icon(Icons.sort, size: 18),
          ),
        ),
      ),
    ]);
  }

  Widget _bagGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: PlayerProfile.bagCapacity,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 60,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, i) {
        final item = i < profile.bag.length ? profile.bag[i] : null;
        return _bagCell(context, i, item);
      },
    );
  }

  Widget _bagCell(BuildContext context, int index, BagItem? item) {
    final cellKey = (cellKeys != null && index < cellKeys!.length) ? cellKeys![index] : null;
    // 드래그로 집어든 칸은 비어 보이게 한다.
    final shown = index == hiddenIndex ? null : item;
    if (shown == null) {
      // 빈 칸(또는 집어든 칸)도 드래그 놓기 대상이 되도록 키를 부여.
      return DecoratedBox(
        key: cellKey,
        decoration: BoxDecoration(
          color: const Color(0x4015181E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
      );
    }
    final body = Stack(children: [
      Positioned.fill(child: LayoutBuilder(builder: (context, c) => ItemIcon.forItem(shown, size: c.maxWidth))),
      if (shown.locked)
        const Positioned(left: 2, top: 2, child: Icon(Icons.lock, size: 13, color: Colors.amberAccent)),
    ]);
    final cell = GestureDetector(
      // 드래그 모드: 단일클릭=집기 / 더블클릭=착용·사용 / 우클릭=판매·잠금 메뉴.
      // 일반 모드(모바일): 탭=상세시트 / 우클릭=잠금 토글.
      onTap: _dragMode ? () => onPickCell!(index) : () => _itemSheet(context, shown),
      onDoubleTap: _dragMode
          ? () {
              if (shown is GearItem) {
                onEquipItem?.call(shown);
              } else if (shown is MiscItem) {
                onUseItem?.call(shown);
              }
            }
          : null,
      onSecondaryTapDown:
          _dragMode && onItemMenu != null ? (d) => onItemMenu!(shown, d.globalPosition) : null,
      onSecondaryTap: _dragMode ? null : () => profile.toggleLock(shown),
      child: KeyedSubtree(key: cellKey, child: body),
    );
    // 모든 아이템 hover 시 정보 카드(데스크탑 hover / 모바일 롱프레스).
    // 장비면 같은 종류로 장착 중인 장비를 hover 카드 왼쪽에 비교 표시.
    final compare = shown is GearItem ? profile.equippedComparable(shown.kind) : null;
    return ItemHoverTooltip(item: shown, compareTo: compare, child: cell);
  }

  void _itemSheet(BuildContext context, BagItem item) {
    if (item is GearItem) {
      _gearSheet(context, item);
    } else if (item is MiscItem) {
      _miscSheet(context, item);
    }
  }

  Widget _lockTile(StateSetter setSheet, BagItem item) {
    return SwitchListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: const Text('판매 잠금'),
      value: item.locked,
      onChanged: (v) {
        profile.toggleLock(item);
        setSheet(() {});
      },
    );
  }

  void _gearSheet(BuildContext context, GearItem g) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                ItemIcon(glyph: g.weaponType != null ? glyphForWeapon(g.weaponType!) : glyphForKind(g.kind), rarity: g.rarity, size: 44),
                const SizedBox(width: 10),
                Expanded(child: EnhancedItemName.gear(g, fontSize: 18, maxLines: 2)),
                if (g.locked) const Icon(Icons.lock, size: 16, color: Colors.amberAccent),
                const SizedBox(width: 4),
                Text('iLv ${g.itemLevel}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ]),
              const SizedBox(height: 4),
              Text('${g.rarity.label} · ${g.weaponType != null ? g.weaponType!.label : g.kind.baseName}',
                  style: const TextStyle(color: Colors.white54)),
              const Divider(height: 18),
              if (profile.equippedComparable(g.kind) != null)
                const Padding(padding: EdgeInsets.only(bottom: 6), child: Text('현재 장착 대비', style: TextStyle(color: Colors.white38, fontSize: 11))),
              ..._gearStatRows(g),
              _lockTile(setSheet, g),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      profile.equip(g);
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('장착'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: g.locked ? null : () { profile.sell(g); Navigator.pop(ctx); },
                  icon: const Icon(Icons.sell, size: 18),
                  label: Text('판매 ${g.sellPrice}G'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _miscSheet(BuildContext context, MiscItem m) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(miscIcon(m.kind), color: Color(m.rarity.colorValue)),
                const SizedBox(width: 8),
                Expanded(child: Text('${m.name}  x${m.quantity}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(m.rarity.colorValue)))),
                if (m.locked) const Icon(Icons.lock, size: 16, color: Colors.amberAccent),
              ]),
              const SizedBox(height: 6),
              Text(
                m.kind.usableHeal
                    ? '사용 시 최대 체력의 ${(m.kind.healPercent * 100).round()}%를 회복합니다.'
                    : m.kind.isTownScroll
                        ? '사용 시 마을로 즉시 귀환합니다. (단축키 B)'
                        : '판매하여 골드를 얻을 수 있는 재료입니다.',
                style: const TextStyle(color: Colors.white54),
              ),
              _lockTile(setSheet, m),
              const SizedBox(height: 8),
              Row(children: [
                if (m.kind.usableHeal)
                  Expanded(child: FilledButton.icon(onPressed: () { profile.usePotion(); Navigator.pop(ctx); }, icon: const Icon(Icons.healing), label: const Text('사용'))),
                if (m.kind.isTownScroll && onUseTownScroll != null)
                  Expanded(child: FilledButton.icon(onPressed: () { Navigator.pop(ctx); onUseTownScroll!(); }, icon: const Icon(Icons.home), label: const Text('귀환'))),
                if (m.kind.usableHeal || (m.kind.isTownScroll && onUseTownScroll != null)) const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: m.locked ? null : () { profile.sell(m); Navigator.pop(ctx); },
                    icon: const Icon(Icons.sell, size: 18),
                    label: Text('판매 ${m.sellPrice}G'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _gearStatRows(GearItem g) {
    final base = profile.equippedComparable(g.kind)?.bonus;
    final b = g.bonus;
    String fmt(double v, int mode) => switch (mode) {
          1 => '+${(v * 100).toStringAsFixed(0)}%',
          2 => '+${v.toStringAsFixed(2)}',
          _ => '+${v.round()}',
        };
    Widget row(String label, double nv, double ov, int mode) {
      Widget? arrow;
      if (base != null && nv != ov) {
        final up = nv > ov;
        arrow = Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(up ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: up ? const Color(0xFF66BB6A) : const Color(0xFFEF5350)),
          Text(fmt(nv - ov, mode), style: TextStyle(fontSize: 11, color: up ? const Color(0xFF66BB6A) : const Color(0xFFEF5350))),
        ]);
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Expanded(child: Text('• $label', style: const TextStyle(color: Colors.white70, fontSize: 13))),
          Text(fmt(nv, mode), style: const TextStyle(color: Color(0xFF81C784), fontSize: 13)),
          if (arrow != null) ...[const SizedBox(width: 8), arrow],
        ]),
      );
    }

    final rows = <Widget>[];
    void maybe(String label, double nv, double ov, int mode) {
      if (nv != 0 || ov != 0) rows.add(row(label, nv, ov, mode));
    }

    maybe('공격력', b.attack, base?.attack ?? 0, 0);
    maybe('방어력', b.defense, base?.defense ?? 0, 0);
    maybe('최대 체력', b.maxHp, base?.maxHp ?? 0, 0);
    maybe('방어구 관통', b.armorPen, base?.armorPen ?? 0, 0);
    maybe('크리티컬 확률', b.critChance, base?.critChance ?? 0, 1);
    maybe('크리티컬 배수', b.critMultiplier, base?.critMultiplier ?? 0, 2);
    maybe('공격 속도', b.attackSpeed, base?.attackSpeed ?? 0, 2);
    if (rows.isEmpty) rows.add(const Text('• 옵션 없음', style: TextStyle(color: Color(0xFF81C784), fontSize: 13)));
    return rows;
  }
}
