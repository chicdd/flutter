import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/search_panel.dart';
import '../services/api_service.dart';
import '../functions.dart';
import '../theme.dart';
import '../style.dart';
import '../widgets/common_table.dart';
import '../widgets/component.dart';

/// 보수점검 완료이력 화면
class MaintenanceInspectionHistory extends StatefulWidget {
  final SearchPanel? searchpanel;
  const MaintenanceInspectionHistory({super.key, this.searchpanel});

  @override
  State<MaintenanceInspectionHistory> createState() =>
      MaintenanceInspectionHistoryState();
}

class MaintenanceInspectionHistoryState
    extends State<MaintenanceInspectionHistory>
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

  // 테이블 컬럼 설정
  late final List<TableColumnConfig> _columns = [
    TableColumnConfig(
      header: '지시자',
      width: _columnWidths[0],
      valueBuilder: (data) => data['지시자']?.toString() ?? '',
    ),
    TableColumnConfig(
      header: '점검기준월',
      width: _columnWidths[1],
      valueBuilder: (data) => data['점검기준월']?.toString() ?? '',
    ),
    TableColumnConfig(
      header: '존점검',
      width: _columnWidths[2],
      cellBuilder: (data, value) =>
          buildCheckboxCell(data['존점검'] == true, _columnWidths[2]!),
    ),
    TableColumnConfig(
      header: '키테스트',
      width: _columnWidths[3],
      cellBuilder: (data, value) =>
          buildCheckboxCell(data['키테스트'] == true, _columnWidths[3]!),
    ),
    TableColumnConfig(
      header: '키예탁',
      width: _columnWidths[4],
      cellBuilder: (data, value) =>
          buildCheckboxCell(data['키예탁'] == true, _columnWidths[4]!),
    ),
    TableColumnConfig(
      header: '키수량',
      width: _columnWidths[5],
      valueBuilder: (data) => data['키수량']?.toString() ?? '0',
    ),
    TableColumnConfig(
      header: '도면점검',
      width: _columnWidths[6],
      cellBuilder: (data, value) =>
          buildCheckboxCell(data['도면점검'] == true, _columnWidths[6]!),
    ),
    TableColumnConfig(
      header: '고객카드',
      width: _columnWidths[7],
      cellBuilder: (data, value) =>
          buildCheckboxCell(data['고객카드'] == true, _columnWidths[7]!),
    ),
    TableColumnConfig(
      header: '점검완료자',
      width: _columnWidths[8],
      valueBuilder: (data) => data['점검완료자']?.toString() ?? '',
    ),
    TableColumnConfig(
      header: '고객요청사항',
      width: _columnWidths[9],
      valueBuilder: (data) => data['고객요청사항']?.toString() ?? '',
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
      final data = await DatabaseService.getMaintenanceInspectionHistory(
        managementNumber,
      );

      if (mounted) {
        setState(() {
          _dataList = data;
        });
      }

      print('보수점검 완료이력 데이터 로드 완료: ${data.length}건');
    } catch (e) {
      print('보수점검 완료이력 데이터 로드 오류: $e');
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
                title: '보수점검 완료이력',
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

  bool _isSaving = false;

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

  /// 저장
  Future<void> _save() async {
    if (_inspectionMonthController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('점검기준월을 입력해주세요.')));
      return;
    }

    if (_processDateController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('처리일자를 입력해주세요.')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
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

      final success = await DatabaseService.addMaintenanceInspection(data);

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
                '보수점검 정보 추가',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // 입력 필드
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

              // 체크박스
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

              // 키예탁수량
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
                        : const Text('보수 점검 입력'),
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
