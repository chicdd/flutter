import 'dart:ui';

import 'package:flutter/material.dart';
import '../models/AuthRegist.dart';
import '../models/search_panel.dart';
import '../models/customer_detail.dart';
import '../services/api_service.dart';
import '../functions.dart';
import '../style.dart';
import '../theme.dart';
import '../widgets/component.dart';
import '../widgets/custom_top_bar.dart';
import '../widgets/common_table.dart';

/// 스마트폰 어플 인증 등록 화면
class SmartphoneAppAuthRegistration extends StatefulWidget {
  final SearchPanel? searchpanel;
  const SmartphoneAppAuthRegistration({super.key, this.searchpanel});

  @override
  State<SmartphoneAppAuthRegistration> createState() =>
      SmartphoneAppAuthRegistrationState();
}

class SmartphoneAppAuthRegistrationState
    extends State<SmartphoneAppAuthRegistration>
    with CustomerServiceHandler {
  // 검색 컨트롤러
  final TextEditingController _searchController = TextEditingController();

  // 스마트폰 인증 데이터 목록
  List<AuthRegist> _authPhoneNumber = [];

  // 페이지 내 검색
  String _pageSearchQuery = '';

  // 테이블 관련 변수
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _bodyScrollController = ScrollController();
  bool _isSyncingScroll = false;
  final Map<int, double> _columnWidths = {
    0: 150.0, // 휴대폰번호
    1: 120.0, // 사용자이름
    2: 130.0, // 원격경계여부
    3: 130.0, // 원격해제여부
    4: 120.0, // 등록일자
    5: 200.0, // 상호명
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
        header: '휴대폰번호',
        width: _columnWidths[0],
        valueBuilder: (data) => data.phoneNumber ?? '-',
      ),
      TableColumnConfig(
        header: '사용자이름',
        width: _columnWidths[1],
        valueBuilder: (data) => data.userName ?? '-',
      ),
      TableColumnConfig(
        header: '원격경계여부',
        width: _columnWidths[2],
        valueBuilder: (data) => data.armaStatusText,
      ),
      TableColumnConfig(
        header: '원격해제여부',
        width: _columnWidths[3],
        valueBuilder: (data) => data.disarmaStatusText,
      ),
      TableColumnConfig(
        header: '등록일자',
        width: _columnWidths[4],
        valueBuilder: (data) => data.registrationDate ?? '-',
      ),
      TableColumnConfig(
        header: '상호명',
        width: _columnWidths[5],
        valueBuilder: (data) => data.customerName ?? '-',
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
      await _loadSmartphoneAuthData(customer.controlManagementNumber);
    } else {
      setState(() {
        _authPhoneNumber = [];
      });
    }
  }

  /// CustomerServiceHandler 콜백 구현
  @override
  void onCustomerChanged(SearchPanel? customer, CustomerDetail? detail) {
    if (customer != null) {
      _loadSmartphoneAuthData(customer.controlManagementNumber);
    } else {
      setState(() {
        _authPhoneNumber = [];
      });
    }
  }

  /// 스마트폰 인증 데이터 로드
  Future<void> _loadSmartphoneAuthData(String managementNumber) async {
    try {
      final authList = await DatabaseService.getSmartphoneAuthInfo(
        managementNumber,
      );

      if (mounted) {
        setState(() {
          _authPhoneNumber = authList;
        });
      }

      print('스마트폰 인증 데이터 로드 완료: ${authList.length}개');
    } catch (e) {
      print('스마트폰 인증 데이터 로드 오류: $e');
      if (mounted) {
        setState(() {
          _authPhoneNumber = [];
        });
      }
    }
  }

  /// 인증 고객 정보 입력 모달 표시
  void _showAddAuthModal() {
    final detail = customerService.customerDetail;
    if (detail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('고객 정보를 불러올 수 없습니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _AddAuthModal(customerDetail: detail),
    );
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
          Row(
            children: [
              const Text(
                '인증 허용 전화번호',
                style: TextStyle(
                  color: Color(0xFF252525),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _showAddAuthModal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '추가',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _authPhoneNumber.isEmpty
                ? const Center(
                    child: Text(
                      '스마트폰 인증 데이터가 없습니다.',
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
      children: List.generate(_authPhoneNumber.length, (index) {
        final auth = _authPhoneNumber[index];
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
              final value = column.valueBuilder?.call(auth) ?? '';
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

/// 인증 고객 정보 입력 모달
class _AddAuthModal extends StatefulWidget {
  final CustomerDetail customerDetail;

  const _AddAuthModal({Key? key, required this.customerDetail})
    : super(key: key);

  @override
  State<_AddAuthModal> createState() => _AddAuthModalState();
}

class _AddAuthModalState extends State<_AddAuthModal> {
  // 폼 컨트롤러
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _managementNumberController =
      TextEditingController();
  final TextEditingController _businessNumberController =
      TextEditingController();
  final TextEditingController _authPhoneController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();

  // 체크박스 상태
  bool _remoteGuardAllowed = false;
  bool _remoteReleaseAllowed = false;

  @override
  void initState() {
    super.initState();
    // CustomerDetail의 값을 컨트롤러에 설정
    _companyController.text = widget.customerDetail.controlBusinessName ?? '';
    _managementNumberController.text =
        widget.customerDetail.controlManagementNumber ?? '';
    _businessNumberController.text = widget.customerDetail.erpCusNumber ?? '';
  }

  /// 인증 정보 등록
  Future<void> _registerAuth(BuildContext context) async {
    // 유효성 검사
    final phoneNumber = _authPhoneController.text.trim();
    final userName = _userNameController.text.trim();

    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('휴대폰번호를 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (userName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('사용자 이름을 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // API 호출
      final success = await CodeDataCache.insertAuth(
        phoneNumber: phoneNumber,
        controlManagementNumber:
            widget.customerDetail.controlManagementNumber ?? '',
        erpCusNumber: widget.customerDetail.erpCusNumber ?? '',
        businessName: widget.customerDetail.controlBusinessName ?? '',
        userName: userName,
        remoteGuardAllowed: _remoteGuardAllowed,
        remoteReleaseAllowed: _remoteReleaseAllowed,
      );

      // 로딩 닫기
      if (mounted) Navigator.of(context).pop();

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('인증 정보가 등록되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // 모달 닫기
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('인증 정보 등록에 실패했습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // 로딩 닫기
      if (mounted) Navigator.of(context).pop();

      print('인증 정보 등록 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('인증 정보 등록 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _companyController.dispose();
    _managementNumberController.dispose();
    _businessNumberController.dispose();
    _authPhoneController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 모달 제목
            const Text(
              '인증 고객 정보 입력',
              style: TextStyle(
                color: Color(0xFF252525),
                fontSize: 18,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            // 폼 필드들
            CommonTextField(
              label: '관제상호명',
              controller: _companyController,
              readOnly: true,
            ),
            const SizedBox(height: 12),
            CommonTextField(
              label: '관제 관리번호',
              controller: _managementNumberController,
              readOnly: true,
            ),
            const SizedBox(height: 12),
            CommonTextField(
              label: '영업 관리번호',
              controller: _businessNumberController,
              readOnly: true,
            ),
            const SizedBox(height: 12),
            CommonTextField(
              label: '인증 휴대전화번호',
              controller: _authPhoneController,
            ),
            const SizedBox(height: 12),
            CommonTextField(label: '사용자 이름', controller: _userNameController),
            const SizedBox(height: 16),
            // 체크박스
            Row(
              children: [
                buildCheckbox('원격경계허용', _remoteGuardAllowed, (value) {
                  setState(() {
                    _remoteGuardAllowed = value ?? false;
                  });
                }),
                const SizedBox(width: 20),
                buildCheckbox('원격해제허용', _remoteReleaseAllowed, (value) {
                  setState(() {
                    _remoteReleaseAllowed = value ?? false;
                  });
                }),
              ],
            ),
            const SizedBox(height: 24),
            // 등록 버튼
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () async {
                  await _registerAuth(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '스마트폰 사용 인증 등록',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
