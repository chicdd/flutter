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
  bool _isLoading = false;

  // 스크롤 컨트롤러
  final ScrollController _scrollController = ScrollController();
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _bodyScrollController = ScrollController();

  // 스크롤 동기화 플래그
  bool _isSyncingScroll = false;

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
  late final List<TableColumnConfig> _columns;

  @override
  void initState() {
    super.initState();
    initCustomerServiceListener();
    _initializeData();

    // 가로 스크롤 동기화
    _headerScrollController.addListener(_syncHeaderScroll);
    _bodyScrollController.addListener(_syncBodyScroll);

    // 테이블 컬럼 설정 초기화
    _columns = [
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
            _buildCheckboxCell(data['존점검'] == true, _columnWidths[2]!),
      ),
      TableColumnConfig(
        header: '키테스트',
        width: _columnWidths[3],
        cellBuilder: (data, value) =>
            _buildCheckboxCell(data['키테스트'] == true, _columnWidths[3]!),
      ),
      TableColumnConfig(
        header: '키예탁',
        width: _columnWidths[4],
        cellBuilder: (data, value) =>
            _buildCheckboxCell(data['키예탁'] == true, _columnWidths[4]!),
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
            _buildCheckboxCell(data['도면점검'] == true, _columnWidths[6]!),
      ),
      TableColumnConfig(
        header: '고객카드',
        width: _columnWidths[7],
        cellBuilder: (data, value) =>
            _buildCheckboxCell(data['고객카드'] == true, _columnWidths[7]!),
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
  }

  @override
  void dispose() {
    disposeCustomerServiceListener();
    _scrollController.dispose();
    _headerScrollController.dispose();
    _bodyScrollController.dispose();
    super.dispose();
  }

  /// 헤더 스크롤 동기화
  void _syncHeaderScroll() {
    if (_isSyncingScroll) return;
    _isSyncingScroll = true;

    if (_bodyScrollController.hasClients &&
        _bodyScrollController.offset != _headerScrollController.offset) {
      _bodyScrollController.jumpTo(_headerScrollController.offset);
    }

    _isSyncingScroll = false;
  }

  /// 바디 스크롤 동기화
  void _syncBodyScroll() {
    if (_isSyncingScroll) return;
    _isSyncingScroll = true;

    if (_headerScrollController.hasClients &&
        _headerScrollController.offset != _bodyScrollController.offset) {
      _headerScrollController.jumpTo(_bodyScrollController.offset);
    }

    _isSyncingScroll = false;
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
      _isLoading = true;
      _dataList.clear();
    });

    try {
      final data = await DatabaseService.getMaintenanceInspectionHistory(
        managementNumber,
      );

      if (mounted) {
        setState(() {
          _dataList = data;
          _isLoading = false;
        });
      }

      print('보수점검 완료이력 데이터 로드 완료: ${data.length}건');
    } catch (e) {
      print('보수점검 완료이력 데이터 로드 오류: $e');
      if (mounted) {
        setState(() {
          _dataList = [];
          _isLoading = false;
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
            Expanded(child: _buildTable()),
          ],
        ),
      ),
    );
  }

  /// 테이블 영역 구성
  Widget _buildTable() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '보수점검 완료이력',
                style: TextStyle(
                  color: Color(0xFF252525),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4318FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '총 ${_dataList.length}건',
                  style: const TextStyle(
                    color: Color(0xFF4318FF),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _showAddModal,
                      label: const Text('추가'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.selectedColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _dataList.isEmpty && !_isLoading
                ? const Center(
                    child: Text(
                      '조회된 데이터가 없습니다.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildResizableTable(),
          ),
        ],
      ),
    );
  }

  /// 크기 조절 가능한 테이블 구성
  Widget _buildResizableTable() {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      child: Column(
        children: [
          // 헤더 (고정)
          SingleChildScrollView(
            controller: _headerScrollController,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: _buildTableHeader(),
          ),

          // 바디 (스크롤)
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                controller: _bodyScrollController,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: _buildTableBody(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 테이블 헤더 구성
  Widget _buildTableHeader() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: List.generate(_columns.length, (index) {
          final column = _columns[index];
          return Row(
            children: [
              Container(
                width: _columnWidths[index],
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                alignment: Alignment.center,
                child: Text(
                  column.header,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF252525),
                  ),
                ),
              ),
              if (index < _columns.length - 1) _buildResizeHandle(index),
            ],
          );
        }),
      ),
    );
  }

  /// 열 크기 조절 핸들
  Widget _buildResizeHandle(int columnIndex) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            final newWidth = (_columnWidths[columnIndex]! + details.delta.dx)
                .clamp(50.0, 500.0);
            _columnWidths[columnIndex] = newWidth;
          });
        },
        child: Container(
          width: 8,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: const Color(0xFFE0E0E0), width: 0.5),
              right: BorderSide(color: const Color(0xFFE0E0E0), width: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  /// 테이블 바디 구성
  Widget _buildTableBody() {
    return Column(
      children: List.generate(_dataList.length, (index) {
        final data = _dataList[index];
        final isEven = index % 2 == 0;

        return Container(
          decoration: BoxDecoration(
            color: isEven ? Colors.white : const Color(0xFFFAFAFA),
            border: const Border(
              left: BorderSide(color: Color(0xFFE0E0E0)),
              right: BorderSide(color: Color(0xFFE0E0E0)),
              bottom: BorderSide(color: Color(0xFFE0E0E0)),
            ),
          ),
          child: Row(
            children: _columns.asMap().entries.map((entry) {
              final columnIndex = entry.key;
              final column = entry.value;
              final value = column.valueBuilder?.call(data) ?? '';

              final cellWidget = column.cellBuilder != null
                  ? column.cellBuilder!(data, value)
                  : buildTableCell(
                      value: value,
                      columnWidths: _columnWidths,
                      columnIndex: columnIndex,
                      searchQuery: _pageSearchQuery,
                    );

              return Row(
                children: [
                  cellWidget,
                  if (columnIndex < _columns.length - 1) buildColumnDivider(),
                ],
              );
            }).toList(),
          ),
        );
      }),
    );
  }

  /// 체크박스 셀 생성
  Widget _buildCheckboxCell(bool isChecked, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      alignment: Alignment.center,
      child: Icon(
        isChecked ? Icons.check_box : Icons.check_box_outline_blank,
        size: 18,
        color: isChecked ? AppTheme.selectedColor : AppTheme.textSecondary,
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
