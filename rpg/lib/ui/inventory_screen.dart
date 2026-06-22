// 인벤토리 화면 (§9 UI). 서버 read 결과를 표시만 한다(§3).
import 'package:flutter/material.dart';

import '../models/inventory.dart';
import '../net/nakama_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  Future<Inventory>? _future;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _future = NakamaService.instance.getInventory();
    });
  }

  static const Map<String, Color> _rarityColor = {
    'common': Color(0xFFB0BEC5),
    'uncommon': Color(0xFF66BB6A),
    'rare': Color(0xFF42A5F5),
    'epic': Color(0xFFAB47BC),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('인벤토리'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<Inventory>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('인벤토리 조회 실패\n${snap.error}', textAlign: TextAlign.center),
              ),
            );
          }
          final inv = snap.data ?? Inventory.empty();
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF2C2C2C),
                child: Text('골드: ${inv.gold}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD54F))),
              ),
              Expanded(
                child: inv.items.isEmpty
                    ? const Center(child: Text('아이템이 없습니다. 몬스터를 처치해 보세요.'))
                    : ListView.separated(
                        itemCount: inv.items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final it = inv.items[i];
                          return ListTile(
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _rarityColor[it.rarity] ?? Colors.grey,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            title: Text(it.displayName),
                            subtitle: Text('${it.type}${it.slot != null ? ' · ${it.slot}' : ''}'
                                '${it.bound ? ' · 귀속' : ''}'),
                            trailing: it.quantity > 1 ? Text('x${it.quantity}') : null,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
