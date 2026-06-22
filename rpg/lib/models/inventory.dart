// 인벤토리 DTO (§9 models). rpc_get_inventory → get_inventory() 결과 매핑.
// 서버 응답을 표시만 한다(§3, §9 상태 규칙). 로컬을 source of truth 로 쓰지 않는다.

class InventoryItem {
  final String id;
  final String templateId;
  final String name;
  final String type;
  final String? slot;
  final String rarity;
  final int quantity;
  final int enhanceLevel;
  final bool bound;
  final String location;
  final Map<String, dynamic> baseStats;

  InventoryItem({
    required this.id,
    required this.templateId,
    required this.name,
    required this.type,
    required this.slot,
    required this.rarity,
    required this.quantity,
    required this.enhanceLevel,
    required this.bound,
    required this.location,
    required this.baseStats,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> j) => InventoryItem(
        id: j['id'] as String,
        templateId: j['template_id'] as String,
        name: (j['name'] as String?) ?? j['template_id'] as String,
        type: (j['type'] as String?) ?? 'misc',
        slot: j['slot'] as String?,
        rarity: (j['rarity'] as String?) ?? 'common',
        quantity: (j['quantity'] as num?)?.toInt() ?? 1,
        enhanceLevel: (j['enhance_level'] as num?)?.toInt() ?? 0,
        bound: j['bound'] == true,
        location: (j['location'] as String?) ?? 'inventory',
        baseStats: (j['base_stats'] as Map<String, dynamic>?) ?? const {},
      );

  String get displayName =>
      enhanceLevel > 0 ? '$name +$enhanceLevel' : name;
}

class Inventory {
  final int gold;
  final List<InventoryItem> items;

  Inventory({required this.gold, required this.items});

  factory Inventory.fromJson(Map<String, dynamic> j) => Inventory(
        gold: (j['gold'] as num?)?.toInt() ?? 0,
        items: ((j['items'] as List?) ?? const [])
            .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  factory Inventory.empty() => Inventory(gold: 0, items: const []);
}
