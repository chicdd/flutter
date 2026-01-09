import 'package:flutter/material.dart';
import '../models/search_panel.dart';
import '../models/customer_detail.dart';
import '../functions.dart';
import '../theme.dart';
import '../widgets/common_table.dart';

/// 설치자재현황 화면
class MaterialStatus extends StatefulWidget {
  final SearchPanel? searchpanel;
  const MaterialStatus({super.key, this.searchpanel});

  @override
  State<MaterialStatus> createState() => MaterialStatusState();
}

class MaterialStatusState extends State<MaterialStatus>
    with CustomerServiceHandler {
  // 검색 컨트롤러
  final TextEditingController _searchController = TextEditingController();

  // 자재 데이터 목록 (추후 모델 추가 필요)
  List<Map<String, dynamic>> _materialList = [];

  // 페이지 내 검색
  String _pageSearchQuery = '';

  // 테이블 관련 변수
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _bodyScrollController = ScrollController();
  bool _isSyncingScroll = false;
  final Map<int, double> _columnWidths = {
    0: 200.0, // 자재명칭
    1: 120.0, // 설치수량
    2: 120.0, // 자재코드
    3: 120.0, // 자재년식
    4: 200.0, // 대분류
    5: 200.0, // 중분류
  };
  late final List<TableColumnConfig> _columns;

  // 검색 쿼리 업데이트 메서드
  void updateSearchQuery(String query) {
    setState(() {
      _pageSearchQuery = query;
    });
  }

  @override
  void initState() {
    super.initState();
    // 공통 리스너 초기화
    initCustomerServiceListener();

    // 테이블 컬럼 설정
    _columns = [
      TableColumnConfig(
        header: '자재명칭',
        width: _columnWidths[0],
        valueBuilder: (data) => data['자재명칭']?.toString() ?? '-',
      ),
      TableColumnConfig(
        header: '설치수량',
        width: _columnWidths[1],
        valueBuilder: (data) => data['설치수량']?.toString() ?? '-',
      ),
      TableColumnConfig(
        header: '자재코드',
        width: _columnWidths[2],
        valueBuilder: (data) => data['자재코드']?.toString() ?? '-',
      ),
      TableColumnConfig(
        header: '자재년식',
        width: _columnWidths[3],
        valueBuilder: (data) => data['자재년식']?.toString() ?? '-',
      ),
      TableColumnConfig(
        header: '대분류',
        width: _columnWidths[4],
        valueBuilder: (data) => data['대분류']?.toString() ?? '-',
      ),
      TableColumnConfig(
        header: '중분류',
        width: _columnWidths[5],
        valueBuilder: (data) => data['중분류']?.toString() ?? '-',
      ),
    ];

    // 스크롤 동기화
    _headerScrollController.addListener(_syncHeaderScroll);
    _bodyScrollController.addListener(_syncBodyScroll);

    // 초기 데이터 로드
    _initializeData();
  }

  @override
  void dispose() {
    // 공통 리스너 해제
    disposeCustomerServiceListener();
    _searchController.dispose();
    _headerScrollController.dispose();
    _bodyScrollController.dispose();
    super.dispose();
  }

  /// 초기 데이터 로드
  Future<void> _initializeData() async {
    // 서비스에서 고객 데이터 로드
    await _loadCustomerDataFromService();
  }

  /// 전역 서비스에서 고객 데이터 로드
  Future<void> _loadCustomerDataFromService() async {
    final customer = customerService.selectedCustomer;

    if (customer != null) {
      await _loadMaterialData(customer.controlManagementNumber);
    } else {
      setState(() {
        _materialList = [];
      });
    }
  }

  /// CustomerServiceHandler 콜백 구현
  @override
  void onCustomerChanged(SearchPanel? customer, CustomerDetail? detail) {
    if (customer != null) {
      _loadMaterialData(customer.controlManagementNumber);
    } else {
      setState(() {
        _materialList = [];
      });
    }
  }

  /// 자재 데이터 로드 (추후 API 연동 필요)
  Future<void> _loadMaterialData(String managementNumber) async {
    try {
      // TODO: API 연동 필요
      // final materialList = await DatabaseService.getMaterialStatus(managementNumber);

      if (mounted) {
        setState(() {
          // 임시 데이터
          _materialList = [];
        });
      }

      print('설치자재현황 데이터 로드 완료: ${_materialList.length}개');
    } catch (e) {
      print('설치자재현황 데이터 로드 오류: $e');
      if (mounted) {
        setState(() {
          _materialList = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // 상단바
          // 메인 컨텐츠
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Expanded(child: _buildTableSection())],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 테이블 섹션
  Widget _buildTableSection() {
    return _buildTable();
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

  /// 테이블 구성
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
          const Text(
            '설치자재현황',
            style: TextStyle(
              color: Color(0xFF252525),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _materialList.isEmpty
                ? const Center(
                    child: Text(
                      '설치자재현황 데이터가 없습니다.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : _buildResizableTable(),
          ),
        ],
      ),
    );
  }

  /// 크기 조절 가능한 테이블
  Widget _buildResizableTable() {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            controller: _headerScrollController,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: _buildTableHeader(),
          ),
          Expanded(
            child: SingleChildScrollView(
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

  /// 테이블 헤더
  Widget _buildTableHeader() {
    return Container(
      height: 45,
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
              if (columnIndex < _columns.length - 1)
                _buildResizeHandle(columnIndex),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// 크기 조절 핸들
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

  /// 테이블 바디
  Widget _buildTableBody() {
    return Column(
      children: List.generate(_materialList.length, (index) {
        final material = _materialList[index];
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
              final value = column.valueBuilder?.call(material) ?? '';
              final cellWidget = buildTableCell(
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
