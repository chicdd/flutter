import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/search_panel.dart';
import '../models/customer_history.dart';
import '../services/api_service.dart';
import '../functions.dart';
import '../theme.dart';
import '../style.dart';
import '../widgets/component.dart';
import 'package:flutter/gestures.dart';
import '../widgets/common_table.dart';
import '../widgets/custom_top_bar.dart';

/// 고객정보 변동이력 화면
class CustomerInfoHistory extends StatefulWidget {
  final SearchPanel? searchpanel;
  const CustomerInfoHistory({super.key, this.searchpanel});

  @override
  State<CustomerInfoHistory> createState() => CustomerInfoHistoryState();
}

class CustomerInfoHistoryState extends State<CustomerInfoHistory>
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

  // 변동이력 데이터 목록 (임시 데이터)
  List<CustomerHistoryData> _dataList = [];
  int _totalCount = 0;

  // 필터 설정
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 365));
  DateTime _endDate = DateTime.now();

  // 테이블 열 너비 (드래그로 조절 가능)
  final Map<int, double> _columnWidths = {
    0: 120.0, // 처리자
    1: 180.0, // 변경처리일시
    2: 300.0, // 변경전
    3: 150.0, // 변경후
    4: 300.0, // 메모
  };

  // 테이블 컬럼 설정
  late final List<TableColumnConfig> _columns = [
    TableColumnConfig(
      header: '처리자',
      width: _columnWidths[0],
      valueBuilder: (data) => data.handler,
    ),
    TableColumnConfig(
      header: '변경처리일시',
      width: _columnWidths[1],
      valueBuilder: (data) => data.changeDateTimeFormatted,
    ),
    TableColumnConfig(
      header: '변경전',
      width: _columnWidths[2],
      valueBuilder: (data) => data.beforeValue,
    ),
    TableColumnConfig(
      header: '변경후',
      width: _columnWidths[3],
      valueBuilder: (data) => data.afterValue,
    ),
    TableColumnConfig(
      header: '메모',
      width: _columnWidths[4],
      valueBuilder: (data) => data.memo,
    ),
  ];

  @override
  void initState() {
    super.initState();
    initCustomerServiceListener();
    _initializeData();

    // 날짜 컨트롤러 초기화
    _startDateController.text = DateFormat('yyyy-MM-dd').format(_startDate);
    _endDateController.text = DateFormat('yyyy-MM-dd').format(_endDate);
  }

  @override
  void dispose() {
    disposeCustomerServiceListener();
    _searchController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
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
      await _loadHistoryData(customer.controlManagementNumber);
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
      _loadHistoryData(customer.controlManagementNumber);
    } else {
      setState(() {
        _dataList = [];
      });
    }
  }

  /// 변동이력 데이터 로드
  Future<void> _loadHistoryData(String managementNumber) async {
    setState(() {
      _dataList.clear();
    });

    try {
      final result = await DatabaseService.getCustomerHistory(
        managementNumber: managementNumber,
        startDate: _startDate,
        endDate: _endDate,
        skip: 0,
        take: 100,
      );

      final history = result['data'] as List<CustomerHistoryData>;
      final totalCount = result['totalCount'] as int;

      if (mounted) {
        setState(() {
          _dataList = history;
          _totalCount = totalCount;
        });
      }

      print('변동이력 데이터 로드 완료: ${history.length}건 / 전체: ${totalCount}건');
    } catch (e) {
      print('변동이력 데이터 로드 오류: $e');
      if (mounted) {
        setState(() {
          _dataList = [];
          _totalCount = 0;
        });
      }
    }
  }

  /// 변동이력 새로고침 버튼 클릭
  Future<void> _refreshHistoryData() async {
    // 조회 버튼을 눌렀을 때 날짜 값을 확정
    DateParsingHelper.openDatePicker(
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
    );
    DateParsingHelper.openDatePicker(
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
    );

    final customer = customerService.selectedCustomer;
    if (customer != null) {
      await _loadHistoryData(customer.controlManagementNumber);
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
        await _loadHistoryData(customer.controlManagementNumber);
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
                      title: '고객정보 변동이력',
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

              // 조회 버튼
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: _refreshHistoryData,
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
}
