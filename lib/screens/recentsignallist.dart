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
  List<RecentSignalInfo> _dataList = [];
  int _currentSkip = 0; // 현재 건너뛴 개수
  bool _hasMore = true; // 더 로드할 데이터가 있는지
  int _totalCount = 0; // 전체 신호 개수

  // 필터 설정
  String _selectedSignalFilter = '전체신호';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isAscending = false;

  // 로딩 상태
  bool _isLoadingMore = false;

  // 스크롤 컨트롤러
  final ScrollController _scrollController = ScrollController();

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
  late final List<TableColumnConfig> _columns = [
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

  @override
  void initState() {
    super.initState();
    initCustomerServiceListener();
    _initializeData();
    _scrollController.addListener(_onScroll);

    // 날짜 컨트롤러 초기화
    _startDateController.text = DateFormat('yyyy-MM-dd').format(_startDate);
    _endDateController.text = DateFormat('yyyy-MM-dd').format(_endDate);
  }

  @override
  void dispose() {
    disposeCustomerServiceListener();
    _scrollController.dispose();
    _searchController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
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
    print('페이징기능 작동');
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
              _dataList.addAll(signals);
              _currentSkip = nextSkip;
              _totalCount = totalCount;
              _hasMore = _dataList.length < _totalCount;
              _isLoadingMore = false;
            });
          }
        });
      }

      print(
        '추가 신호 데이터 로드 완료: ${signals.length}건 (표시: ${_dataList.length}/${_totalCount}건)',
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
        _dataList = [];
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
        _dataList = [];
      });
    }
  }

  /// 신호 데이터 로드
  Future<void> _loadSignalData(String managementNumber) async {
    setState(() {
      _currentSkip = 0; // 초기화
      _hasMore = true; // 초기화
      _totalCount = 0; // 초기화
      _dataList.clear(); // 기존 데이터 클리어
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
          _dataList = signals;
          _totalCount = totalCount;
          _hasMore = signals.length < totalCount;
        });
      }

      print('최근 신호 데이터 로드 완료: ${signals.length}건 / 전체: ${totalCount}건');
    } catch (e) {
      print('최근 신호 데이터 로드 오류: $e');
      if (mounted) {
        setState(() {
          _dataList = [];
          _totalCount = 0;
        });
      }
    }
  }

  /// 관제신호 새로고침 버튼 클릭
  Future<void> _refreshSignalData() async {
    // 조회 버튼을 눌렀을 때 날짜 값을 확정

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
                  Expanded(
                    child: buildTable(
                      context: context,
                      title: '최근 관제신호 목록',
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
                      pagingTotalcount: _totalCount,
                      verticalScrollController: _scrollController,
                    ),
                  ),
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
                onSubmitted: () => DateParsingHelper.openDatePicker(
                  context: context,
                  isStartDate: true,
                  startDate: _startDate,
                  endDate: _endDate,
                  startController: _startDateController,
                  endController: _endDateController,
                  onConfirm: (newStart, newEnd) async {
                    setState(() {
                      _startDate = newStart;
                      _endDate = newEnd;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),

              // 종료 날짜
              DateTextField(
                label: '검색 종료일자',
                controller: _endDateController,
                onCalendarPressed: _selectDate,
                onSubmitted: () => DateParsingHelper.openDatePicker(
                  context: context,
                  isStartDate: false,
                  startDate: _startDate,
                  endDate: _endDate,
                  startController: _startDateController,
                  endController: _endDateController,
                  onConfirm: (newStart, newEnd) async {
                    setState(() {
                      _startDate = newStart;
                      _endDate = newEnd;
                    });
                  },
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
                    onPressed: _refreshSignalData,
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
}
