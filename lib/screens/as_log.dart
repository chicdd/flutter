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
import '../models/aslog.dart';

/// AS 접수 리스트 화면
class AsLogScreen extends StatefulWidget {
  final SearchPanel? searchpanel;
  const AsLogScreen({super.key, this.searchpanel});

  @override
  State<AsLogScreen> createState() => AsLogState();
}

class AsLogState extends State<AsLogScreen>
    with CustomerServiceHandler, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // 데이터 목록
  List<AsLog> _dataList = [];
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
        header: '관제상호',
        width: _columnWidths[0],
        valueBuilder: (data) => data.controlBusinessName ?? '',
      ),
      TableColumnConfig(
        header: '고객이름',
        width: _columnWidths[2],
        valueBuilder: (data) => data.controlBusinessName ?? '',
      ),
      TableColumnConfig(
        header: '고객연락처',
        width: _columnWidths[1],
        valueBuilder: (data) => data.customerHP ?? '',
      ),
      TableColumnConfig(
        header: '요청일자',
        width: _columnWidths[3],
        valueBuilder: (data) => dateParsing(data.requireDate) ?? '',
      ),
      TableColumnConfig(
        header: '요청시간',
        width: _columnWidths[4],
        valueBuilder: (data) => data.requireTime ?? '',
      ),
      TableColumnConfig(
        header: '요청제목',
        width: _columnWidths[5],
        valueBuilder: (data) => data.requireSubject ?? '',
      ),
      TableColumnConfig(
        header: '접수일자',
        width: _columnWidths[6],
        valueBuilder: (data) => dateParsing(data.receiptDate) ?? '',
      ),
      TableColumnConfig(
        header: '접수시간',
        width: _columnWidths[7],
        valueBuilder: (data) => data.receiptTime ?? '',
      ),
      TableColumnConfig(
        header: '세부내용',
        width: _columnWidths[11],
        valueBuilder: (data) => data.processingetc ?? '',
      ),
      TableColumnConfig(
        header: '담당자코드명',
        width: _columnWidths[8],
        valueBuilder: (data) => data.contactCodeName ?? '',
      ),
      TableColumnConfig(
        header: '처리여부',
        width: _columnWidths[9],
        valueBuilder: (data) => data.isProcessed ?? '',
      ),
      TableColumnConfig(
        header: '접수자',
        width: _columnWidths[10],
        valueBuilder: (data) => data.receptionist ?? '',
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
      final data = await DatabaseService.getASLog(managementNumber);

      if (mounted) {
        setState(() {
          _dataList = data;
          _isLoading = false;
        });
      }

      print('AS접수 데이터 로드 완료: ${data.length}건');
    } catch (e) {
      print('AS접수 데이터 로드 오류: $e');
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
                'AS 접수 리스트',
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
  bool _isSaving = false;

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

  /// 저장
  Future<void> _save() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('AS접수제목을 입력해주세요.')));
      return;
    }

    if (_requestDateController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('방문요청일자를 입력해주세요.')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
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

      final success = await DatabaseService.addASLog(data);

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
                'A/S 접수 등록',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // 입력 필드
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

              // 담당자 드롭다운
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
                        : const Text('A/S 접수 등록'),
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
