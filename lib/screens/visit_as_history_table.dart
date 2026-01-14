import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../functions.dart';
import '../models/search_panel.dart';
import '../models/visit_as_history.dart';
import '../services/api_service.dart';
import '../services/selected_customer_service.dart';
import '../theme.dart';
import '../style.dart';
import '../widgets/common_table.dart';
import '../widgets/component.dart';

/// 최근 방문 및 A/S 이력 테이블 화면
class VisitAsHistoryTable extends StatefulWidget {
  final SearchPanel? searchpanel;
  const VisitAsHistoryTable({super.key, this.searchpanel});

  @override
  State<VisitAsHistoryTable> createState() => VisitAsHistoryTableState();
}

class VisitAsHistoryTableState extends State<VisitAsHistoryTable>
    with CustomerServiceHandler, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // 데이터 목록
  List<VisitAsHistory> _dataList = [];

  // 페이지 내 검색
  String _pageSearchQuery = '';

  // 검색 쿼리 업데이트 메서드
  void updateSearchQuery(String query) {
    setState(() {
      _pageSearchQuery = query;
    });
  }

  // 테이블 열 너비
  final Map<int, double> _columnWidths = {
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

  // 테이블 컬럼 설정
  late final List<TableColumnConfig> _columns = [
    TableColumnConfig(
      header: '요청일자',
      width: _columnWidths[0],
      valueBuilder: (data) => (data as VisitAsHistory).requestDate ?? '-',
    ),
    TableColumnConfig(
      header: '권역명',
      width: _columnWidths[1],
      valueBuilder: (data) => (data as VisitAsHistory).areaName ?? '-',
    ),
    TableColumnConfig(
      header: '요청제목',
      width: _columnWidths[2],
      valueBuilder: (data) => (data as VisitAsHistory).requestTitle ?? '-',
    ),
    TableColumnConfig(
      header: '처리여부',
      width: _columnWidths[3],
      valueBuilder: (data) => (data as VisitAsHistory).processingStatusText,
    ),
    TableColumnConfig(
      header: '처리일시',
      width: _columnWidths[4],
      valueBuilder: (data) =>
          (data as VisitAsHistory).processingDateTime ?? '-',
    ),
    TableColumnConfig(
      header: '처리비고',
      width: _columnWidths[5],
      valueBuilder: (data) => (data as VisitAsHistory).processingNote ?? '-',
    ),
    TableColumnConfig(
      header: '접수자',
      width: _columnWidths[6],
      valueBuilder: (data) => (data as VisitAsHistory).receptionist ?? '-',
    ),
    TableColumnConfig(
      header: '처리자',
      width: _columnWidths[7],
      valueBuilder: (data) => (data as VisitAsHistory).processor ?? '-',
    ),
    TableColumnConfig(
      header: '개인AS처리자',
      width: _columnWidths[8],
      valueBuilder: (data) =>
          (data as VisitAsHistory).personalAsProcessor ?? '-',
    ),
  ];

  @override
  void initState() {
    super.initState();
    initCustomerServiceListener();
    _initializeData();
  }

  @override
  void dispose() {
    disposeCustomerServiceListener();
    super.dispose();
  }

  /// 초기 데이터 로드
  Future<void> _initializeData() async {
    await _loadCustomerDataFromService();
  }

  /// 전역 서비스에서 고객 데이터 로드
  Future<void> _loadCustomerDataFromService() async {
    final customerDetail = customerService.customerDetail;

    if (customerDetail != null && customerDetail.erpCusNumber != null) {
      await _loadData(customerDetail.erpCusNumber!);
    } else {
      setState(() {
        _dataList = [];
      });
    }
  }

  /// CustomerServiceHandler 콜백 구현
  @override
  void onCustomerChanged(SearchPanel? customer, detail) {
    if (detail != null && detail.erpCusNumber != null) {
      _loadData(detail.erpCusNumber!);
    } else {
      setState(() {
        _dataList = [];
      });
    }
  }

  /// 데이터 로드
  Future<void> _loadData(String customerNumber) async {
    setState(() {
      _dataList.clear();
    });

    try {
      final data = await DatabaseService.getVisitAsHistory(customerNumber);

      if (mounted) {
        setState(() {
          _dataList = data;
        });
      }

      print('최근 방문 및 A/S이력 데이터 로드 완료: ${data.length}건');
    } catch (e) {
      print('최근 방문 및 A/S이력 데이터 로드 오류: $e');
      if (mounted) {
        setState(() {
          _dataList = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 테이블 영역
            Expanded(
              child: buildTable(
                context: context,
                title: '최근 방문 및 A/S 이력',
                dataList: _dataList,
                columns: _columns,
                columnWidths: _columnWidths,
                onColumnResize: (columnIndex, newWidth) {
                  setState(() {
                    _columnWidths[columnIndex] = newWidth;
                  });
                },
                searchQuery: _pageSearchQuery,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
