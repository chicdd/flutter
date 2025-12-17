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
    // 초기 데이터 로드
    _initializeData();
  }

  @override
  void dispose() {
    // 공통 리스너 해제
    disposeCustomerServiceListener();
    _searchController.dispose();
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
    return CommonDataTable(
      title: '설치자재현황',
      columns: [
        TableColumnConfig(
          header: '자재명칭',
          flex: 2,
          valueBuilder: (data) => data['자재명칭']?.toString() ?? '-',
        ),
        TableColumnConfig(
          header: '설치수량',
          flex: 1,
          valueBuilder: (data) => data['설치수량']?.toString() ?? '-',
        ),
        TableColumnConfig(
          header: '자재코드',
          flex: 1,
          valueBuilder: (data) => data['자재코드']?.toString() ?? '-',
        ),
        TableColumnConfig(
          header: '자재년식',
          flex: 1,
          valueBuilder: (data) => data['자재년식']?.toString() ?? '-',
        ),
        TableColumnConfig(
          header: '대분류',
          flex: 2,
          valueBuilder: (data) => data['대분류']?.toString() ?? '-',
        ),
        TableColumnConfig(
          header: '중분류',
          flex: 2,
          valueBuilder: (data) => data['중분류']?.toString() ?? '-',
        ),
      ],
      data: _materialList,
      emptyMessage: '설치자재현황 데이터가 없습니다.',
    );
  }
}
