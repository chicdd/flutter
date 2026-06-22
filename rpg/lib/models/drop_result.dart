// 드랍 결과 DTO (§9 models). rpc_report_kill 응답.
// 권위 불변식(§3.1): 클라이언트는 이 결과를 "표시"만 한다. 인벤토리는 서버가 갱신했다.

class DropResult {
  final bool alreadyClaimed;
  final String? templateId;
  final int quantity;
  final String? itemId;

  DropResult({
    required this.alreadyClaimed,
    this.templateId,
    this.quantity = 0,
    this.itemId,
  });

  bool get hasDrop => templateId != null;

  factory DropResult.fromJson(Map<String, dynamic> j) {
    final drop = j['drop'] as Map<String, dynamic>?;
    return DropResult(
      alreadyClaimed: j['already_claimed'] == true,
      templateId: drop?['template_id'] as String?,
      quantity: drop == null ? 0 : ((drop['quantity'] as num?)?.toInt() ?? 0),
      itemId: drop?['item_id'] as String?,
    );
  }
}
