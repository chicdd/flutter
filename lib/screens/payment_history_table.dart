import 'package:flutter/material.dart';
import '../models/search_panel.dart';
import '../models/customer_detail.dart';
import '../models/payment_history.dart';
import '../services/api_service.dart';
import '../functions.dart';
import '../style.dart';
import '../widgets/common_table.dart';
import 'base_table_screen.dart';

/// 최근 수금 이력 테이블 화면
class PaymentHistoryTable extends BaseTableScreen<PaymentHistory> {
  const PaymentHistoryTable({super.key, super.searchpanel});

  @override
  State<PaymentHistoryTable> createState() => PaymentHistoryTableState();
}

class PaymentHistoryTableState
    extends BaseTableScreenState<PaymentHistory, PaymentHistoryTable> {
  @override
  String get tableTitle => '최근 수금 이력';

  @override
  Map<int, double> get initialColumnWidths => {
    0: 150.0, // 매출년월
    1: 120.0, // 청구금액
    2: 120.0, // 실입금액
    3: 120.0, // 입금방법
    4: 150.0, // 입금일자
    5: 100.0, // 수금상태
    6: 100.0, // 처리자
    7: 200.0, // 비고
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
  Future<List<PaymentHistory>> loadDataFromApi(String key) async {
    return await DatabaseService.getPaymentHistory(key);
  }

  @override
  List<TableColumnConfig> buildColumns() {
    return [
      TableColumnConfig(
        header: '매출년월',
        width: columnWidths[0],
        valueBuilder: (data) => (data as PaymentHistory).meachulformatted ?? '',
      ),
      TableColumnConfig(
        header: '청구금액',
        width: columnWidths[1],
        valueBuilder: (data) => (data as PaymentHistory).billingAmount ?? '-',
      ),
      TableColumnConfig(
        header: '실입금액',
        width: columnWidths[2],
        valueBuilder: (data) =>
            (data as PaymentHistory).actualPaymentAmount ?? '-',
      ),
      TableColumnConfig(
        header: '입금방법',
        width: columnWidths[3],
        valueBuilder: (data) => (data as PaymentHistory).paymentMethod ?? '-',
      ),
      TableColumnConfig(
        header: '입금일자',
        width: columnWidths[4],
        valueBuilder: (data) =>
            dateParsing((data as PaymentHistory).paymentDate) ?? '-',
      ),
      TableColumnConfig(
        header: '수금상태',
        width: columnWidths[5],
        valueBuilder: (data) => (data as PaymentHistory).collectionStatusText,
      ),
      TableColumnConfig(
        header: '처리자',
        width: columnWidths[6],
        valueBuilder: (data) => (data as PaymentHistory).processor ?? '-',
      ),
      TableColumnConfig(
        header: '비고',
        width: columnWidths[7],
        valueBuilder: (data) => (data as PaymentHistory).note ?? '-',
      ),
    ];
  }
}
