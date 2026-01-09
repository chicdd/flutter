/// 고객정보 변동이력 데이터 모델
class CustomerHistoryData {
  final String handler;
  final DateTime? changeDateTime;
  final String beforeValue;
  final String afterValue;
  final String memo;

  CustomerHistoryData({
    required this.handler,
    required this.changeDateTime,
    required this.beforeValue,
    required this.afterValue,
    required this.memo,
  });

  factory CustomerHistoryData.fromJson(Map<String, dynamic> json) {
    return CustomerHistoryData(
      handler: json['처리자'] ?? '',
      changeDateTime: json['변경처리일시'] != null
          ? DateTime.tryParse(json['변경처리일시'])
          : null,
      beforeValue: json['변경전'] ?? '',
      afterValue: json['변경후'] ?? '',
      memo: json['메모'] ?? '',
    );
  }

  // 날짜 시간 형식 변환 (yyyy-MM-dd HH:mm:ss)
  String get changeDateTimeFormatted {
    if (changeDateTime == null) return '';
    return '${changeDateTime!.year}-${changeDateTime!.month.toString().padLeft(2, '0')}-${changeDateTime!.day.toString().padLeft(2, '0')} '
        '${changeDateTime!.hour.toString().padLeft(2, '0')}:${changeDateTime!.minute.toString().padLeft(2, '0')}:${changeDateTime!.second.toString().padLeft(2, '0')}';
  }
}
