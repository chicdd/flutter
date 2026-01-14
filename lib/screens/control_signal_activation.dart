import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import '../models/search_panel.dart';
import '../services/api_service.dart';
import '../functions.dart';
import '../theme.dart';
import '../style.dart';
import '../widgets/common_table.dart';
import '../widgets/component.dart';

/// 관제신호 개통처리 화면
class ControlSignalActivation extends StatefulWidget {
  final SearchPanel? searchpanel;
  const ControlSignalActivation({super.key, this.searchpanel});

  @override
  State<ControlSignalActivation> createState() =>
      ControlSignalActivationState();
}

class ControlSignalActivationState extends State<ControlSignalActivation>
    with CustomerServiceHandler, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // 데이터 목록
  List<Map<String, dynamic>> _dataList = [];

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

  // 테이블 컬럼 설정
  late final List<TableColumnConfig> _columns = [
    TableColumnConfig(
      header: '개시',
      width: _columnWidths[0],
      valueBuilder: (data) => data['개시']?.toString() ?? '',
    ),
    TableColumnConfig(
      header: 'ZONECK',
      width: _columnWidths[1],
      cellBuilder: (data, value) =>
          buildCheckboxCell(data['ZONECK'] == true, _columnWidths[1]!),
    ),
    TableColumnConfig(
      header: 'KEYCK',
      width: _columnWidths[2],
      cellBuilder: (data, value) =>
          buildCheckboxCell(data['KEYCK'] == true, _columnWidths[2]!),
    ),
    TableColumnConfig(
      header: 'KEYS',
      width: _columnWidths[3],
      valueBuilder: (data) => data['KEYS']?.toString() ?? '0',
    ),
    TableColumnConfig(
      header: '도면',
      width: _columnWidths[4],
      cellBuilder: (data, value) =>
          buildCheckboxCell(data['도면'] == true, _columnWidths[4]!),
    ),
    TableColumnConfig(
      header: '고객카드',
      width: _columnWidths[5],
      cellBuilder: (data, value) =>
          buildCheckboxCell(data['customerCard'] == true, _columnWidths[5]!),
    ),
    TableColumnConfig(
      header: '개시처리자',
      width: _columnWidths[6],
      valueBuilder: (data) => data['개시처리자']?.toString() ?? '',
    ),
    TableColumnConfig(
      header: '관제확인자',
      width: _columnWidths[7],
      valueBuilder: (data) => data['관제확인자']?.toString() ?? '',
    ),
    TableColumnConfig(
      header: '설치공사자',
      width: _columnWidths[8],
      valueBuilder: (data) => data['설치공사자']?.toString() ?? '',
    ),
    TableColumnConfig(
      header: '키인수자',
      width: _columnWidths[9],
      valueBuilder: (data) => data['키인수자']?.toString() ?? '',
    ),
    TableColumnConfig(
      header: '비고',
      width: _columnWidths[10],
      valueBuilder: (data) => data['비고']?.toString() ?? '',
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
    final customer = customerService.selectedCustomer;

    if (customer != null) {
      await _loadData(customer.controlManagementNumber);
    } else {
      setState(() {
        _dataList = [];
      });
    }
  }

  /// CustomerServiceHandler 콜백 구현
  @override
  void onCustomerChanged(SearchPanel? customer, detail) {
    if (customer != null) {
      _loadData(customer.controlManagementNumber);
    } else {
      setState(() {
        _dataList = [];
      });
    }
  }

  /// 데이터 로드
  Future<void> _loadData(String managementNumber) async {
    setState(() {
      _dataList.clear();
    });

    try {
      final data = await DatabaseService.getControlSignalActivations(
        managementNumber,
      );

      if (mounted) {
        setState(() {
          _dataList = data;
        });
      }

      print('관제개시 데이터 로드 완료: ${data.length}건');
    } catch (e) {
      print('관제개시 데이터 로드 오류: $e');
      if (mounted) {
        setState(() {
          _dataList = [];
        });
      }
    }
  }

  /// 추가 모달 표시
  void _showAddModal() {
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
          _loadData(customer.controlManagementNumber);
        },
      ),
    );
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
                title: '관제신호 개통처리',
                dataList: _dataList,
                columns: _columns,
                columnWidths: _columnWidths,
                onColumnResize: (columnIndex, newWidth) {
                  setState(() {
                    _columnWidths[columnIndex] = newWidth;
                  });
                },
                showTotalCount: true,
                searchQuery: _pageSearchQuery,
                onAdd: _showAddModal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 추가 모달
class _AddModal extends StatefulWidget {
  final String controlManagementNumber;
  final VoidCallback onSaved;

  const _AddModal({
    required this.controlManagementNumber,
    required this.onSaved,
  });

  @override
  State<_AddModal> createState() => _AddModalState();
}

class _AddModalState extends State<_AddModal> {
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

  bool _isSaving = false;

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

  /// 저장
  Future<void> _save() async {
    if (_openDateController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('경비개시일자를 입력해주세요.')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
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

      final success = await DatabaseService.addControlSignalActivation(data);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('저장되었습니다.')));
          Navigator.of(context).pop();
          widget.onSaved();
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('저장에 실패했습니다.')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.white,
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              const Text(
                '경비개시 정보 추가',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // 입력 필드
              DateTextField(
                label: '경비개시일자',
                controller: _openDateController,
                onCalendarPressed: _selectDate,
              ),
              const SizedBox(height: 16),

              CommonTextField(
                label: '개시처리자',
                controller: _openProcessorController,
              ),
              const SizedBox(height: 16),

              CommonTextField(
                label: '관제확인자',
                controller: _securityConfirmerController,
              ),
              const SizedBox(height: 16),

              CommonTextField(label: '설치공사자', controller: _installerController),
              const SizedBox(height: 16),

              CommonTextField(
                label: '키인수자',
                controller: _keyReceiverController,
              ),
              const SizedBox(height: 16),

              CommonTextField(
                label: '비고',
                controller: _remarksController,
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // 체크박스
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

              // 키예탁수량
              SizedBox(
                width: 200,
                child: CommonTextField(
                  label: '키예탁수량',
                  controller: _keyQuantityController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(height: 24),

              // 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () {
                            Navigator.of(context).pop();
                          },
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.selectedColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('경비개시'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
