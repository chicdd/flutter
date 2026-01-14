import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../models/search_panel.dart';
import '../models/payment_history.dart';
import '../services/api_service.dart';
import '../services/selected_customer_service.dart';
import '../functions.dart';
import '../theme.dart';
import '../style.dart';
import '../widgets/common_table.dart';
import '../widgets/component.dart';

/// 최근 수금 이력 테이블 화면
class PaymentHistoryTable extends StatefulWidget {
  final SearchPanel? searchpanel;
  const PaymentHistoryTable({super.key, this.searchpanel});

  @override
  State<PaymentHistoryTable> createState() => PaymentHistoryTableState();
}

class PaymentHistoryTableState extends State<PaymentHistoryTable>
    with CustomerServiceHandler, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // 데이터 목록
  List<PaymentHistory> _dataList = [];

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
    0: 150.0, // 매출년월
    1: 120.0, // 청구금액
    2: 120.0, // 실입금액
    3: 120.0, // 입금방법
    4: 150.0, // 입금일자
    5: 100.0, // 수금상태
    6: 100.0, // 처리자
    7: 200.0, // 비고
  };

  // 테이블 컬럼 설정
  late final List<TableColumnConfig> _columns = [
    TableColumnConfig(
      header: '매출년월',
      width: _columnWidths[0],
      valueBuilder: (data) => (data as PaymentHistory).meachulformatted ?? '',
    ),
    TableColumnConfig(
      header: '청구금액',
      width: _columnWidths[1],
      valueBuilder: (data) => (data as PaymentHistory).billingAmount ?? '-',
    ),
    TableColumnConfig(
      header: '실입금액',
      width: _columnWidths[2],
      valueBuilder: (data) =>
          (data as PaymentHistory).actualPaymentAmount ?? '-',
    ),
    TableColumnConfig(
      header: '입금방법',
      width: _columnWidths[3],
      valueBuilder: (data) => (data as PaymentHistory).paymentMethod ?? '-',
    ),
    TableColumnConfig(
      header: '입금일자',
      width: _columnWidths[4],
      valueBuilder: (data) =>
          dateParsing((data as PaymentHistory).paymentDate) ?? '-',
    ),
    TableColumnConfig(
      header: '수금상태',
      width: _columnWidths[5],
      valueBuilder: (data) => (data as PaymentHistory).collectionStatusText,
    ),
    TableColumnConfig(
      header: '처리자',
      width: _columnWidths[6],
      valueBuilder: (data) => (data as PaymentHistory).processor ?? '-',
    ),
    TableColumnConfig(
      header: '비고',
      width: _columnWidths[7],
      valueBuilder: (data) => (data as PaymentHistory).note ?? '-',
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
      final data = await DatabaseService.getPaymentHistory(customerNumber);

      if (mounted) {
        setState(() {
          _dataList = data;
        });
      }

      print('최근수금이력 데이터 로드 완료: ${data.length}건');
    } catch (e) {
      print('최근수금이력 데이터 로드 오류: $e');
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
                title: '최근 수금 이력',
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
