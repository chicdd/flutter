import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../functions.dart';
import '../style.dart';
import '../theme.dart';
import '../widgets/common_table.dart';
import '../widgets/component.dart';
import '../widgets/base_add_modal.dart';
import 'base_table_screen.dart';

/// 보수점검 완료이력 화면
class MaintenanceInspectionHistory
    extends BaseTableScreen<Map<String, dynamic>> {
  const MaintenanceInspectionHistory({super.key, super.searchpanel});

  @override
  State<MaintenanceInspectionHistory> createState() =>
      MaintenanceInspectionHistoryState();
}

class MaintenanceInspectionHistoryState
    extends
        BaseTableScreenState<
          Map<String, dynamic>,
          MaintenanceInspectionHistory
        > {
  @override
  String get tableTitle => '보수점검 완료이력';

  @override
  bool get showAddButton => true;

  @override
  Map<int, double> get initialColumnWidths => {
    0: 120.0, // 지시자
    1: 150.0, // 점검기준월
    2: 80.0, // 존점검
    3: 80.0, // 키테스트
    4: 80.0, // 키예탁
    5: 80.0, // 키수량
    6: 80.0, // 도면점검
    7: 100.0, // 고객카드
    8: 120.0, // 점검완료자
    9: 250.0, // 고객요청사항
  };

  @override
  Future<List<Map<String, dynamic>>> loadDataFromApi(String key) async {
    return await DatabaseService.getMaintenanceInspectionHistory(key);
  }

  @override
  List<TableColumnConfig> buildColumns() {
    return [
      TableColumnConfig(
        header: '지시자',
        width: columnWidths[0],
        valueBuilder: (data) => data['지시자']?.toString() ?? '',
      ),
      TableColumnConfig(
        header: '점검기준월',
        width: columnWidths[1],
        valueBuilder: (data) => data['점검기준월']?.toString() ?? '',
      ),
      TableColumnConfig(
        header: '존점검',
        width: columnWidths[2],
        cellBuilder: (data, value) =>
            buildCheckboxCell(data['존점검'] == true, columnWidths[2]!),
      ),
      TableColumnConfig(
        header: '키테스트',
        width: columnWidths[3],
        cellBuilder: (data, value) =>
            buildCheckboxCell(data['키테스트'] == true, columnWidths[3]!),
      ),
      TableColumnConfig(
        header: '키예탁',
        width: columnWidths[4],
        cellBuilder: (data, value) =>
            buildCheckboxCell(data['키예탁'] == true, columnWidths[4]!),
      ),
      TableColumnConfig(
        header: '키수량',
        width: columnWidths[5],
        valueBuilder: (data) => data['키수량']?.toString() ?? '0',
      ),
      TableColumnConfig(
        header: '도면점검',
        width: columnWidths[6],
        cellBuilder: (data, value) =>
            buildCheckboxCell(data['도면점검'] == true, columnWidths[6]!),
      ),
      TableColumnConfig(
        header: '고객카드',
        width: columnWidths[7],
        cellBuilder: (data, value) =>
            buildCheckboxCell(data['고객카드'] == true, columnWidths[7]!),
      ),
      TableColumnConfig(
        header: '점검완료자',
        width: columnWidths[8],
        valueBuilder: (data) => data['점검완료자']?.toString() ?? '',
      ),
      TableColumnConfig(
        header: '고객요청사항',
        width: columnWidths[9],
        valueBuilder: (data) => data['고객요청사항']?.toString() ?? '',
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
  final TextEditingController _inspectionMonthController =
      TextEditingController();
  final TextEditingController _processDateController = TextEditingController();
  final TextEditingController _inspectorController = TextEditingController();
  final TextEditingController _customerRequestController =
      TextEditingController();
  final TextEditingController _keyQuantityController = TextEditingController(
    text: '0',
  );

  bool _zoneCheck = false;
  bool _mapCheck = false;
  bool _customerCard = false;
  bool _depositKeyTest = false;

  @override
  String get modalTitle => '보수점검 정보 추가';

  @override
  String get saveButtonLabel => '보수 점검 입력';

  @override
  void dispose() {
    _inspectionMonthController.dispose();
    _processDateController.dispose();
    _inspectorController.dispose();
    _customerRequestController.dispose();
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
        if (isStartDate) {
          _inspectionMonthController.text = DateFormat(
            'yyyy-MM-dd',
          ).format(picked);
        } else {
          _processDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
    }
  }

  @override
  Future<bool> validateAndSave() async {
    // 검증
    if (_inspectionMonthController.text.isEmpty) {
      showErrorSnackBar('점검기준월을 입력해주세요.');
      return false;
    }

    if (_processDateController.text.isEmpty) {
      showErrorSnackBar('처리일자를 입력해주세요.');
      return false;
    }

    // 데이터 구성
    final data = {
      '관제관리번호': widget.controlManagementNumber,
      '발생자': '', // 발생자는 빈 값으로 전달
      '점검기준월': _inspectionMonthController.text,
      '처리일자': _processDateController.text,
      '존점검': _zoneCheck,
      '키테스트': _depositKeyTest,
      '키예탁': _depositKeyTest, // 예탁키테스트를 키예탁으로 매핑
      '키수량': int.tryParse(_keyQuantityController.text) ?? 0,
      '도면점검': _mapCheck,
      '고객카드': _customerCard,
      '처리자': _inspectorController.text,
      '고객요청사항': _customerRequestController.text,
    };

    // API 호출
    return await DatabaseService.addMaintenanceInspection(data);
  }

  @override
  Widget buildFormFields() {
    return Column(
      children: [
        Row(
          children: [
            DateTextField(
              label: '점검기준월',
              controller: _inspectionMonthController,
              onCalendarPressed: _selectDate,
            ),
            const SizedBox(width: 24),
            DateTextField(
              label: '처리일자',
              controller: _processDateController,
              onCalendarPressed: _selectDate,
            ),
          ],
        ),
        const SizedBox(height: 16),
        CommonTextField(label: '점검완료자', controller: _inspectorController),
        const SizedBox(height: 16),
        CommonTextField(
          label: '고객요청사항',
          controller: _customerRequestController,
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            buildCheckbox('존점검결과', _zoneCheck, (value) {
              setState(() {
                _zoneCheck = value ?? false;
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
          child: SizedBox(
            width: 100,
            child: CommonTextField(
              label: '키예탁수량',
              controller: _keyQuantityController,
              keyboardType: TextInputType.number,
            ),
          ),
        ),
      ],
    );
  }
}
