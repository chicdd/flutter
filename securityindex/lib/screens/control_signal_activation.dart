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
        header: '개시',
        width: _columnWidths[0],
        valueBuilder: (data) => data['개시']?.toString() ?? '',
      ),
      TableColumnConfig(
        header: 'ZONECK',
        width: _columnWidths[1],
        cellBuilder: (data, value) =>
            _buildCheckboxCell(data['ZONECK'] == true, _columnWidths[1]!),
      ),
      TableColumnConfig(
        header: 'KEYCK',
        width: _columnWidths[2],
        cellBuilder: (data, value) =>
            _buildCheckboxCell(data['KEYCK'] == true, _columnWidths[2]!),
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
            _buildCheckboxCell(data['도면'] == true, _columnWidths[4]!),
      ),
      TableColumnConfig(
        header: '고객카드',
        width: _columnWidths[5],
        cellBuilder: (data, value) =>
            _buildCheckboxCell(data['customerCard'] == true, _columnWidths[5]!),
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
      final data = await DatabaseService.getControlSignalActivations(
        managementNumber,
      );

      if (mounted) {
        setState(() {
          _dataList = data;
          _isLoading = false;
        });
      }

      print('관제개시 데이터 로드 완료: ${data.length}건');
    } catch (e) {
      print('관제개시 데이터 로드 오류: $e');
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
                '관제신호 개통처리',
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
