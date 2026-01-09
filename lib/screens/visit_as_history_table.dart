import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../functions.dart';
import '../models/search_panel.dart';
import '../models/visit_as_history.dart';
import '../services/api_service.dart';
import '../services/selected_customer_service.dart';
import '../theme.dart';
import '../style.dart';
import '../widgets/common_table.dart';
import '../widgets/component.dart';

/// 최근 방문 및 A/S 이력 테이블 화면
class VisitAsHistoryTable extends StatefulWidget {
  final SearchPanel? searchpanel;
  const VisitAsHistoryTable({super.key, this.searchpanel});

  @override
  State<VisitAsHistoryTable> createState() => VisitAsHistoryTableState();
}

class VisitAsHistoryTableState extends State<VisitAsHistoryTable>
    with CustomerServiceHandler, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // 데이터 목록
  List<VisitAsHistory> _dataList = [];
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
    0: 150.0, // 요청일자
    1: 100.0, // 권역명
    2: 200.0, // 요청제목
    3: 100.0, // 처리여부
    4: 150.0, // 처리일시
    5: 200.0, // 처리비고
    6: 100.0, // 접수자
    7: 100.0, // 처리자
    8: 120.0, // 개인AS처리자
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
        header: '요청일자',
        width: _columnWidths[0],
        valueBuilder: (data) => (data as VisitAsHistory).requestDate ?? '-',
      ),
      TableColumnConfig(
        header: '권역명',
        width: _columnWidths[1],
        valueBuilder: (data) => (data as VisitAsHistory).areaName ?? '-',
      ),
      TableColumnConfig(
        header: '요청제목',
        width: _columnWidths[2],
        valueBuilder: (data) => (data as VisitAsHistory).requestTitle ?? '-',
      ),
      TableColumnConfig(
        header: '처리여부',
        width: _columnWidths[3],
        valueBuilder: (data) => (data as VisitAsHistory).processingStatusText,
      ),
      TableColumnConfig(
        header: '처리일시',
        width: _columnWidths[4],
        valueBuilder: (data) =>
            (data as VisitAsHistory).processingDateTime ?? '-',
      ),
      TableColumnConfig(
        header: '처리비고',
        width: _columnWidths[5],
        valueBuilder: (data) => (data as VisitAsHistory).processingNote ?? '-',
      ),
      TableColumnConfig(
        header: '접수자',
        width: _columnWidths[6],
        valueBuilder: (data) => (data as VisitAsHistory).receptionist ?? '-',
      ),
      TableColumnConfig(
        header: '처리자',
        width: _columnWidths[7],
        valueBuilder: (data) => (data as VisitAsHistory).processor ?? '-',
      ),
      TableColumnConfig(
        header: '개인AS처리자',
        width: _columnWidths[8],
        valueBuilder: (data) =>
            (data as VisitAsHistory).personalAsProcessor ?? '-',
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
    final customerDetail = customerService.customerDetail;

    if (customerDetail != null && customerDetail.erpCusNumber != null) {
      await _loadData(customerDetail.erpCusNumber!);
    } else {
      setState(() {
        _dataList = [];
      });
    }
  }

  /// CustomerServiceHandler 콜백 구현
  @override
  void onCustomerChanged(SearchPanel? customer, detail) {
    if (detail != null && detail.erpCusNumber != null) {
      _loadData(detail.erpCusNumber!);
    } else {
      setState(() {
        _dataList = [];
      });
    }
  }

  /// 데이터 로드
  Future<void> _loadData(String customerNumber) async {
    setState(() {
      _isLoading = true;
      _dataList.clear();
    });

    try {
      final data = await DatabaseService.getVisitAsHistory(customerNumber);

      if (mounted) {
        setState(() {
          _dataList = data;
          _isLoading = false;
        });
      }

      print('최근 방문 및 A/S이력 데이터 로드 완료: ${data.length}건');
    } catch (e) {
      print('최근 방문 및 A/S이력 데이터 로드 오류: $e');
      if (mounted) {
        setState(() {
          _dataList = [];
          _isLoading = false;
        });
      }
    }
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
                '최근 방문 및 A/S 이력',
                style: TextStyle(
                  color: Color(0xFF252525),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
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
          height: 45,
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
