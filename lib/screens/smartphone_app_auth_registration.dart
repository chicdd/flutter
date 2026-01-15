import 'package:flutter/material.dart';
import '../models/AuthRegist.dart';
import '../models/customer_detail.dart';
import '../services/api_service.dart';
import '../functions.dart';
import '../style.dart';
import '../theme.dart';

import '../widgets/common_table.dart';
import '../widgets/base_add_modal.dart';
import 'base_table_screen.dart';

/// 스마트폰 어플 인증 등록 화면
class SmartphoneAppAuthRegistration extends BaseTableScreen<AuthRegist> {
  const SmartphoneAppAuthRegistration({super.key, super.searchpanel});

  @override
  State<SmartphoneAppAuthRegistration> createState() =>
      SmartphoneAppAuthRegistrationState();
}

class SmartphoneAppAuthRegistrationState
    extends BaseTableScreenState<AuthRegist, SmartphoneAppAuthRegistration> {
  @override
  String get tableTitle => '인증 허용 전화번호';

  @override
  bool get showAddButton => true;

  @override
  Map<int, double> get initialColumnWidths => {
    0: 150.0, // 휴대폰번호
    1: 120.0, // 사용자이름
    2: 130.0, // 원격경계여부
    3: 130.0, // 원격해제여부
    4: 120.0, // 등록일자
    5: 200.0, // 상호명
  };

  @override
  Future<List<AuthRegist>> loadDataFromApi(String key) async {
    return await DatabaseService.getSmartphoneAuthInfo(key);
  }

  @override
  List<TableColumnConfig> buildColumns() {
    return [
      TableColumnConfig(
        header: '휴대폰번호',
        width: columnWidths[0],
        valueBuilder: (data) => (data as AuthRegist).phoneNumber ?? '-',
      ),
      TableColumnConfig(
        header: '사용자이름',
        width: columnWidths[1],
        valueBuilder: (data) => (data as AuthRegist).userName ?? '-',
      ),
      TableColumnConfig(
        header: '원격경계여부',
        width: columnWidths[2],
        valueBuilder: (data) => (data as AuthRegist).armaStatusText,
      ),
      TableColumnConfig(
        header: '원격해제여부',
        width: columnWidths[3],
        valueBuilder: (data) => (data as AuthRegist).disarmaStatusText,
      ),
      TableColumnConfig(
        header: '등록일자',
        width: columnWidths[4],
        valueBuilder: (data) => (data as AuthRegist).registrationDate ?? '-',
      ),
      TableColumnConfig(
        header: '상호명',
        width: columnWidths[5],
        valueBuilder: (data) => (data as AuthRegist).customerName ?? '-',
      ),
    ];
  }

  @override
  void onAddButtonPressed() {
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
      builder: (context) => _AddAuthModal(
        customerDetail: detail,
        onSaved: () {
          refreshData();
        },
      ),
    );
  }
}

/// 인증 고객 정보 입력 모달
class _AddAuthModal extends BaseAddModal {
  final CustomerDetail customerDetail;

  const _AddAuthModal({
    super.key,
    required this.customerDetail,
    required super.onSaved,
  });

  @override
  State<_AddAuthModal> createState() => _AddAuthModalState();
}

class _AddAuthModalState extends BaseAddModalState<_AddAuthModal> {
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
  String get modalTitle => '인증 고객 정보 입력';

  @override
  String get saveButtonLabel => '스마트폰 사용 인증 등록';

  @override
  double get modalWidth => 400.0;

  @override
  void initState() {
    super.initState();
    // CustomerDetail의 값을 컨트롤러에 설정
    _companyController.text = widget.customerDetail.controlBusinessName ?? '';
    _managementNumberController.text =
        widget.customerDetail.controlManagementNumber ?? '';
    _businessNumberController.text = widget.customerDetail.erpCusNumber ?? '';
  }

  @override
  Future<bool> validateAndSave() async {
    // 검증
    final phoneNumber = _authPhoneController.text.trim();
    final userName = _userNameController.text.trim();

    if (phoneNumber.isEmpty) {
      showErrorSnackBar('휴대폰번호를 입력해주세요.');
      return false;
    }

    if (userName.isEmpty) {
      showErrorSnackBar('사용자 이름을 입력해주세요.');
      return false;
    }

    // API 호출
    return await CodeDataCache.insertAuth(
      phoneNumber: phoneNumber,
      controlManagementNumber:
          widget.customerDetail.controlManagementNumber ?? '',
      erpCusNumber: widget.customerDetail.erpCusNumber ?? '',
      businessName: widget.customerDetail.controlBusinessName ?? '',
      userName: userName,
      remoteGuardAllowed: _remoteGuardAllowed,
      remoteReleaseAllowed: _remoteReleaseAllowed,
    );
  }

  @override
  String get successMessage => '인증 정보가 등록되었습니다.';

  @override
  String get failureMessage => '인증 정보 등록에 실패했습니다.';

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
  Widget buildFormFields() {
    return Column(
      children: [
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
        CommonTextField(label: '인증 휴대전화번호', controller: _authPhoneController),
        const SizedBox(height: 12),
        CommonTextField(label: '사용자 이름', controller: _userNameController),
        const SizedBox(height: 16),
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
      ],
    );
  }
}
