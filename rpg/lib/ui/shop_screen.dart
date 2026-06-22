// 상점 — 포션(초/중/고급), 마을 귀환 주문서, 장비 뽑기(골드로 뽑기 레벨업 → 내 레벨 맞춤 장비),
// 약한 장비/잡템 일괄 판매. 메뉴 탭과 마을 상인 NPC 양쪽에서 ShopView 를 공용으로 쓴다.
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/gear.dart';
import '../models/items.dart';
import '../state/player_profile.dart';
import 'widgets/item_icon.dart';

class ShopScreen extends StatelessWidget {
  final PlayerProfile profile;
  final String title;
  const ShopScreen({super.key, required this.profile, this.title = '상점'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ShopView(profile: profile),
    );
  }
}

class ShopView extends StatefulWidget {
  final PlayerProfile profile;
  const ShopView({super.key, required this.profile});

  @override
  State<ShopView> createState() => _ShopViewState();
}

class _ShopViewState extends State<ShopView> {
  static const int scrollPrice = 40;
  static const int drawPrice = 120;
  final _rng = Random();
  String? _msg;

  PlayerProfile get p => widget.profile;

  void _show(String m) => setState(() => _msg = m);

  void _buyPotion(MiscKind kind, int price, int n) {
    if (!p.spendGold(price * n)) return _show('골드가 부족합니다.');
    p.addItem(MiscItem(id: _id(), kind: kind, quantity: n));
    _show('${kind.name} x$n 구매!');
  }

  void _buyScroll(int n) {
    if (!p.spendGold(scrollPrice * n)) return _show('골드가 부족합니다.');
    p.addItem(MiscItem(id: _id(), kind: MiscKind.townScroll, quantity: n));
    _show('마을 귀환 주문서 x$n 구매!');
  }

  void _upgradeGacha() {
    final cost = p.gachaUpgradeCost;
    if (!p.upgradeGacha()) return _show('골드가 부족합니다. (필요 ${cost}G)');
    _show('장비 뽑기 레벨 ${p.gachaLevel} 달성!');
  }

  Rarity _drawRarity() {
    final gl = p.gachaLevel;
    final r = _rng.nextDouble();
    final leg = (gl * 0.004).clamp(0.0, 0.08);
    final epic = (gl * 0.012).clamp(0.0, 0.25);
    if (r < (gl * 0.0008).clamp(0.0, 0.02)) return Rarity.mythic;
    if (r < leg) return Rarity.legendary;
    if (r < leg + epic) return Rarity.epic;
    if (r < leg + epic + 0.32) return Rarity.rare;
    return Rarity.uncommon;
  }

  void _draw() {
    if (p.bagFull) return _show('가방이 가득 찼습니다.');
    if (!p.spendGold(drawPrice)) return _show('골드가 부족합니다.');
    // 뽑기 레벨이 내 레벨까지 올라야 내 레벨 장비가 나온다.
    final lvl = min(p.level, p.gachaLevel);
    final item = GearGenerator.random(level: lvl, rarity: _drawRarity(), rng: _rng);
    p.addItem(item);
    _show('${item.rarity.label} ${item.name} (iLv ${item.itemLevel}) 획득!');
  }

  String _id() => 's${DateTime.now().microsecondsSinceEpoch}_${_rng.nextInt(9999)}';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: p,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Row(children: [
            const Icon(Icons.monetization_on, color: Color(0xFFFFD54F)),
            const SizedBox(width: 6),
            Text('보유 골드: ${p.gold}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFD54F))),
          ]),
          if (_msg != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_msg!, style: const TextStyle(color: Colors.lightGreenAccent)),
            ),
          const Divider(height: 28),

          // 장비 뽑기.
          _box(
            ItemIcon(glyph: ItemGlyph.crystal, rarity: Rarity.epic, size: 44),
            '장비 뽑기  (뽑기 레벨 ${p.gachaLevel})',
            '뽑기 레벨까지의 장비가 나옵니다(현재 iLv ${min(p.level, p.gachaLevel)}). 내 레벨(${p.level})에 맞추려면 레벨업하세요.',
            [
              FilledButton.icon(onPressed: _draw, icon: const Icon(Icons.casino), label: const Text('뽑기 ${drawPrice}G')),
              const SizedBox(width: 8),
              OutlinedButton(
                  onPressed: _upgradeGacha, child: Text('뽑기 레벨업 ${p.gachaUpgradeCost}G')),
            ],
          ),

          // 포션.
          _box(
            ItemIcon(glyph: ItemGlyph.potion, rarity: Rarity.common, size: 44),
            '초급 포션 (30% 회복)',
            '개당 8G',
            [
              FilledButton(onPressed: () => _buyPotion(MiscKind.healthPotion, 8, 1), child: const Text('1개')),
              const SizedBox(width: 8),
              FilledButton(onPressed: () => _buyPotion(MiscKind.healthPotion, 8, 10), child: const Text('10개')),
            ],
          ),
          _box(
            ItemIcon(glyph: ItemGlyph.potion, rarity: Rarity.uncommon, size: 44),
            '중급 포션 (55% 회복)',
            '개당 20G',
            [
              FilledButton(onPressed: () => _buyPotion(MiscKind.potionMedium, 20, 1), child: const Text('1개')),
              const SizedBox(width: 8),
              FilledButton(onPressed: () => _buyPotion(MiscKind.potionMedium, 20, 5), child: const Text('5개')),
            ],
          ),
          _box(
            ItemIcon(glyph: ItemGlyph.potion, rarity: Rarity.rare, size: 44),
            '고급 포션 (80% 회복)',
            '개당 45G',
            [
              FilledButton(onPressed: () => _buyPotion(MiscKind.potionLarge, 45, 1), child: const Text('1개')),
              const SizedBox(width: 8),
              FilledButton(onPressed: () => _buyPotion(MiscKind.potionLarge, 45, 3), child: const Text('3개')),
            ],
          ),

          // 마을 귀환 주문서.
          _box(
            const Icon(Icons.auto_stories, color: Color(0xFF80CBC4), size: 34),
            '마을 귀환 주문서',
            '사용 시 마을로 즉시 귀환 (단축키 B) · 개당 ${scrollPrice}G',
            [
              FilledButton(onPressed: () => _buyScroll(1), child: const Text('1개')),
              const SizedBox(width: 8),
              FilledButton(onPressed: () => _buyScroll(5), child: const Text('5개')),
            ],
          ),

          const Divider(height: 28),
          _box(
            const Icon(Icons.trending_down, color: Color(0xFFEF9A9A), size: 34),
            '약한 장비 일괄 판매',
            '장착 장비보다 약한(잠금 제외) 장비를 모두 판매',
            [OutlinedButton.icon(
                onPressed: () => _show('약한 장비 판매: +${p.sellWeakerThanEquipped()}G'),
                icon: const Icon(Icons.sell),
                label: const Text('판매'))],
          ),
          _box(
            const Icon(Icons.delete_sweep, color: Color(0xFFEF9A9A), size: 34),
            '잡템 일괄 판매',
            '평범/고급 장비 + 재료(잠금 제외) 판매',
            [OutlinedButton.icon(
                onPressed: () => _show('잡템 판매: +${p.sellBulk()}G'),
                icon: const Icon(Icons.sell),
                label: const Text('판매'))],
          ),
        ],
      ),
    );
  }

  Widget _box(Widget leading, String title, String desc, List<Widget> actions) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF242424), borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 46, height: 46, child: Center(child: leading)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(spacing: 0, runSpacing: 6, children: actions),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
