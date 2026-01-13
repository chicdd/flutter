import 'package:flutter/material.dart';
import '../models/search_panel.dart';
import '../models/customer_detail.dart';
import '../models/visit_as_history.dart';
import '../services/api_service.dart';
import '../functions.dart';
import '../widgets/common_table.dart';
import 'base_table_screen.dart';

/// 최근 방문 및 A/S 이력 테이블 화면
class VisitAsHistoryTable extends BaseTableScreen<VisitAsHistory> {
  const VisitAsHistoryTable({super.key, super.searchpanel});

  @override
  State<VisitAsHistoryTable> createState() => VisitAsHistoryTableState();
}

class VisitAsHistoryTableState
    extends BaseTableScreenState<VisitAsHistory, VisitAsHistoryTable> {
  @override
  String get tableTitle => '최근 방문 및 A/S 이력';

  @override
  Map<int, double> get initialColumnWidths => {
        0: 150.0, // 요청일자
        1: 100.0, // 권역명
        2: 200.0, // 요청제목
        3: 100.0, // 처리여부
        4: 150.0, // 처리일시
        5: 200.0, // 처리비고
        6: 100.0, // 접수자
        7: 100.0, // 처리자
        8: 120.0, // 개인AS처리자
      };

  @override
  String? getDataKeyFromCustomer(
    SearchPanel? customer,
    CustomerDetail? detail,
  ) {
    // 이 화면은 ERP 고객번호를 사용함
    return detail?.erpCusNumber;
  }

  @override
  Future<List<VisitAsHistory>> loadDataFromApi(String key) async {
    return await DatabaseService.getVisitAsHistory(key);
  }

  @override
  List<TableColumnConfig> buildColumns() {
    return [
      TableColumnConfig(
        header: '요청일자',
        width: columnWidths[0],
        valueBuilder: (data) => (data as VisitAsHistory).requestDate ?? '-',
      ),
      TableColumnConfig(
        header: '권역명',
        width: columnWidths[1],
        valueBuilder: (data) => (data as VisitAsHistory).areaName ?? '-',
      ),
      TableColumnConfig(
        header: '요청제목',
        width: columnWidths[2],
        valueBuilder: (data) => (data as VisitAsHistory).requestTitle ?? '-',
      ),
      TableColumnConfig(
        header: '처리여부',
        width: columnWidths[3],
        valueBuilder: (data) => (data as VisitAsHistory).processingStatusText,
      ),
      TableColumnConfig(
        header: '처리일시',
        width: columnWidths[4],
        valueBuilder: (data) =>
            (data as VisitAsHistory).processingDateTime ?? '-',
      ),
      TableColumnConfig(
        header: '처리비고',
        width: columnWidths[5],
        valueBuilder: (data) => (data as VisitAsHistory).processingNote ?? '-',
      ),
      TableColumnConfig(
        header: '접수자',
        width: columnWidths[6],
        valueBuilder: (data) => (data as VisitAsHistory).receptionist ?? '-',
      ),
      TableColumnConfig(
        header: '처리자',
        width: columnWidths[7],
        valueBuilder: (data) => (data as VisitAsHistory).processor ?? '-',
      ),
      TableColumnConfig(
        header: '개인AS처리자',
        width: columnWidths[8],
        valueBuilder: (data) =>
            (data as VisitAsHistory).personalAsProcessor ?? '-',
      ),
    ];
  }
}
