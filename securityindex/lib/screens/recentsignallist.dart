import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/search_panel.dart';
import '../models/customer_detail.dart';
import '../models/recentsignalinfo.dart';
import '../services/api_service.dart';
import '../functions.dart';
import '../theme.dart';
import '../style.dart';
import '../widgets/component.dart';
import '../widgets/common_table.dart';
import '../widgets/custom_top_bar.dart';
import 'package:flutter/gestures.dart';

/// 최근 관제신호 목록 화면
class RecentSignalList extends StatefulWidget {
  final SearchPanel? searchpanel;
  const RecentSignalList({super.key, this.searchpanel});

  @override
  State<RecentSignalList> createState() => RecentSignalListState();
}

class RecentSignalListState extends State<RecentSignalList>
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

  // 신호 데이터 목록
  List<RecentSignalInfo> _signalList = [];
  int _currentSkip = 0; // 현재 건너뛴 개수
  bool _hasMore = true; // 더 로드할 데이터가 있는지
  int _totalCount = 0; // 전체 신호 개수

  // 필터 설정
  String _selectedSignalFilter = '전체신호';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isAscending = false;

  // 로딩 상태
  bool _isLoading = false;
  bool _isLoadingMore = false;

  // 스크롤 컨트롤러
  final ScrollController _scrollController = ScrollController();
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _bodyScrollController = ScrollController();

  // 스크롤 동기화 플래그
  bool _isSyncingScroll = false;

  // 테이블 열 너비 (드래그로 조절 가능)
  final Map<int, double> _columnWidths = {
    0: 120.0, // 관제관리번호
    1: 150.0, // 관제상호
    2: 120.0, // 수신일자
    3: 100.0, // 수신시간
    4: 150.0, // 신호명
    5: 100.0, // 메인코드
    6: 150.0, // 비고
    7: 100.0, // 관제자
    8: 120.0, // 공중회선
    9: 120.0, // 전용회선
    10: 200.0, // 입력내용
    11: 100.0, // 글자색
    12: 100.0, // 배경색
  };

  // 테이블 컬럼 설정
  late final List<TableColumnConfig> _columns;

  @override
  void initState() {
    super.initState();
    initCustomerServiceListener();
    _initializeData();
    _scrollController.addListener(_onScroll);

    // 가로 스크롤 동기화
    _headerScrollController.addListener(_syncHeaderScroll);
    _bodyScrollController.addListener(_syncBodyScroll);

    // 날짜 컨트롤러 초기화
    _startDateController.text = DateFormat('yyyy-MM-dd').format(_startDate);
    _endDateController.text = DateFormat('yyyy-MM-dd').format(_endDate);

    // 테이블 컬럼 설정 초기화
    _columns = [
      TableColumnConfig(
        header: '관제관리번호',
        width: _columnWidths[0],
        valueBuilder: (data) => data.controlManagementNumber ?? '',
      ),
      TableColumnConfig(
        header: '관제상호',
        width: _columnWidths[1],
        valueBuilder: (data) => data.controlBusinessName ?? '',
      ),
      TableColumnConfig(
        header: '수신일자',
        width: _columnWidths[2],
        valueBuilder: (data) => data.receiveDate,
      ),
      TableColumnConfig(
        header: '수신시간',
        width: _columnWidths[3],
        valueBuilder: (data) => dateParsing(data.receiveTime),
      ),
      TableColumnConfig(
        header: '신호명',
        width: _columnWidths[4],
        valueBuilder: (data) => data.signalName ?? '',
      ),
      TableColumnConfig(
        header: '메인코드',
        width: _columnWidths[5],
        valueBuilder: (data) => data.signalCode ?? '',
      ),
      TableColumnConfig(
        header: '비고',
        width: _columnWidths[6],
        valueBuilder: (data) => data.remark ?? '',
      ),
      TableColumnConfig(
        header: '관제자',
        width: _columnWidths[7],
        valueBuilder: (data) => data.controllerName ?? '',
      ),
      TableColumnConfig(
        header: '공중회선',
        width: _columnWidths[8],
        valueBuilder: (data) => data.publicLine ?? '',
      ),
      TableColumnConfig(
        header: '전용회선',
        width: _columnWidths[9],
        valueBuilder: (data) => data.dedicatedLine ?? '',
      ),
      TableColumnConfig(
        header: '입력내용',
        width: _columnWidths[10],
        valueBuilder: (data) => data.inputContent ?? '',
      ),
      TableColumnConfig(
        header: '글자색',
        width: _columnWidths[11],
        valueBuilder: (data) => data.textColor ?? '',
      ),
      TableColumnConfig(
        header: '배경색',
        width: _columnWidths[12],
        valueBuilder: (data) => data.backgroundColor ?? '',
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

  /// 스크롤 이벤트 처리 (페이징)
  void _onScroll() {
    // 스크롤이 80% 이상 내려왔을 때만 추가 로드 (중복 방지)
    if (!_isLoadingMore &&
        _hasMore &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreData();
    }
  }

  /// 추가 데이터 로드
  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMore) {
      return; // 이미 로딩 중이거나 더 이상 로드할 데이터가 없는 경우
    }

    final customer = customerService.selectedCustomer;
    if (customer == null) return;

    // UI 업데이트는 먼저 처리
    setState(() {
      _isLoadingMore = true;
    });

    // 백그라운드에서 데이터 로드 (버벅거림 방지)
    try {
      final nextSkip = _currentSkip + 100;
      final result = await DatabaseService.getRecentSignals(
        managementNumber: customer.controlManagementNumber,
        startDate: _startDate,
        endDate: _endDate,
        signalFilter: _selectedSignalFilter,
        ascending: _isAscending,
        skip: nextSkip,
        take: 100,
      );

      final signals = result['data'] as List<RecentSignalInfo>;
      final totalCount = result['totalCount'] as int;

      if (mounted) {
        // microtask로 UI 업데이트 지연 (부드러운 스크롤)
        Future.microtask(() {
          if (mounted) {
            setState(() {
              _signalList.addAll(signals);
              _currentSkip = nextSkip;
              _totalCount = totalCount;
              _hasMore = _signalList.length < _totalCount;
              _isLoadingMore = false;
            });
          }
        });
      }

      print(
        '추가 신호 데이터 로드 완료: ${signals.length}건 (표시: ${_signalList.length}/${_totalCount}건)',
      );
    } catch (e) {
      print('추가 신호 데이터 로드 오류: $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  /// 초기 데이터 로드
  Future<void> _initializeData() async {
    await _loadCustomerDataFromService();
  }

  /// 전역 서비스에서 고객 데이터 로드
  Future<void> _loadCustomerDataFromService() async {
    final customer = customerService.selectedCustomer;

    if (customer != null) {
      await _loadSignalData(customer.controlManagementNumber);
    } else {
      setState(() {
        _signalList = [];
      });
    }
  }

  /// CustomerServiceHandler 콜백 구현
  @override
  void onCustomerChanged(SearchPanel? customer, CustomerDetail? detail) {
    if (customer != null) {
      _loadSignalData(customer.controlManagementNumber);
    } else {
      setState(() {
        _signalList = [];
      });
    }
  }

  /// 신호 데이터 로드
  Future<void> _loadSignalData(String managementNumber) async {
    setState(() {
      _isLoading = true;
      _currentSkip = 0; // 초기화
      _hasMore = true; // 초기화
      _totalCount = 0; // 초기화
      _signalList.clear(); // 기존 데이터 클리어
    });

    try {
      final result = await DatabaseService.getRecentSignals(
        managementNumber: managementNumber,
        startDate: _startDate,
        endDate: _endDate,
        signalFilter: _selectedSignalFilter,
        ascending: _isAscending,
        skip: 0,
        take: 100,
      );

      final signals = result['data'] as List<RecentSignalInfo>;
      final totalCount = result['totalCount'] as int;

      if (mounted) {
        setState(() {
          _signalList = signals;
          _totalCount = totalCount;
          _hasMore = signals.length < totalCount;
          _isLoading = false;
        });
      }

      print('최근 신호 데이터 로드 완료: ${signals.length}건 / 전체: ${totalCount}건');
    } catch (e) {
      print('최근 신호 데이터 로드 오류: $e');
      if (mounted) {
        setState(() {
          _signalList = [];
          _totalCount = 0;
          _isLoading = false;
        });
      }
    }
  }

  /// 관제신호 새로고침 버튼 클릭
  Future<void> _refreshSignalData() async {
    // 조회 버튼을 눌렀을 때 날짜 값을 확정
    _parseStartDate(_startDateController.text);
    _parseEndDate(_endDateController.text);

    final customer = customerService.selectedCustomer;
    if (customer != null) {
      await _loadSignalData(customer.controlManagementNumber);
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
        await _loadSignalData(customer.controlManagementNumber);
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
                  Expanded(child: _buildSignalTable()),
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
              // 신호 필터 드롭다운
              SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '신호 필터',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF252525),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSignalFilter,
                          isExpanded: true,
                          items: ['전체신호', '경계해제신호', '처리신호제외']
                              .map(
                                (filter) => DropdownMenuItem(
                                  value: filter,
                                  child: Text(filter),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedSignalFilter = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

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

              // 오름차순 정렬 체크박스
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '정렬 옵션',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF252525),
                    ),
                  ),
                  const SizedBox(height: 8),
                  buildCheckbox('오름차순 정렬', _isAscending, (value) {
                    setState(() {
                      _isAscending = value ?? false;
                    });
                  }),
                ],
              ),
              const SizedBox(width: 16),

              // 조회 버튼
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _refreshSignalData,
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '관제신호 새로고침',
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
  Widget _buildSignalTable() {
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
                '최근 관제신호 목록',
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
            child: Stack(
              children: [
                // 테이블 (항상 렌더링)
                _buildResizableTable(),
                // 로딩 인디케이터 (테이블 중앙)
                if (_isLoadingMore)
                  Container(
                    color: Colors.black.withOpacity(0.1),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text(
                              '데이터를 불러오는 중...',
                              style: TextStyle(
                                color: Color(0xFF252525),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
                child: buildTableBody(),
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
              if (columnIndex < _columns.length - 1)
                _buildResizeHandle(columnIndex),
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
  Widget buildTableBody() {
    return Column(
      children: List.generate(_signalList.length, (index) {
        final signal = _signalList[index];
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
              final value = column.valueBuilder?.call(signal) ?? '';
              final cellWidget = column.cellBuilder != null
                  ? column.cellBuilder!(signal, value)
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
