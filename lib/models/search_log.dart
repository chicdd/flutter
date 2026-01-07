/// 검색로그 데이터 모델
class SearchLogData {
  final String name;
  final DateTime? recordDate;
  final String recordTime;
  final String inputContent;

  SearchLogData({
    required this.name,
    required this.recordDate,
    required this.recordTime,
    required this.inputContent,
  });

  factory SearchLogData.fromJson(Map<String, dynamic> json) {
    return SearchLogData(
      name: json['성명'] ?? '',
      recordDate: json['기록일자'] != null
          ? DateTime.tryParse(json['기록일자'])
          : null,
      recordTime: json['기록시간'] ?? '',
      inputContent: json['입력내용'] ?? '',
    );
  }

  // 날짜 형식 변환 (yyyy-MM-dd)
  String get recordDateFormatted {
    if (recordDate == null) return '';
    return '${recordDate!.year}-${recordDate!.month.toString().padLeft(2, '0')}-${recordDate!.day.toString().padLeft(2, '0')}';
  }
}
