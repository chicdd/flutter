import 'package:flutter/material.dart';
import '../models/AuthRegist.dart';
import '../models/search_panel.dart';
import '../models/customer_detail.dart';
import '../services/api_service.dart';
import '../functions.dart';
import '../theme.dart';
import '../style.dart';
import '../widgets/custom_top_bar.dart';
import '../config/topbar_config.dart';

/// 스마트폰 어플 인증 등록 화면
class SmartphoneAppAuthRegistration extends StatefulWidget {
  final SearchPanel? searchpanel;
  const SmartphoneAppAuthRegistration({super.key, this.searchpanel});

  @override
  State<SmartphoneAppAuthRegistration> createState() =>
      _SmartphoneAppAuthRegistrationState();
}

class _SmartphoneAppAuthRegistrationState
    extends State<SmartphoneAppAuthRegistration>
    with CustomerServiceHandler {
  // 검색 컨트롤러
  final TextEditingController _searchController = TextEditingController();

  // 스마트폰 인증 데이터 목록
  List<AuthRegist> _authPhoneNumber = [];

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
    showDialog(context: context, builder: (context) => _AddAuthModal());
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
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              // 추가 버튼
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 테이블 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '휴대폰번호',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF252525),
                      fontSize: 15,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '사용자이름',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF252525),
                      fontSize: 15,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '원격경계여부',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF252525),
                      fontSize: 15,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '등록일자',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF252525),
                      fontSize: 15,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '상호명',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF252525),
                      fontSize: 15,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 테이블 내용 (실제 데이터)
          if (_authPhoneNumber.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFE5E5E5), width: 0.5),
                ),
              ),
              child: Center(
                child: Text(
                  '스마트폰 인증 데이터가 없습니다.',
                  style: const TextStyle(
                    color: Color(0xFF8D8D8D),
                    fontSize: 15,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            )
          else
            ..._authPhoneNumber.asMap().entries.map((entry) {
              final index = entry.key;
              final authRegist = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: index % 2 == 0
                      ? const Color(0xFFF5F5F5)
                      : const Color(0xFFFFFFFF),
                  border: const Border(
                    bottom: BorderSide(color: Color(0xFFE5E5E5), width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        authRegist.phoneNumber ?? '-',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF252525),
                          fontSize: 15,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        authRegist.userName ?? '-',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF252525),
                          fontSize: 15,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        authRegist.armaStatusText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF252525),
                          fontSize: 15,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        authRegist.registrationDate ?? '-',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF252525),
                          fontSize: 15,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        authRegist.customerName ?? '-',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF252525),
                          fontSize: 15,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// 인증 고객 정보 입력 모달
class _AddAuthModal extends StatefulWidget {
  const _AddAuthModal({Key? key}) : super(key: key);

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
            _buildTextField('관제상호명', _companyController),
            const SizedBox(height: 12),
            _buildTextField('관제 관리번호', _managementNumberController),
            const SizedBox(height: 12),
            _buildTextField('영업 관리번호', _businessNumberController),
            const SizedBox(height: 12),
            _buildTextField('인증 휴대전화번호', _authPhoneController),
            const SizedBox(height: 12),
            _buildTextField('사용자 이름', _userNameController),
            const SizedBox(height: 16),
            // 체크박스
            Row(
              children: [
                _buildCheckbox('원격경계허용', _remoteGuardAllowed, (value) {
                  setState(() {
                    _remoteGuardAllowed = value ?? false;
                  });
                }),
                const SizedBox(width: 20),
                _buildCheckbox('원격해제허용', _remoteReleaseAllowed, (value) {
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
                onPressed: () {
                  // TODO: 인증 정보 등록 API 호출
                  Navigator.of(context).pop();
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

  /// 텍스트 필드 빌더
  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            style: const TextStyle(fontSize: 14, color: Color(0xFF252525)),
          ),
        ),
      ],
    );
  }

  /// 체크박스 빌더
  Widget _buildCheckbox(String label, bool value, Function(bool?) onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF007AFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF252525),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
