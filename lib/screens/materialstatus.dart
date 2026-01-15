import 'package:flutter/material.dart';
import '../models/search_panel.dart';
import '../models/customer_detail.dart';
import '../widgets/common_table.dart';
import 'base_table_screen.dart';

/// 설치자재현황 화면
class MaterialStatus extends BaseTableScreen<Map<String, dynamic>> {
  const MaterialStatus({super.key, super.searchpanel});

  @override
  State<MaterialStatus> createState() => MaterialStatusState();
}

class MaterialStatusState
    extends BaseTableScreenState<Map<String, dynamic>, MaterialStatus> {
  @override
  String get tableTitle => '설치자재현황';

  @override
  Map<int, double> get initialColumnWidths => {
    0: 200.0, // 자재명칭
    1: 120.0, // 설치수량
    2: 120.0, // 자재코드
    3: 120.0, // 자재년식
    4: 200.0, // 대분류
    5: 200.0, // 중분류
  };

  @override
  Future<List<Map<String, dynamic>>> loadDataFromApi(String key) async {
    // TODO: API 연동 필요
    // return await DatabaseService.getMaterialStatus(key);
    return []; // 임시 빈 데이터
  }

  @override
  List<TableColumnConfig> buildColumns() {
    return [
      TableColumnConfig(
        header: '자재명칭',
        width: columnWidths[0],
        valueBuilder: (data) => data['자재명칭']?.toString() ?? '-',
      ),
      TableColumnConfig(
        header: '설치수량',
        width: columnWidths[1],
        valueBuilder: (data) => data['설치수량']?.toString() ?? '-',
      ),
      TableColumnConfig(
        header: '자재코드',
        width: columnWidths[2],
        valueBuilder: (data) => data['자재코드']?.toString() ?? '-',
      ),
      TableColumnConfig(
        header: '자재년식',
        width: columnWidths[3],
        valueBuilder: (data) => data['자재년식']?.toString() ?? '-',
      ),
      TableColumnConfig(
        header: '대분류',
        width: columnWidths[4],
        valueBuilder: (data) => data['대분류']?.toString() ?? '-',
      ),
      TableColumnConfig(
        header: '중분류',
        width: columnWidths[5],
        valueBuilder: (data) => data['중분류']?.toString() ?? '-',
      ),
    ];
  }
}
