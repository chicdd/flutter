import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../models/search_panel.dart';
import '../theme.dart';
import '../models/sales_info.dart';
import '../services/api_service.dart';
import '../services/selected_customer_service.dart';
import '../style.dart';
import '../widgets/component.dart';
import '../widgets/common_table.dart';
import '../functions.dart';
import 'payment_history_table.dart';
import 'visit_as_history_table.dart';

class SalesInfoScreen extends StatefulWidget {
  final SearchPanel? searchpanel;
  const SalesInfoScreen({super.key, this.searchpanel});

  @override
  State<SalesInfoScreen> createState() => SalesInfoScreenState();
}

class SalesInfoScreenState extends State<SalesInfoScreen> {
  final _customerService = SelectedCustomerService();

  // 상세 정보 로딩 상태
  bool _isLoading = false;
  SalesInfo? _salesInfo;
  bool _isErpDbError = false; // ERP DB 연결 오류 상태

  // 페이지 내 검색
  String _pageSearchQuery = '';

  // 탭 선택 상태
  int _selectedTabIndex = 0;

  // TextEditingController들
  final _customerNumberController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _representativeController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _faxNumberController = TextEditingController();
  final _mobilePhoneController = TextEditingController();
  final _customerStatusController = TextEditingController();
  final _paymentMethodController = TextEditingController();
  final _responsibleAreaController = TextEditingController();
  final _salesManagerController = TextEditingController();
  final _businessRegNumberController = TextEditingController();
  final _businessRegNameController = TextEditingController();
  final _businessRepresentativeController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _businessCategoryController = TextEditingController();
  final _invoiceEmailController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _monthlyFeeController = TextEditingController();
  final _vatController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _depositController = TextEditingController();
  final _integratedCountController = TextEditingController();
  final _unpaidMonthsController = TextEditingController();
  final _unpaidAmountController = TextEditingController();

  // 검색 쿼리 업데이트 메서드
  void updateSearchQuery(String query) {
    setState(() {
      _pageSearchQuery = query;
    });
  }

  @override
  void initState() {
    super.initState();

    // ChangeNotifier 리스너 등록
    _customerService.addListener(_onCustomerServiceChanged);

    // 초기 데이터 로드
    _loadSalesInfo();
  }

  @override
  void dispose() {
    _customerService.removeListener(_onCustomerServiceChanged);

    // 모든 컨트롤러 해제
    _customerNumberController.dispose();
    _businessNameController.dispose();
    _representativeController.dispose();
    _businessPhoneController.dispose();
    _faxNumberController.dispose();
    _mobilePhoneController.dispose();
    _customerStatusController.dispose();
    _paymentMethodController.dispose();
    _responsibleAreaController.dispose();
    _salesManagerController.dispose();
    _businessRegNumberController.dispose();
    _businessRegNameController.dispose();
    _businessRepresentativeController.dispose();
    _businessTypeController.dispose();
    _businessCategoryController.dispose();
    _invoiceEmailController.dispose();
    _businessAddressController.dispose();
    _monthlyFeeController.dispose();
    _vatController.dispose();
    _totalAmountController.dispose();
    _depositController.dispose();
    _integratedCountController.dispose();
    _unpaidMonthsController.dispose();
    _unpaidAmountController.dispose();

    super.dispose();
  }

  /// 고객 서비스 변경 시 호출
  void _onCustomerServiceChanged() {
    if (mounted && !_customerService.isLoadingDetail) {
      _loadSalesInfo();
    }
  }

  /// 영업정보 로드
  Future<void> _loadSalesInfo() async {
    final selectedCustomer = _customerService.selectedCustomer;
    final customerDetail = _customerService.customerDetail;

    print('=== 영업정보 로드 시작 ===');
    print('selectedCustomer: ${selectedCustomer?.controlManagementNumber}');
    print('customerDetail: ${customerDetail?.controlManagementNumber}');

    if (selectedCustomer == null && customerDetail == null) {
      print('고객 정보가 없습니다.');
      setState(() {
        _salesInfo = null;
        _isLoading = false;
      });
      return;
    }

    // 영업관리번호가 있으면 영업정보 조회
    String? erpCusNumber;
    if (customerDetail != null) {
      erpCusNumber = customerDetail.erpCusNumber;
    }

    print('영업관리번호(erpCusNumber): "$erpCusNumber"');
    print('영업관리번호 길이: ${erpCusNumber?.length ?? 0}');
    print('영업관리번호 isEmpty: ${erpCusNumber?.isEmpty ?? true}');
    print('영업관리번호 trim 후: "${erpCusNumber?.trim()}"');

    if (erpCusNumber == null || erpCusNumber.trim().isEmpty) {
      print('영업관리번호가 없어서 영업정보를 조회할 수 없습니다.');
      setState(() {
        _salesInfo = null;
        _isLoading = false;
      });
      return;
    }

    // trim하여 사용
    erpCusNumber = erpCusNumber.trim();

    setState(() {
      _isLoading = true;
      _isErpDbError = false; // 로딩 시작 시 에러 상태 초기화
    });

    try {
      final salesInfo = await DatabaseService.getSalesInfo(erpCusNumber);

      if (mounted) {
        setState(() {
          _salesInfo = salesInfo;
          _isLoading = false;
          _isErpDbError = false;
        });
      }
    } catch (e) {
      print('영업정보 로드 오류: $e');
      if (mounted) {
        // ERP DB 연결 오류인지 확인
        if (e.toString().contains('ERP_DB_NOT_CONNECTED')) {
          setState(() {
            _isLoading = false;
            _isErpDbError = true;
            _salesInfo = null;
          });
        } else {
          setState(() {
            _isLoading = false;
            _isErpDbError = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isExtraWideScreen = constraints.maxWidth >= 1920;
          final isWideScreen = constraints.maxWidth >= 1200;
          return
          // _isLoading
          //   ? const Center(child: CircularProgressIndicator())
          //   : _isErpDbError
          //   ? const Center(
          //       child: Text(
          //         '영업DB에 연결되지 않음.\n관리자에게 문의하세요.',
          //         textAlign: TextAlign.center,
          //         style: TextStyle(
          //           fontSize: 16,
          //           color: Colors.red,
          //           fontWeight: FontWeight.w600,
          //         ),
          //       ),
          //     )
          //   : _salesInfo == null
          //   ? const Center(
          //       child: Text(
          //         '영업정보를 불러올 수 없습니다.\n영업관리번호를 확인해주세요.',
          //         textAlign: TextAlign.center,
          //         style: TextStyle(
          //           fontSize: 16,
          //           color: AppTheme.textSecondary,
          //         ),
          //       ),
          //     )
          //   :
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: isExtraWideScreen
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 상단 : 영업정보
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [_buildBasicInfoSection()],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [_buildBusinessInfoSection()],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [_buildMonthlyFeeSection()],
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : isWideScreen
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 상단 : 영업정보
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildBasicInfoSection(),
                                SizedBox(height: 24),
                                _buildMonthlyFeeSection(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [_buildBusinessInfoSection()],
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildBasicInfoSection(),
                      const SizedBox(height: 24),
                      _buildBusinessInfoSection(),
                      const SizedBox(height: 24),
                      _buildMonthlyFeeSection(),
                    ],
                  ),
            // child: Column(
            //   crossAxisAlignment: CrossAxisAlignment.stretch,
            //   children: [
            //     _buildBasicInfoSection(),
            //     const SizedBox(height: 24),
            //     _buildBusinessInfoSection(),
            //     const SizedBox(height: 24),
            //     _buildMonthlyFeeSection(),
            //   ],
            // ),
          );
        },
      ),
    );
  }

  // 기본정보 섹션
  Widget _buildBasicInfoSection() {
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
          buildSectionTitle('기본정보'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CommonTextField(
                  label: '고객번호',
                  controller: TextEditingController(
                    text: _salesInfo?.customerNumber ?? '-',
                  ),
                  searchQuery: _pageSearchQuery,
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '상호명',
                  controller: TextEditingController(
                    text: _salesInfo?.businessName ?? '-',
                  ),
                  searchQuery: _pageSearchQuery,
                  readOnly: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CommonTextField(
                  label: '대표자',
                  controller: TextEditingController(
                    text: _salesInfo?.representative ?? '-',
                  ),
                  searchQuery: _pageSearchQuery,
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '상호전화',
                  controller: TextEditingController(
                    text: _salesInfo?.businessPhone ?? '-',
                  ),
                  searchQuery: _pageSearchQuery,
                  readOnly: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CommonTextField(
                  label: '팩스번호',
                  controller: TextEditingController(
                    text: _salesInfo?.faxNumber ?? '-',
                  ),
                  searchQuery: _pageSearchQuery,
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '휴대전화',
                  controller: TextEditingController(
                    text: _salesInfo?.mobilePhone ?? '-',
                  ),
                  searchQuery: _pageSearchQuery,
                  readOnly: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CommonTextField(
                  label: '고객상태',
                  controller: TextEditingController(
                    text: _salesInfo?.customerStatus ?? '-',
                  ),
                  searchQuery: _pageSearchQuery,
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '납입방법',
                  controller: TextEditingController(
                    text: _salesInfo?.paymentMethod ?? '-',
                  ),
                  searchQuery: _pageSearchQuery,
                  readOnly: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CommonTextField(
                  label: '담당권역',
                  controller: TextEditingController(
                    text: _salesInfo?.responsibleArea ?? '-',
                  ),
                  searchQuery: _pageSearchQuery,
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '신규판매자',
                  controller: TextEditingController(
                    text: _salesInfo?.salesManager ?? '-',
                  ),
                  searchQuery: _pageSearchQuery,
                  readOnly: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 사업자정보 섹션
  Widget _buildBusinessInfoSection() {
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
          buildSectionTitle('사업자정보'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CommonTextField(
                  label: '사업자 등록번호',
                  controller: TextEditingController(
                    text: _salesInfo?.businessRegNumber ?? '-',
                  ),
                  searchQuery: _pageSearchQuery,
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '사업자 상호',
                  controller: TextEditingController(
                    text: _salesInfo?.businessRegName ?? '-',
                  ),
                  searchQuery: _pageSearchQuery,
                  readOnly: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CommonTextField(
                  label: '사업자 대표자',
                  controller: TextEditingController(
                    text: _salesInfo?.businessRepresentative ?? '-',
                  ),
                  searchQuery: _pageSearchQuery,
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '업태',
                  controller: TextEditingController(
                    text: _salesInfo?.businessType ?? '-',
                  ),
                  searchQuery: _pageSearchQuery,
                  readOnly: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CommonTextField(
                  label: '종목',
                  controller: TextEditingController(
                    text: _salesInfo?.businessCategory ?? '-',
                  ),
                  searchQuery: _pageSearchQuery,
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '계산서 이메일',
                  controller: TextEditingController(
                    text: _salesInfo?.invoiceEmail ?? '-',
                  ),
                  searchQuery: _pageSearchQuery,
                  readOnly: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CommonTextField(
            label: '사업장 주소',
            controller: TextEditingController(
              text: _salesInfo?.businessAddress ?? '-',
            ),
            searchQuery: _pageSearchQuery,
            readOnly: true,
          ),
        ],
      ),
    );
  }

  // 월정료 정보 섹션
  Widget _buildMonthlyFeeSection() {
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
          buildSectionTitle('월정료 정보'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CommonTextField(
                  label: '월정료',
                  controller: TextEditingController(
                    text: _formatCurrency(_salesInfo?.monthlyFee),
                  ),
                  searchQuery: _pageSearchQuery,
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: 'VAT',
                  controller: TextEditingController(
                    text: _formatCurrency(_salesInfo?.vat),
                  ),
                  searchQuery: _pageSearchQuery,
                  readOnly: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CommonTextField(
                  label: '총금액',
                  controller: TextEditingController(
                    text: _formatCurrency(_salesInfo?.totalAmount),
                  ),
                  searchQuery: _pageSearchQuery,
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '보증금',
                  controller: TextEditingController(
                    text: _formatCurrency(_salesInfo?.deposit),
                  ),
                  searchQuery: _pageSearchQuery,
                  readOnly: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CommonTextField(
                  label: '통합관리건수',
                  controller: TextEditingController(
                    text: _salesInfo?.integratedCount.toString() ?? '0',
                  ),
                  searchQuery: _pageSearchQuery,
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '미납월분',
                  controller: TextEditingController(
                    text: _salesInfo?.unpaidMonths?.toString() ?? '-',
                  ),
                  searchQuery: _pageSearchQuery,
                  readOnly: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CommonTextField(
            label: '미납총금액',
            controller: TextEditingController(
              text: _formatCurrency(_salesInfo?.unpaidAmount),
            ),
            searchQuery: _pageSearchQuery,
            readOnly: true,
          ),
        ],
      ),
    );
  }

  /// 금액 포맷팅
  String _formatCurrency(double? amount) {
    if (amount == null) return '-';
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';
  }
}
