import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/search_panel.dart';
import '../models/search_log.dart';
import '../services/api_service.dart';
import '../functions.dart';
import '../theme.dart';
import '../style.dart';
import '../widgets/common_table.dart';
import '../widgets/component.dart';
import 'package:flutter/gestures.dart';

import '../widgets/custom_top_bar.dart';

/// 검색로그 내역조회 화면
class SearchLogInquiry extends StatefulWidget {
  final SearchPanel? searchpanel;
  const SearchLogInquiry({super.key, this.searchpanel});

  @override
  State<SearchLogInquiry> createState() => SearchLogInquiryState();
}

class SearchLogInquiryState extends State<SearchLogInquiry>
    with CustomerServiceHandler, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // 검색 컨트롤러
  final TextEditingController _searchController = TextEditingController();
  // 날짜 입력 컨트롤러
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  // 페이지 내 검색
  String _pageSearchQuery = '';

  // 검색 쿼리 업데이트 메서드
  void updateSearchQuery(String query) {
    setState(() {
      _pageSearchQuery = query;
    });
  }

  // 검색로그 데이터 목록 (임시 데이터)
  List<SearchLogData> _logList = [];
  int _totalCount = 0;

  // 필터 설정
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 365));
  DateTime _endDate = DateTime.now();

  // 로딩 상태
  bool _isLoading = false;

  // 스크롤 컨트롤러
  final ScrollController _scrollController = ScrollController();
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _bodyScrollController = ScrollController();

  // 스크롤 동기화 플래그
  bool _isSyncingScroll = false;

  // 테이블 열 너비 (드래그로 조절 가능)
  final Map<int, double> _columnWidths = {
    0: 150.0, // 성명
    1: 150.0, // 기록일자
    2: 120.0, // 기록시간
    3: 500.0, // 입력내용
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

    // 날짜 컨트롤러 초기화
    _startDateController.text = DateFormat('yyyy-MM-dd').format(_startDate);
    _endDateController.text = DateFormat('yyyy-MM-dd').format(_endDate);

    // 테이블 컬럼 설정 초기화
    _columns = [
      TableColumnConfig(
        header: '성명',
        width: _columnWidths[0],
        valueBuilder: (data) => data.name,
      ),
      TableColumnConfig(
        header: '기록일자',
        width: _columnWidths[1],
        valueBuilder: (data) => data.recordDateFormatted,
      ),
      TableColumnConfig(
        header: '기록시간',
        width: _columnWidths[2],
        valueBuilder: (data) => data.recordTime,
      ),
      TableColumnConfig(
        header: '입력내용',
        width: _columnWidths[3],
        valueBuilder: (data) => data.inputContent,
      ),
    ];
  }

  @override
  void dispose() {
    disposeCustomerServiceListener();
    _scrollController.dispose();
    _headerScrollController.dispose();
    _bodyScrollController.dispose();
    _searchController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
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
      await _loadSearchLogData(customer.controlManagementNumber);
    } else {
      setState(() {
        _logList = [];
      });
    }
  }

  /// CustomerServiceHandler 콜백 구현
  @override
  void onCustomerChanged(SearchPanel? customer, detail) {
    if (customer != null) {
      _loadSearchLogData(customer.controlManagementNumber);
    } else {
      setState(() {
        _logList = [];
      });
    }
  }

  /// 검색로그 데이터 로드
  Future<void> _loadSearchLogData(String managementNumber) async {
    setState(() {
      _isLoading = true;
      _logList.clear();
    });

    try {
      final result = await DatabaseService.getSearchLogs(
        managementNumber: managementNumber,
        startDate: _startDate,
        endDate: _endDate,
        skip: 0,
        take: 100,
      );

      final logs = result['data'] as List<SearchLogData>;
      final totalCount = result['totalCount'] as int;

      if (mounted) {
        setState(() {
          _logList = logs;
          _totalCount = totalCount;
          _isLoading = false;
        });
      }

      print('검색로그 데이터 로드 완료: ${logs.length}건 / 전체: ${totalCount}건');
    } catch (e) {
      print('검색로그 데이터 로드 오류: $e');
      if (mounted) {
        setState(() {
          _logList = [];
          _totalCount = 0;
          _isLoading = false;
        });
      }
    }
  }

  /// 검색로그 새로고침 버튼 클릭
  Future<void> _refreshLogData() async {
    // 조회 버튼을 눌렀을 때 날짜 값을 확정
    _parseStartDate(_startDateController.text);
    _parseEndDate(_endDateController.text);

    final customer = customerService.selectedCustomer;
    if (customer != null) {
      await _loadSearchLogData(customer.controlManagementNumber);
    }
  }

  /// 날짜 선택 다이얼로그
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePickerDialog(
      context,
      initialDate: isStartDate ? _startDate : _endDate,
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _startDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        } else {
          _endDate = picked;
          _endDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
      // 날짜 변경 시 데이터 다시 로드
      final customer = customerService.selectedCustomer;
      if (customer != null) {
        await _loadSearchLogData(customer.controlManagementNumber);
      }
    }
  }

  /// 시작 날짜 텍스트 파싱 (다양한 포맷 지원)
  void _parseStartDate(String value) {
    final date = validateAndParseDateText(value);
    if (date != null) {
      setState(() {
        _startDate = date;
        _startDateController.text = DateFormat('yyyy-MM-dd').format(date);
      });
    } else {
      _startDateController.text = DateFormat('yyyy-MM-dd').format(_startDate);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('날짜 형식이 올바르지 않습니다.')));
    }
  }

  /// 종료 날짜 텍스트 파싱 (다양한 포맷 지원)
  void _parseEndDate(String value) {
    final date = validateAndParseDateText(value);
    if (date != null) {
      setState(() {
        _endDate = date;
        _endDateController.text = DateFormat('yyyy-MM-dd').format(date);
      });
    } else {
      _endDateController.text = DateFormat('yyyy-MM-dd').format(_endDate);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('날짜 형식이 올바르지 않습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 필수
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // 콘텐츠 영역
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // 필터 영역
                  _buildFilterSection(),
                  const SizedBox(height: 24),

                  // 테이블 영역
                  Expanded(child: _buildLogTable()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 필터 영역 구성
  Widget _buildFilterSection() {
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
          const Text(
            '검색 필터',
            style: TextStyle(
              color: Color(0xFF252525),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // 시작 날짜
              DateTextField(
                label: '검색 시작일자',
                controller: _startDateController,
                onCalendarPressed: _selectDate,
                onSubmitted: () => _parseStartDate(_startDateController.text),
              ),
              const SizedBox(width: 16),

              // 종료 날짜
              DateTextField(
                label: '검색 종료일자',
                controller: _endDateController,
                onCalendarPressed: _selectDate,
                onSubmitted: () => _parseEndDate(_endDateController.text),
              ),
              const SizedBox(width: 16),

              // 조회 버튼
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _refreshLogData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '조회',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 테이블 영역 구성
  Widget _buildLogTable() {
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
                '검색로그 내역조회',
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
                  '총 $_totalCount건',
                  style: const TextStyle(
                    color: Color(0xFF4318FF),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _logList.isEmpty && !_isLoading
                ? const Center(
                    child: Text(
                      '조회된 검색로그가 없습니다.',
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
      height: 45, // 헤더 고정 높이
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: _columns.asMap().entries.map((entry) {
          final columnIndex = entry.key;
          final column = entry.value;

          return Row(
            children: [
              Container(
                width: _columnWidths[columnIndex],
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

              // 크기 조절 핸들 (마지막 열 제외)
              if (columnIndex < _columns.length - 1) _buildResizeHandle(columnIndex),
            ],
          );
        }).toList(),
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
            // 최소 너비 50으로 제한
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
      children: List.generate(_logList.length, (index) {
        final log = _logList[index];
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
              final value = column.valueBuilder?.call(log) ?? '';
              final cellWidget = column.cellBuilder != null
                  ? column.cellBuilder!(log, value)
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
