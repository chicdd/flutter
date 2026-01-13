import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/search_panel.dart';
import '../models/customer_detail.dart';
import '../services/api_service.dart';
import '../functions.dart';
import '../theme.dart';
import '../style.dart';
import '../widgets/common_table.dart';
import '../widgets/component.dart';
import '../widgets/base_add_modal.dart';
import '../models/aslog.dart';
import 'base_table_screen.dart';

/// AS 접수 리스트 화면
class AsLogScreen extends BaseTableScreen<AsLog> {
  const AsLogScreen({super.key, super.searchpanel});

  @override
  State<AsLogScreen> createState() => AsLogState();
}

class AsLogState extends BaseTableScreenState<AsLog, AsLogScreen> {
  @override
  String get tableTitle => 'AS 접수 리스트';

  @override
  bool get showAddButton => true;

  @override
  Map<int, double> get initialColumnWidths => {
        0: 300.0, // 관제상호
        1: 120.0, // 고객연락처
        2: 300.0, // 고객이름
        3: 100.0, // 요청일자
        4: 100.0, // 요청시간
        5: 200.0, // 요청제목
        6: 100.0, // 접수일자
        7: 100.0, // 접수시간
        8: 120.0, // 담당자코드명
        9: 80.0, // 처리여부
        10: 100.0, // 접수자
        11: 250.0, // 세부내용
      };

  @override
  Future<List<AsLog>> loadDataFromApi(String key) async {
    return await DatabaseService.getASLog(key);
  }

  @override
  List<TableColumnConfig> buildColumns() {
    return [
      TableColumnConfig(
        header: '관제상호',
        width: columnWidths[0],
        valueBuilder: (data) => data.controlBusinessName ?? '',
      ),
      TableColumnConfig(
        header: '고객이름',
        width: columnWidths[2],
        valueBuilder: (data) => data.controlBusinessName ?? '',
      ),
      TableColumnConfig(
        header: '고객연락처',
        width: columnWidths[1],
        valueBuilder: (data) => data.customerHP ?? '',
      ),
      TableColumnConfig(
        header: '요청일자',
        width: columnWidths[3],
        valueBuilder: (data) => dateParsing(data.requireDate) ?? '',
      ),
      TableColumnConfig(
        header: '요청시간',
        width: columnWidths[4],
        valueBuilder: (data) => data.requireTime ?? '',
      ),
      TableColumnConfig(
        header: '요청제목',
        width: columnWidths[5],
        valueBuilder: (data) => data.requireSubject ?? '',
      ),
      TableColumnConfig(
        header: '접수일자',
        width: columnWidths[6],
        valueBuilder: (data) => dateParsing(data.receiptDate) ?? '',
      ),
      TableColumnConfig(
        header: '접수시간',
        width: columnWidths[7],
        valueBuilder: (data) => data.receiptTime ?? '',
      ),
      TableColumnConfig(
        header: '세부내용',
        width: columnWidths[11],
        valueBuilder: (data) => data.processingetc ?? '',
      ),
      TableColumnConfig(
        header: '담당자코드명',
        width: columnWidths[8],
        valueBuilder: (data) => data.contactCodeName ?? '',
      ),
      TableColumnConfig(
        header: '처리여부',
        width: columnWidths[9],
        valueBuilder: (data) => data.isProcessed ?? '',
      ),
      TableColumnConfig(
        header: '접수자',
        width: columnWidths[10],
        valueBuilder: (data) => data.receptionist ?? '',
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
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _requestDateController = TextEditingController();
  final TextEditingController _requestHourController = TextEditingController();
  final TextEditingController _requestMinuteController =
      TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _detailController = TextEditingController();

  String? _selectedManager;
  List<CodeData> _managerList = [];
  bool _isLoadingManager = false;

  @override
  String get modalTitle => 'A/S 접수 등록';

  @override
  String get saveButtonLabel => 'A/S 접수 등록';

  @override
  void initState() {
    super.initState();
    _loadManagerList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _requestDateController.dispose();
    _requestHourController.dispose();
    _requestMinuteController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  /// 담당자 목록 로드
  Future<void> _loadManagerList() async {
    setState(() {
      _isLoadingManager = true;
    });

    try {
      final data = await CodeDataCache.getCodeData('managercode');
      if (mounted) {
        setState(() {
          _managerList = data;
          _isLoadingManager = false;
        });
      }
    } catch (e) {
      print('담당자 목록 로드 오류: $e');
      if (mounted) {
        setState(() {
          _isLoadingManager = false;
        });
      }
    }
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
        _requestDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  /// 시간 선택기 표시
  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _requestHourController.text = picked.hour.toString().padLeft(2, '0');
        _requestMinuteController.text = picked.minute.toString().padLeft(
          2,
          '0',
        );
      });
    }
  }

  @override
  Future<bool> validateAndSave() async {
    // 검증
    if (_titleController.text.isEmpty) {
      showErrorSnackBar('AS접수제목을 입력해주세요.');
      return false;
    }

    if (_requestDateController.text.isEmpty) {
      showErrorSnackBar('방문요청일자를 입력해주세요.');
      return false;
    }

    // 데이터 구성
    final data = {
      '관제관리번호': widget.controlManagementNumber,
      '고객이름': _customerNameController.text,
      '고객연락처': _customerPhoneController.text,
      '요청일자': _requestDateController.text,
      '요청시간':
          '${_requestHourController.text}:${_requestMinuteController.text}',
      '요청제목': _titleController.text,
      '담당구역': _selectedManager ?? '',
      '입력자': 'ADMIN', // 실제로는 현재 로그인한 사용자 ID를 사용
      '세부내용': _detailController.text,
    };

    // API 호출
    return await DatabaseService.addASLog(data);
  }

  @override
  Widget buildFormFields() {
    return Column(
      children: [
        CommonTextField(label: 'AS접수제목', controller: _titleController),
        const SizedBox(height: 16),
        Row(
          children: [
            DateTextField(
              label: '방문요청일자',
              controller: _requestDateController,
              onCalendarPressed: _selectDate,
            ),
            const SizedBox(width: 24),
            TimePickerField(
              label: '방문요청시간',
              hourController: _requestHourController,
              minuteController: _requestMinuteController,
              onTimePickerPressed: _selectTime,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingManager)
          const CircularProgressIndicator()
        else
          CommonDropdownField(
            label: '담당자',
            value: _selectedManager,
            items: _managerList,
            onChanged: (value) {
              setState(() {
                _selectedManager = value;
              });
            },
          ),
        const SizedBox(height: 16),
        CommonTextField(
          label: '접수고객명',
          controller: _customerNameController,
        ),
        const SizedBox(height: 16),
        CommonTextField(
          label: '고객연락처',
          controller: _customerPhoneController,
        ),
        const SizedBox(height: 16),
        CommonTextField(
          label: '세부기록사항',
          controller: _detailController,
          maxLines: 3,
        ),
      ],
    );
  }
}
