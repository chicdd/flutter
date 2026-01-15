import 'package:flutter/material.dart';
import '../models/search_panel.dart';
import '../models/customer_detail.dart';
import '../functions.dart';
import '../widgets/common_table.dart';

/// 테이블 화면의 공통 기능을 제공하는 추상 클래스
///
/// 사용 방법:
/// ```dart
/// class MyScreen extends BaseTableScreen<MyDataModel> {
///   const MyScreen({super.key, super.searchpanel});
///
///   @override
///   State<MyScreen> createState() => _MyScreenState();
/// }
///
/// class _MyScreenState extends BaseTableScreenState<MyDataModel, MyScreen> {
///   @override
///   String get tableTitle => '내 테이블';
///
///   @override
///   Future<List<MyDataModel>> loadDataFromApi(String key) async {
///     return await DatabaseService.getMyData(key);
///   }
///
///   @override
///   List<TableColumnConfig> buildColumns() {
///     return [
///       TableColumnConfig(
///         header: '컬럼명',
///         width: columnWidths[0],
///         valueBuilder: (data) => data.field ?? '',
///       ),
///     ];
///   }
///
///   @override
///   Map<int, double> get initialColumnWidths => {
///     0: 150.0,
///   };
/// }
/// ```
abstract class BaseTableScreen<T> extends StatefulWidget {
  final SearchPanel? searchpanel;

  const BaseTableScreen({super.key, this.searchpanel});
}

/// 테이블 화면의 공통 State를 제공하는 추상 클래스
///
/// [T]: 테이블에 표시할 데이터 모델 타입
/// [W]: 위젯 타입 (BaseTableScreen<T>를 상속한 위젯)
abstract class BaseTableScreenState<T, W extends BaseTableScreen<T>>
    extends State<W>
    with CustomerServiceHandler, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _isloading = true;

  /// 데이터 목록
  List<T> _dataList = [];
  List<T> get dataList => _dataList;

  /// 페이지 내 검색 쿼리
  String _pageSearchQuery = '';
  String get pageSearchQuery => _pageSearchQuery;

  /// 테이블 열 너비
  late final Map<int, double> _columnWidths;
  Map<int, double> get columnWidths => _columnWidths;

  /// 테이블 컬럼 설정
  late final List<TableColumnConfig> _columns;

  /// 스크롤 컨트롤러 (필요한 경우 오버라이드)
  ScrollController? _scrollController;
  ScrollController? get scrollController => _scrollController;

  // ========================================
  // 추상 메서드 (서브클래스에서 구현 필수)
  // ========================================

  /// 테이블 제목
  String get tableTitle;

  /// API에서 데이터를 로드하는 메서드
  ///
  /// [key]: 관제관리번호 또는 ERP고객번호 등 데이터를 가져올 키
  Future<List<T>> loadDataFromApi(String key);

  /// 테이블 컬럼 구성
  List<TableColumnConfig> buildColumns();

  /// 초기 컬럼 너비 설정
  Map<int, double> get initialColumnWidths;

  // ========================================
  // 선택적 오버라이드 메서드
  // ========================================

  /// 고객 정보에서 데이터 로드 키를 추출
  ///
  /// 기본값: controlManagementNumber 사용
  /// erpCusNumber를 사용하는 화면은 오버라이드 필요
  String? getDataKeyFromCustomer(
    SearchPanel? customer,
    CustomerDetail? detail,
  ) {
    return customer?.controlManagementNumber;
  }

  /// 추가 버튼 표시 여부
  bool get showAddButton => false;

  /// 추가 버튼 클릭 시 동작
  void onAddButtonPressed() {}

  /// 스크롤 컨트롤러 사용 여부
  bool get useScrollController => false;

  /// 데이터 로드 완료 후 추가 처리
  void onDataLoaded(List<T> data) {}

  /// 데이터 로드 에러 처리
  void onDataLoadError(dynamic error) {
    print('데이터 로드 오류: $error');
  }

  // ========================================
  // 공통 라이프사이클 메서드
  // ========================================

  @override
  void initState() {
    super.initState();
    _columnWidths = Map<int, double>.from(initialColumnWidths);
    _columns = buildColumns();

    if (useScrollController) {
      _scrollController = ScrollController();
    }

    initCustomerServiceListener();
    _initializeData();
  }

  @override
  void dispose() {
    disposeCustomerServiceListener();
    _scrollController?.dispose();
    super.dispose();
  }

  // ========================================
  // 공통 데이터 로딩 로직
  // ========================================

  /// 초기 데이터 로드
  Future<void> _initializeData() async {
    await _loadCustomerDataFromService();
  }

  /// 전역 서비스에서 고객 데이터 로드
  Future<void> _loadCustomerDataFromService() async {
    final customer = customerService.selectedCustomer;
    final detail = customerService.customerDetail;

    final key = getDataKeyFromCustomer(customer, detail);

    if (key != null && key.isNotEmpty) {
      await _loadData(key);
    } else {
      _clearData();
    }
  }

  /// CustomerServiceHandler 콜백 구현
  @override
  void onCustomerChanged(SearchPanel? customer, CustomerDetail? detail) {
    final key = getDataKeyFromCustomer(customer, detail);

    if (key != null && key.isNotEmpty) {
      _loadData(key);
    } else {
      _clearData();
    }
  }

  /// 데이터 로드
  Future<void> _loadData(String key) async {
    setState(() {
      _dataList.clear();
      _isloading = true;
    });

    try {
      final data = await loadDataFromApi(key);

      if (mounted) {
        setState(() {
          _dataList = data;
          _isloading = false;
        });

        onDataLoaded(data);
      }

      print('$tableTitle 데이터 로드 완료: ${data.length}건');
    } catch (e) {
      onDataLoadError(e);

      if (mounted) {
        setState(() {
          _dataList = [];
          _isloading = false;
        });
      }
    }
  }

  /// 데이터 초기화
  void _clearData() {
    if (mounted) {
      setState(() {
        _dataList = [];
      });
    }
  }

  /// 데이터 새로고침 (외부에서 호출 가능)
  Future<void> refreshData() async {
    await _loadCustomerDataFromService();
  }

  // ========================================
  // 공통 UI 업데이트 메서드
  // ========================================

  /// 검색 쿼리 업데이트
  void updateSearchQuery(String query) {
    setState(() {
      _pageSearchQuery = query;
    });
  }

  /// 컬럼 너비 업데이트
  void onColumnResize(int columnIndex, double newWidth) {
    setState(() {
      _columnWidths[columnIndex] = newWidth;
    });
  }

  // ========================================
  // 공통 빌드 메서드
  // ========================================

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 상단 추가 위젯 (필요한 경우 오버라이드)
            ...buildHeaderWidgets(),

            // 테이블 영역
            Expanded(
              child: buildTable(
                context: context,
                title: tableTitle,
                dataList: _dataList,
                columns: _columns,
                columnWidths: _columnWidths,
                onColumnResize: onColumnResize,
                searchQuery: _pageSearchQuery,
                onAdd: showAddButton ? onAddButtonPressed : null,
                isLoading: _isloading,
              ),
            ),

            // 하단 추가 위젯 (필요한 경우 오버라이드)
            ...buildFooterWidgets(),
          ],
        ),
      ),
    );
  }

  /// 상단 추가 위젯 (필요한 경우 오버라이드)
  List<Widget> buildHeaderWidgets() {
    return [];
  }

  /// 하단 추가 위젯 (필요한 경우 오버라이드)
  List<Widget> buildFooterWidgets() {
    return [];
  }
}
