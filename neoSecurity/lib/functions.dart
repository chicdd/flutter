List<Map<String, dynamic>> buildGrouped(List<Map<String, String>> list, works) {
  final List<Map<String, dynamic>> result = [];
  String? lastMonth;

  for (var item in list) {
    final date = item[works] ?? '';
    String month = '';

    if (date.length >= 7) {
      month = date.substring(0, 7).replaceAll('-', '.');
    } else {
      // 납입일자가 없거나 짧을 경우 매출년월 기준으로 표시
      final ym = item[works] ?? '';
      if (ym.length == 6) {
        // '202507' -> '2025.07'
        month = '${ym.substring(0, 4)}.${ym.substring(4, 6)}';
      } else {
        month = '미정'; // 기타 fallback
      }
    }

    // 월이 달라지면 헤더 추가
    if (lastMonth != month) {
      result.add({'type': 'header', 'month': month});
      lastMonth = month;
    }

    // 항목 추가
    result.add({'type': 'item', 'data': item});
  }

  return result;
}

String dateconvert(String? isoDate) {
  if (isoDate == null || isoDate.trim().isEmpty) return '';
  return isoDate.split('T').first; // "2025-07-13T00:00:00+09:00" → "2025-07-13"
}
