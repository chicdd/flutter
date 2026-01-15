import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'base_table_screen.dart';
import '../models/search_panel.dart';
import '../models/customer_detail.dart';
import '../services/api_service.dart';
import '../functions.dart';
import '../style.dart';
import '../widgets/common_table.dart';

import '../widgets/base_add_modal.dart';
import 'base_table_screen.dart';

/// 관제신호 개통처리 화면
class ControlSignalActivation extends BaseTableScreen<Map<String, dynamic>> {
  const ControlSignalActivation({super.key, super.searchpanel});

  @override
  State<ControlSignalActivation> createState() =>
      ControlSignalActivationState();
}

class ControlSignalActivationState
    extends
        BaseTableScreenState<Map<String, dynamic>, ControlSignalActivation> {
  @override
  String get tableTitle => '관제신호 개통처리';

  @override
  bool get showAddButton => true;

  @override
  Map<int, double> get initialColumnWidths => {
    0: 120.0, // 개시
    1: 80.0, // ZONECK
    2: 80.0, // KEYCK
    3: 80.0, // KEYS
    4: 80.0, // 도면
    5: 100.0, // 고객카드
    6: 120.0, // 개시처리자
    7: 120.0, // 관제확인자
    8: 120.0, // 설치공사자
    9: 120.0, // 키인수자
    10: 200.0, // 비고
  };

  @override
  Future<List<Map<String, dynamic>>> loadDataFromApi(String key) async {
    return await DatabaseService.getControlSignalActivations(key);
  }

  @override
  List<TableColumnConfig> buildColumns() {
    return [
      TableColumnConfig(
        header: '개시',
        width: columnWidths[0],
        valueBuilder: (data) => data['개시']?.toString() ?? '',
      ),
      TableColumnConfig(
        header: 'ZONECK',
        width: columnWidths[1],
        cellBuilder: (data, value) =>
            buildCheckboxCell(data['ZONECK'] == true, columnWidths[1]!),
      ),
      TableColumnConfig(
        header: 'KEYCK',
        width: columnWidths[2],
        cellBuilder: (data, value) =>
            buildCheckboxCell(data['KEYCK'] == true, columnWidths[2]!),
      ),
      TableColumnConfig(
        header: 'KEYS',
        width: columnWidths[3],
        valueBuilder: (data) => data['KEYS']?.toString() ?? '0',
      ),
      TableColumnConfig(
        header: '도면',
        width: columnWidths[4],
        cellBuilder: (data, value) =>
            buildCheckboxCell(data['도면'] == true, columnWidths[4]!),
      ),
      TableColumnConfig(
        header: '고객카드',
        width: columnWidths[5],
        cellBuilder: (data, value) =>
            buildCheckboxCell(data['customerCard'] == true, columnWidths[5]!),
      ),
      TableColumnConfig(
        header: '개시처리자',
        width: columnWidths[6],
        valueBuilder: (data) => data['개시처리자']?.toString() ?? '',
      ),
      TableColumnConfig(
        header: '관제확인자',
        width: columnWidths[7],
        valueBuilder: (data) => data['관제확인자']?.toString() ?? '',
      ),
      TableColumnConfig(
        header: '설치공사자',
        width: columnWidths[8],
        valueBuilder: (data) => data['설치공사자']?.toString() ?? '',
      ),
      TableColumnConfig(
        header: '키인수자',
        width: columnWidths[9],
        valueBuilder: (data) => data['키인수자']?.toString() ?? '',
      ),
      TableColumnConfig(
        header: '비고',
        width: columnWidths[10],
        valueBuilder: (data) => data['비고']?.toString() ?? '',
      ),
    ];
  }

  @override
  void onAddButtonPressed() {
    final customer = customerService.selectedCustomer;
    if (customer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('고객을 먼저 선택해주세요.')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _AddModal(
        controlManagementNumber: customer.controlManagementNumber,
        onSaved: () {
          refreshData();
        },
      ),
    );
  }
}

/// 추가 모달
class _AddModal extends BaseAddModal {
  final String controlManagementNumber;

  const _AddModal({
    required this.controlManagementNumber,
    required super.onSaved,
  });

  @override
  State<_AddModal> createState() => _AddModalState();
}

class _AddModalState extends BaseAddModalState<_AddModal> {
  final TextEditingController _openDateController = TextEditingController();
  final TextEditingController _openProcessorController =
      TextEditingController();
  final TextEditingController _securityConfirmerController =
      TextEditingController();
  final TextEditingController _installerController = TextEditingController();
  final TextEditingController _keyReceiverController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _keyQuantityController = TextEditingController(
    text: '0',
  );

  bool _zoneCheckResult = false;
  bool _mapCheck = false;
  bool _customerCard = false;
  bool _depositKeyTest = false;

  @override
  String get modalTitle => '경비개시 정보 추가';

  @override
  String get saveButtonLabel => '경비개시';

  @override
  void dispose() {
    _openDateController.dispose();
    _openProcessorController.dispose();
    _securityConfirmerController.dispose();
    _installerController.dispose();
    _keyReceiverController.dispose();
    _remarksController.dispose();
    _keyQuantityController.dispose();
    super.dispose();
  }

  /// 날짜 선택기 표시
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePickerDialog(
      context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _openDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Future<bool> validateAndSave() async {
    // 검증
    if (_openDateController.text.isEmpty) {
      showErrorSnackBar('경비개시일자를 입력해주세요.');
      return false;
    }

    // 데이터 구성
    final data = {
      '관제관리번호': widget.controlManagementNumber,
      '경비개시일자': _openDateController.text,
      '존점검결과': _zoneCheckResult,
      '키테스트': _depositKeyTest,
      '키수량': int.tryParse(_keyQuantityController.text) ?? 0,
      '도면점검': _mapCheck,
      '고객카드': _customerCard,
      '점검자': _openProcessorController.text,
      '관제확인자': _securityConfirmerController.text,
      '설치공사자': _installerController.text,
      '키인수자': _keyReceiverController.text,
      '비고사항': _remarksController.text,
    };

    // API 호출
    return await DatabaseService.addControlSignalActivation(data);
  }

  @override
  Widget buildFormFields() {
    return Column(
      children: [
        DateTextField(
          label: '경비개시일자',
          controller: _openDateController,
          onCalendarPressed: _selectDate,
        ),
        const SizedBox(height: 16),
        CommonTextField(label: '개시처리자', controller: _openProcessorController),
        const SizedBox(height: 16),
        CommonTextField(
          label: '관제확인자',
          controller: _securityConfirmerController,
        ),
        const SizedBox(height: 16),
        CommonTextField(label: '설치공사자', controller: _installerController),
        const SizedBox(height: 16),
        CommonTextField(label: '키인수자', controller: _keyReceiverController),
        const SizedBox(height: 16),
        CommonTextField(
          label: '비고',
          controller: _remarksController,
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            buildCheckbox('존점검결과', _zoneCheckResult, (value) {
              setState(() {
                _zoneCheckResult = value ?? false;
              });
            }),
            buildCheckbox('도면점검', _mapCheck, (value) {
              setState(() {
                _mapCheck = value ?? false;
              });
            }),
            buildCheckbox('고객카드', _customerCard, (value) {
              setState(() {
                _customerCard = value ?? false;
              });
            }),
            buildCheckbox('예탁키테스트', _depositKeyTest, (value) {
              setState(() {
                _depositKeyTest = value ?? false;
              });
            }),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 200,
          child: CommonTextField(
            label: '키예탁수량',
            controller: _keyQuantityController,
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }
}
