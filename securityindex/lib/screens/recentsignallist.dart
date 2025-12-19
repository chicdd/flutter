import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/search_panel.dart';
import '../models/customer_detail.dart';
import '../models/recentsignalinfo.dart';
import '../services/api_service.dart';
import '../functions.dart';
import '../theme.dart';
import '../widgets/component.dart';
import '../widgets/custom_top_bar.dart';
import '../widgets/common_table.dart';
import 'package:flutter/gestures.dart';

/// 최근 관제신호 목록 화면
class RecentSignalListScreen extends StatefulWidget {
  final SearchPanel? searchpanel;
  const RecentSignalListScreen({super.key, this.searchpanel});

  @override
  State<RecentSignalListScreen> createState() => _RecentSignalListScreenState();
}

class _RecentSignalListScreenState extends State<RecentSignalListScreen>
    with CustomerServiceHandler, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  // 검색 컨트롤러
  final TextEditingController _searchController = TextEditingController();
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

  @override
  void initState() {
    super.initState();
    initCustomerServiceListener();
    _initializeData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    disposeCustomerServiceListener();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
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
    final customer = customerService.selectedCustomer;
    if (customer != null) {
      await _loadSignalData(customer.controlManagementNumber);
    }
  }

  /// 날짜 선택 다이얼로그
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2008, 8),
      lastDate: DateTime.now(),
      locale: const Locale('ko', 'KR'),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
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
              SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '검색 시작일자',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF252525),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context, true),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('yyyy-MM-dd').format(_startDate),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // 종료 날짜
              SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '검색 종료일자',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF252525),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context, false),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('yyyy-MM-dd').format(_endDate),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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
    return Stack(
      children: [
        // 테이블
        CommonDataTable(
          title: '최근 관제신호 목록 (총 $_totalCount건)',
          enableHorizontalScroll: true,
          scrollController: _scrollController,
          columns: [
            TableColumnConfig(
              header: '관제관리번호',
              width: 120.0,
              valueBuilder: (data) => data.controlManagementNumber ?? '-',
              cellBuilder: (data, value) => Center(
                child: HighlightedText(
                  text: value,
                  query: _pageSearchQuery,
                  style: const TextStyle(
                    color: Color(0xFF252525),
                    fontSize: 15,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            TableColumnConfig(
              header: '관제상호',
              width: 150.0,
              valueBuilder: (data) => data.controlBusinessName ?? '-',
              cellBuilder: (data, value) => Center(
                child: HighlightedText(
                  text: value,
                  query: _pageSearchQuery,
                  style: const TextStyle(
                    color: Color(0xFF252525),
                    fontSize: 15,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            TableColumnConfig(
              header: '수신일자',
              width: 120.0,
              valueBuilder: (data) => data.receiveDateFormatted,
              cellBuilder: (data, value) => Center(
                child: HighlightedText(
                  text: value,
                  query: _pageSearchQuery,
                  style: const TextStyle(
                    color: Color(0xFF252525),
                    fontSize: 15,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            TableColumnConfig(
              header: '수신시간',
              width: 100.0,
              valueBuilder: (data) => data.receiveTimeFormatted,
              cellBuilder: (data, value) => Center(
                child: HighlightedText(
                  text: value,
                  query: _pageSearchQuery,
                  style: const TextStyle(
                    color: Color(0xFF252525),
                    fontSize: 15,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            TableColumnConfig(
              header: '신호명',
              width: 150.0,
              valueBuilder: (data) => data.signalName ?? '-',
              cellBuilder: (data, value) => Center(
                child: HighlightedText(
                  text: value,
                  query: _pageSearchQuery,
                  style: const TextStyle(
                    color: Color(0xFF252525),
                    fontSize: 15,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            TableColumnConfig(
              header: '메인코드',
              width: 100.0,
              valueBuilder: (data) => data.signalCode ?? '-',
              cellBuilder: (data, value) => Center(
                child: HighlightedText(
                  text: value,
                  query: _pageSearchQuery,
                  style: const TextStyle(
                    color: Color(0xFF252525),
                    fontSize: 15,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            TableColumnConfig(
              header: '비고',
              width: 150.0,
              valueBuilder: (data) => data.remark ?? '-',
              cellBuilder: (data, value) => Center(
                child: HighlightedText(
                  text: value,
                  query: _pageSearchQuery,
                  style: const TextStyle(
                    color: Color(0xFF252525),
                    fontSize: 15,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            TableColumnConfig(
              header: '관제자',
              width: 100.0,
              valueBuilder: (data) => data.controllerName ?? '-',
              cellBuilder: (data, value) => Center(
                child: HighlightedText(
                  text: value,
                  query: _pageSearchQuery,
                  style: const TextStyle(
                    color: Color(0xFF252525),
                    fontSize: 15,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            TableColumnConfig(
              header: '공중회선',
              width: 120.0,
              valueBuilder: (data) => data.publicLine ?? '-',
              cellBuilder: (data, value) => Center(
                child: HighlightedText(
                  text: value,
                  query: _pageSearchQuery,
                  style: const TextStyle(
                    color: Color(0xFF252525),
                    fontSize: 15,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            TableColumnConfig(
              header: '전용회선',
              width: 120.0,
              valueBuilder: (data) => data.dedicatedLine ?? '-',
              cellBuilder: (data, value) => Center(
                child: HighlightedText(
                  text: value,
                  query: _pageSearchQuery,
                  style: const TextStyle(
                    color: Color(0xFF252525),
                    fontSize: 15,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            TableColumnConfig(
              header: '입력내용',
              width: 200.0,
              valueBuilder: (data) => data.inputContent ?? '-',
              cellBuilder: (data, value) => Center(
                child: HighlightedText(
                  text: value,
                  query: _pageSearchQuery,
                  style: const TextStyle(
                    color: Color(0xFF252525),
                    fontSize: 15,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            TableColumnConfig(
              header: '글자색',
              width: 100.0,
              valueBuilder: (data) => data.textColor ?? '-',
              cellBuilder: (data, value) => Center(
                child: HighlightedText(
                  text: value,
                  query: _pageSearchQuery,
                  style: const TextStyle(
                    color: Color(0xFF252525),
                    fontSize: 15,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            TableColumnConfig(
              header: '배경색',
              width: 100.0,
              valueBuilder: (data) => data.backgroundColor ?? '-',
              cellBuilder: (data, value) => Center(
                child: HighlightedText(
                  text: value,
                  query: _pageSearchQuery,
                  style: const TextStyle(
                    color: Color(0xFF252525),
                    fontSize: 15,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
          data: _signalList,
          emptyMessage: '조회된 신호가 없습니다.',
        ),
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
    );
  }
}
