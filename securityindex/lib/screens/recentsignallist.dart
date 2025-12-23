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
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

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

  // DataGrid 컨트롤러
  late DataGridController _dataGridController;
  late RecentSignalDataSource _dataSource;

  // 열 너비 저장 (열 크기 조정을 위해)
  final Map<String, double> _columnWidths = {
    'controlManagementNumber': 120,
    'controlBusinessName': 150,
    'receiveDateFormatted': 120,
    'receiveTimeFormatted': 100,
    'signalName': 150,
    'signalCode': 100,
    'remark': 150,
    'controllerName': 100,
    'publicLine': 120,
    'dedicatedLine': 120,
    'inputContent': 200,
    'textColor': 100,
    'backgroundColor': 100,
  };

  @override
  void initState() {
    super.initState();
    initCustomerServiceListener();
    _dataGridController = DataGridController();
    _dataSource = RecentSignalDataSource(
      signalList: _signalList,
      searchQuery: _pageSearchQuery,
    );
    _initializeData();
  }

  @override
  void dispose() {
    disposeCustomerServiceListener();
    _dataGridController.dispose();
    _searchController.dispose();
    super.dispose();
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
              // DataSource 업데이트
              _dataSource.updateDataSource(
                signalList: _signalList,
                searchQuery: _pageSearchQuery,
              );
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
          // DataSource 업데이트
          _dataSource.updateDataSource(
            signalList: _signalList,
            searchQuery: _pageSearchQuery,
          );
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
          // 제목
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

          // 데이터 그리드
          Expanded(
            child: Stack(
              children: [
                NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    // 스크롤 위치가 80%에 도달하면 추가 데이터 로드
                    if (!_isLoadingMore &&
                        _hasMore &&
                        scrollInfo.metrics.pixels >=
                            scrollInfo.metrics.maxScrollExtent * 0.8) {
                      _loadMoreData();
                    }
                    return false;
                  },
                  child: SfDataGrid(
                    source: _dataSource,
                    controller: _dataGridController,
                    // 행 높이 설정 (패딩 포함)
                    rowHeight: double.nan, // 자동 높이 조절
                    headerRowHeight: 45,
                    // 가로 스크롤 활성화
                    columnWidthMode: ColumnWidthMode.none,
                    // 열 크기 조정 활성화
                    allowColumnsResizing: true,
                    onColumnResizeUpdate: (ColumnResizeUpdateDetails details) {
                      setState(() {
                        // 열 너비 업데이트
                        _columnWidths[details.column.columnName] =
                            details.width;
                      });
                      return true;
                    },
                    // 그리드 라인 표시
                    gridLinesVisibility: GridLinesVisibility.both,
                    headerGridLinesVisibility: GridLinesVisibility.both,
                    // Load More 인디케이터
                    loadMoreViewBuilder:
                        (BuildContext context, LoadMoreRows loadMoreRows) {
                          // 로딩 중이고 더 로드할 데이터가 있을 때만 표시
                          if (_isLoadingMore && _hasMore) {
                            return Container(
                              height: 60.0,
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  top: BorderSide(
                                    width: 1.0,
                                    color: Color(0xFFE0E0E0),
                                  ),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 25,
                                    width: 25,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('데이터를 불러오는 중...'),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                    columns: [
                      GridColumn(
                        columnName: 'controlManagementNumber',
                        width: _columnWidths['controlManagementNumber']!,
                        label: Container(
                          padding: const EdgeInsets.all(8),
                          alignment: Alignment.center,
                          color: const Color(0xDAEEEEEE),
                          child: const Text(
                            '관제관리번호',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: const Color(0xDA363636),
                            ),
                          ),
                        ),
                      ),
                      GridColumn(
                        columnName: 'controlBusinessName',
                        width: _columnWidths['controlBusinessName']!,
                        label: Container(
                          padding: const EdgeInsets.all(8),
                          alignment: Alignment.center,
                          color: const Color(0xDAEEEEEE),
                          child: const Text(
                            '관제상호',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: const Color(0xDA363636),
                            ),
                          ),
                        ),
                      ),
                      GridColumn(
                        columnName: 'receiveDateFormatted',
                        width: _columnWidths['receiveDateFormatted']!,
                        label: Container(
                          padding: const EdgeInsets.all(8),
                          alignment: Alignment.center,
                          color: const Color(0xDAEEEEEE),
                          child: const Text(
                            '수신일자',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: const Color(0xDA363636),
                            ),
                          ),
                        ),
                      ),
                      GridColumn(
                        columnName: 'receiveTimeFormatted',
                        width: _columnWidths['receiveTimeFormatted']!,
                        label: Container(
                          padding: const EdgeInsets.all(8),
                          alignment: Alignment.center,
                          color: const Color(0xDAEEEEEE),
                          child: const Text(
                            '수신시간',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: const Color(0xDA363636),
                            ),
                          ),
                        ),
                      ),
                      GridColumn(
                        columnName: 'signalName',
                        width: _columnWidths['signalName']!,
                        label: Container(
                          padding: const EdgeInsets.all(8),
                          alignment: Alignment.center,
                          color: const Color(0xDAEEEEEE),
                          child: const Text(
                            '신호명',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: const Color(0xDA363636),
                            ),
                          ),
                        ),
                      ),
                      GridColumn(
                        columnName: 'signalCode',
                        width: _columnWidths['signalCode']!,
                        label: Container(
                          padding: const EdgeInsets.all(8),
                          alignment: Alignment.center,
                          color: const Color(0xDAEEEEEE),
                          child: const Text(
                            '메인코드',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: const Color(0xDA363636),
                            ),
                          ),
                        ),
                      ),
                      GridColumn(
                        columnName: 'remark',
                        width: _columnWidths['remark']!,
                        label: Container(
                          padding: const EdgeInsets.all(8),
                          alignment: Alignment.center,
                          color: const Color(0xDAEEEEEE),
                          child: const Text(
                            '비고',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: const Color(0xDA363636),
                            ),
                          ),
                        ),
                      ),
                      GridColumn(
                        columnName: 'controllerName',
                        width: _columnWidths['controllerName']!,
                        label: Container(
                          padding: const EdgeInsets.all(8),
                          alignment: Alignment.center,
                          color: const Color(0xDAEEEEEE),
                          child: const Text(
                            '관제자',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: const Color(0xDA363636),
                            ),
                          ),
                        ),
                      ),
                      GridColumn(
                        columnName: 'publicLine',
                        width: _columnWidths['publicLine']!,
                        label: Container(
                          padding: const EdgeInsets.all(8),
                          alignment: Alignment.center,
                          color: const Color(0xDAEEEEEE),
                          child: const Text(
                            '공중회선',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: const Color(0xDA363636),
                            ),
                          ),
                        ),
                      ),
                      GridColumn(
                        columnName: 'dedicatedLine',
                        width: _columnWidths['dedicatedLine']!,
                        label: Container(
                          padding: const EdgeInsets.all(8),
                          alignment: Alignment.center,
                          color: const Color(0xDAEEEEEE),
                          child: const Text(
                            '전용회선',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: const Color(0xDA363636),
                            ),
                          ),
                        ),
                      ),
                      GridColumn(
                        columnName: 'inputContent',
                        width: _columnWidths['inputContent']!,
                        label: Container(
                          padding: const EdgeInsets.all(8),
                          alignment: Alignment.center,
                          color: const Color(0xDAEEEEEE),
                          child: const Text(
                            '입력내용',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: const Color(0xDA363636),
                            ),
                          ),
                        ),
                      ),
                      GridColumn(
                        columnName: 'textColor',
                        width: _columnWidths['textColor']!,
                        label: Container(
                          padding: const EdgeInsets.all(8),
                          alignment: Alignment.center,
                          color: const Color(0xDAEEEEEE),
                          child: const Text(
                            '글자색',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: const Color(0xDA363636),
                            ),
                          ),
                        ),
                      ),
                      GridColumn(
                        columnName: 'backgroundColor',
                        width: _columnWidths['backgroundColor']!,
                        label: Container(
                          padding: const EdgeInsets.all(8),
                          alignment: Alignment.center,
                          color: const Color(0xDAEEEEEE),
                          child: const Text(
                            '배경색',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: const Color(0xDA363636),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Syncfusion DataGrid를 위한 DataSource 클래스
class RecentSignalDataSource extends DataGridSource {
  RecentSignalDataSource({
    required List<RecentSignalInfo> signalList,
    required String searchQuery,
  }) : _signalList = signalList,
       _searchQuery = searchQuery {
    buildDataGridRows();
  }

  List<RecentSignalInfo> _signalList;
  String _searchQuery;
  List<DataGridRow> _dataGridRows = [];

  @override
  List<DataGridRow> get rows => _dataGridRows;

  @override
  Future<void> handleLoadMoreRows() async {
    // loadMoreViewBuilder에서 호출됨
    // 실제 데이터 로딩은 _loadMoreData()에서 처리
    await Future.delayed(const Duration(milliseconds: 200));
    notifyListeners();
  }

  /// DataGridRow 목록 구축
  void buildDataGridRows() {
    _dataGridRows = _signalList.map<DataGridRow>((signal) {
      return DataGridRow(
        cells: [
          DataGridCell<String>(
            columnName: 'controlManagementNumber',
            value: signal.controlManagementNumber ?? '-',
          ),
          DataGridCell<String>(
            columnName: 'controlBusinessName',
            value: signal.controlBusinessName ?? '-',
          ),
          DataGridCell<String>(
            columnName: 'receiveDateFormatted',
            value: signal.receiveDateFormatted,
          ),
          DataGridCell<String>(
            columnName: 'receiveTimeFormatted',
            value: signal.receiveTimeFormatted,
          ),
          DataGridCell<String>(
            columnName: 'signalName',
            value: signal.signalName ?? '-',
          ),
          DataGridCell<String>(
            columnName: 'signalCode',
            value: signal.signalCode ?? '-',
          ),
          DataGridCell<String>(
            columnName: 'remark',
            value: signal.remark ?? '-',
          ),
          DataGridCell<String>(
            columnName: 'controllerName',
            value: signal.controllerName ?? '-',
          ),
          DataGridCell<String>(
            columnName: 'publicLine',
            value: signal.publicLine ?? '-',
          ),
          DataGridCell<String>(
            columnName: 'dedicatedLine',
            value: signal.dedicatedLine ?? '-',
          ),
          DataGridCell<String>(
            columnName: 'inputContent',
            value: signal.inputContent ?? '-',
          ),
          DataGridCell<String>(
            columnName: 'textColor',
            value: signal.textColor ?? '-',
          ),
          DataGridCell<String>(
            columnName: 'backgroundColor',
            value: signal.backgroundColor ?? '-',
          ),
        ],
      );
    }).toList();
  }

  /// 데이터 업데이트
  void updateDataSource({
    required List<RecentSignalInfo> signalList,
    required String searchQuery,
  }) {
    _signalList = signalList;
    _searchQuery = searchQuery;
    buildDataGridRows();
    notifyListeners();
  }

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((cell) {
        final value = cell.value.toString();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Center(
            child: HighlightedText(
              text: value,
              query: _searchQuery,
              style: const TextStyle(color: Color(0xFF252525), fontSize: 13),
              overflow: TextOverflow.visible,
              softWrap: true,
              textAlign: TextAlign.center,
            ),
          ),
        );
      }).toList(),
    );
  }
}
