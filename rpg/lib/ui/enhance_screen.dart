// 장비 강화소(대장장이) — 가방의 장비를 선택해 강화. 천장(보정) 시스템 포함.
// 표시: 강화확률 / 실패확률 / (유지·하락·파괴) / 천장 누적·잔여 / 비용.
import 'package:flutter/material.dart';

import '../models/enhance.dart';
import '../models/gear.dart';
import '../state/player_profile.dart';
import 'widgets/item_icon.dart';

class EnhanceScreen extends StatefulWidget {
  final PlayerProfile profile;
  final String title;
  const EnhanceScreen({super.key, required this.profile, this.title = '대장간 · 장비 강화'});

  @override
  State<EnhanceScreen> createState() => _EnhanceScreenState();
}

class _EnhanceScreenState extends State<EnhanceScreen> {
  GearItem? _sel;
  String? _msg;
  Color _msgColor = Colors.white70;

  PlayerProfile get p => widget.profile;

  void _enhance() {
    final g = _sel;
    if (g == null) return;
    final info = EnhanceSystem.infoFor(g.enhanceLevel, g.enhanceStack);
    if (info.maxed) return;
    if (p.gold < info.cost) {
      setState(() {
        _msg = '골드가 부족합니다 (${info.cost}G 필요)';
        _msgColor = const Color(0xFFEF5350);
      });
      return;
    }
    final res = p.tryEnhance(g);
    setState(() {
      switch (res) {
        case EnhanceResult.success:
          _msg = '강화 성공! +${g.enhanceLevel}';
          _msgColor = const Color(0xFF66BB6A);
          break;
        case EnhanceResult.keep:
          _msg = '강화 실패 — 단계 유지 (천장 +1)';
          _msgColor = const Color(0xFFFFB300);
          break;
        case EnhanceResult.downgrade:
          _msg = '강화 실패 — 단계 하락… (+${g.enhanceLevel})';
          _msgColor = const Color(0xFFFF8A65);
          break;
        case EnhanceResult.destroy:
          _msg = '💥 강화 실패 — 장비가 파괴되었습니다!';
          _msgColor = const Color(0xFFEF5350);
          _sel = null;
          break;
        case null:
          _msg = '강화할 수 없습니다.';
          _msgColor = Colors.white70;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListenableBuilder(
        listenable: p,
        builder: (context, _) {
          final gears = p.bag.whereType<GearItem>().toList();
          // 선택이 파괴/소멸됐으면 해제.
          if (_sel != null && !p.bag.contains(_sel)) _sel = null;
          return Row(
            children: [
              // 좌: 강화할 장비 목록.
              SizedBox(
                width: 150,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(10),
                      child: Text('장비 선택', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: gears.isEmpty
                          ? const Center(child: Text('장비가 없습니다.', style: TextStyle(color: Colors.white38)))
                          : ListView.builder(
                              itemCount: gears.length,
                              itemBuilder: (context, i) {
                                final g = gears[i];
                                final selected = identical(g, _sel);
                                return ListTile(
                                  dense: true,
                                  selected: selected,
                                  selectedTileColor: const Color(0x332196F3),
                                  leading: ItemIcon(
                                    glyph: g.weaponType != null ? glyphForWeapon(g.weaponType!) : glyphForKind(g.kind),
                                    rarity: g.rarity,
                                    size: 34,
                                  ),
                                  title: Text(g.displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Color(g.rarity.colorValue), fontSize: 12)),
                                  onTap: () => setState(() {
                                    _sel = g;
                                    _msg = null;
                                  }),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              // 우: 강화 패널.
              Expanded(child: _sel == null ? _empty() : _panel(_sel!)),
            ],
          );
        },
      ),
    );
  }

  Widget _empty() => const Center(
      child: Text('강화할 장비를 선택하세요.', style: TextStyle(color: Colors.white38, fontSize: 15)));

  Widget _panel(GearItem g) {
    final info = EnhanceSystem.infoFor(g.enhanceLevel, g.enhanceStack);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            ItemIcon(
                glyph: g.weaponType != null ? glyphForWeapon(g.weaponType!) : glyphForKind(g.kind),
                rarity: g.rarity,
                size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(g.displayName,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(g.rarity.colorValue))),
                Text('${g.rarity.label} · ${g.kind.baseName} · iLv ${g.itemLevel}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ]),
            ),
            Row(children: [
              const Icon(Icons.monetization_on, color: Color(0xFFFFD54F), size: 16),
              const SizedBox(width: 3),
              Text('${p.gold}', style: const TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold)),
            ]),
          ]),
          const SizedBox(height: 14),

          if (info.maxed)
            _box(const Color(0x33FFD54F), const Text('최대 강화(+20)에 도달했습니다.',
                textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold)))
          else ...[
            // 단계 + 능력치 미리보기.
            _box(const Color(0x33263238), Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('+${g.enhanceLevel}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.arrow_forward, size: 18)),
                Text('+${info.target}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF66BB6A))),
              ]),
              const SizedBox(height: 8),
              ..._statPreview(g),
            ])),
            const SizedBox(height: 12),

            // 확률 표시(절대 확률, 합 100).
            Row(children: [
              Expanded(child: _prob('강화 확률', info.success, const Color(0xFF66BB6A), big: true)),
              const SizedBox(width: 8),
              Expanded(child: _prob('실패 확률', info.fail, const Color(0xFFEF5350), big: true)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _prob('유지', info.keep, const Color(0xFF90A4AE))),
              const SizedBox(width: 6),
              Expanded(child: _prob('하락', info.downgrade, const Color(0xFFFF8A65))),
              const SizedBox(width: 6),
              Expanded(child: _prob('파괴', info.destroy, const Color(0xFFD32F2F))),
            ]),
            const SizedBox(height: 12),

            // 천장(보정) 상태.
            _box(const Color(0x332E2A40), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.shield_moon, size: 16, color: Color(0xFFB39DDB)),
                const SizedBox(width: 6),
                const Text('천장(실패 보정)', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (info.pityMax > 0)
                  Text('누적 ${info.stack} / ${info.pityMax}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
              const SizedBox(height: 6),
              if (info.pityMax > 0) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (info.stack / info.pityMax).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFB39DDB)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '실패 1회당 +${info.step.toStringAsFixed(1)}%p · 앞으로 ${info.pityRemaining}회 실패 시 100% 확정',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ] else
                const Text('이 구간은 항상 100% 성공입니다.', style: TextStyle(color: Colors.white60, fontSize: 12)),
            ])),
            const SizedBox(height: 14),

            if (_msg != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(_msg!, textAlign: TextAlign.center, style: TextStyle(color: _msgColor, fontWeight: FontWeight.bold)),
              ),

            FilledButton.icon(
              onPressed: p.gold >= info.cost ? _enhance : null,
              icon: const Icon(Icons.flash_on),
              label: Text('강화하기  (${info.cost} G)'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF6D4C41),
              ),
            ),
            if (info.destroy > 0)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('⚠ 이 단계부터 실패 시 장비가 파괴될 수 있습니다.',
                    textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFEF9A9A), fontSize: 12)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _box(Color color, Widget child) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: child,
      );

  Widget _prob(String label, double pct, Color color, {bool big = false}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: big ? 12 : 8, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(children: [
        Text(label, style: TextStyle(color: Colors.white70, fontSize: big ? 13 : 11)),
        const SizedBox(height: 2),
        Text('${pct.toStringAsFixed(pct >= 10 ? 0 : 1)}%',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: big ? 22 : 15)),
      ]),
    );
  }

  // 현재 → 다음 단계 능력치 미리보기.
  List<Widget> _statPreview(GearItem g) {
    final cur = g.effectiveBonus;
    final next = g.bonus.scaled(EnhanceSystem.statMult(g.enhanceLevel + 1));
    final rows = <Widget>[];
    void row(String label, double a, double b, {bool pct = false}) {
      if (a == 0 && b == 0) return;
      String f(double v) => pct ? '${(v * 100).toStringAsFixed(1)}%' : v.toStringAsFixed(1);
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))),
          Text(f(a), style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward, size: 11, color: Colors.white38)),
          Text(f(b), style: const TextStyle(color: Color(0xFF66BB6A), fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
      ));
    }

    row('공격력', cur.attack, next.attack);
    row('방어력', cur.defense, next.defense);
    row('최대 체력', cur.maxHp, next.maxHp);
    row('방어구 관통', cur.armorPen, next.armorPen);
    row('크리티컬 확률', cur.critChance, next.critChance, pct: true);
    row('공격 속도', cur.attackSpeed, next.attackSpeed);
    return rows;
  }
}
