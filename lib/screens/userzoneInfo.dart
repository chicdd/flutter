import 'package:flutter/material.dart';
import '../models/search_panel.dart';
import '../models/customer_detail.dart';
import '../models/userZone.dart';
import '../services/api_service.dart';
import '../functions.dart';
import '../style.dart';
import '../theme.dart';
import '../widgets/common_table.dart';

/// 사용자존정보 화면
class UserZoneInfoScreen extends StatefulWidget {
  final SearchPanel? searchpanel;
  const UserZoneInfoScreen({super.key, this.searchpanel});

  @override
  State<UserZoneInfoScreen> createState() => UserZoneInfoState();
}

class UserZoneInfoState extends State<UserZoneInfoScreen>
    with CustomerServiceHandler {
  // 검색 컨트롤러
  final TextEditingController _searchController = TextEditingController();

  // 현재 로드된 고객의 관제관리번호 (중복 API 호출 방지)
  String? _loadedCustomerManagementNumber;

  // 사용자 관리 데이터 목록
  List<UserZoneInfo> _userInfoList = [];

  // 존정보 관리 데이터 목록
  List<ZoneInfo> _zoneInfoList = [];

  // 페이지 내 검색
  String _pageSearchQuery = '';

  // 테이블 컬럼 너비 설정
  final Map<int, double> _userColumnWidths = {
    0: 80.0, // 순번
    1: 120.0, // 사용자명
    2: 100.0, // 관계
    3: 130.0, // 휴대전화
    4: 130.0, // 자택전화
    5: 140.0, // 주민번호
    6: 120.0, // 사용자
    7: 150.0, // 비고
    8: 100.0, // 무단허용
    9: 80.0, // SMS
    10: 80.0, // 요원
    11: 80.0, // APP
    12: 80.0, // 예비
  };

  late List<TableColumnConfig> userColumns = [
    TableColumnConfig(
      header: '순번',
      width: _userColumnWidths[0],
      valueBuilder: (data) => data.registrationNumber ?? '-',
    ),
    TableColumnConfig(
      header: '사용자명',
      width: _userColumnWidths[1],
      valueBuilder: (data) => data.userName ?? '-',
    ),
    TableColumnConfig(
      header: '관계',
      width: _userColumnWidths[2],
      valueBuilder: (data) => data.position ?? '-',
    ),
    TableColumnConfig(
      header: '휴대전화',
      width: _userColumnWidths[3],
      valueBuilder: (data) => data.phoneNumber ?? '-',
    ),
    TableColumnConfig(
      header: '자택전화',
      width: _userColumnWidths[4],
      valueBuilder: (data) => data.relationWithContractor ?? '-',
    ),
    TableColumnConfig(
      header: '주민번호',
      width: _userColumnWidths[5],
      valueBuilder: (data) => data.residentNumber ?? '-',
    ),
    TableColumnConfig(
      header: '사용자',
      width: _userColumnWidths[5],
      valueBuilder: (data) => data.ocUser ?? '-',
    ),
    TableColumnConfig(
      header: '비고',
      width: _userColumnWidths[5],
      valueBuilder: (data) => data.note ?? '-',
    ),
    TableColumnConfig(
      header: '무단허용',
      width: _userColumnWidths[5],
      valueBuilder: (data) =>
          (data.unauthorizedReleaseAllowed ?? false) ? 'O' : '',
    ),
    TableColumnConfig(
      header: 'SMS',
      width: _userColumnWidths[5],
      valueBuilder: (data) => (data.smsSent ?? false) ? 'O' : '',
    ),
    TableColumnConfig(
      header: '요원',
      width: _userColumnWidths[5],
      valueBuilder: (data) => (data.agentCard ?? false) ? 'O' : '',
    ),
    TableColumnConfig(
      header: 'APP',
      width: _userColumnWidths[5],
      valueBuilder: (data) => (data.unattendedSms ?? false) ? 'O' : '',
    ),
    TableColumnConfig(
      header: '에비',
      width: _userColumnWidths[5],
      valueBuilder: (data) => (data.reserveCard ?? false) ? 'O' : '',
    ),
  ];
  // 존정보 테이블 컬럼 설정
  late List<TableColumnConfig> zoneColumns = [
    TableColumnConfig(
      header: '존번호',
      width: _zoneColumnWidths[0],
      valueBuilder: (data) => data.zoneNumber ?? '-',
    ),
    TableColumnConfig(
      header: '감지기설치위치',
      width: _zoneColumnWidths[1],
      valueBuilder: (data) => data.detectorInstallLocation ?? '-',
    ),
    TableColumnConfig(
      header: '감지기명',
      width: _zoneColumnWidths[2],
      valueBuilder: (data) => data.detectorName ?? '-',
    ),
    TableColumnConfig(
      header: '비고',
      width: _zoneColumnWidths[3],
      valueBuilder: (data) => data.note ?? '-',
    ),
  ];
  // 존정보 테이블 컬럼 너비 설정
  final Map<int, double> _zoneColumnWidths = {
    0: 100.0, // 존번호
    1: 250.0, // 감지기설치위치
    2: 150.0, // 감지기명
    3: 250.0, // 비고
  };

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
      _loadedCustomerManagementNumber = customer.controlManagementNumber;
      await _loadUserZoneData(customer.controlManagementNumber);
    } else {
      setState(() {
        _userInfoList = [];
        _zoneInfoList = [];
      });
    }
  }

  /// CustomerServiceHandler 콜백 구현
  @override
  void onCustomerChanged(SearchPanel? customer, CustomerDetail? detail) {
    final currentCustomerNumber = customer?.controlManagementNumber;

    // 고객이 변경된 경우에만 API 호출
    if (currentCustomerNumber != _loadedCustomerManagementNumber) {
      _loadedCustomerManagementNumber = currentCustomerNumber;

      if (customer != null) {
        _loadUserZoneData(customer.controlManagementNumber);
      } else {
        setState(() {
          _userInfoList = [];
          _zoneInfoList = [];
        });
      }
    }
  }

  /// 사용자 및 존정보 데이터 로드
  Future<void> _loadUserZoneData(String managementNumber) async {
    try {
      final userList = await DatabaseService.getUserInfo(managementNumber);
      final zoneList = await DatabaseService.getZoneInfo(managementNumber);

      if (mounted) {
        setState(() {
          _userInfoList = userList;
          _zoneInfoList = zoneList;
        });
      }

      print('사용자존정보 데이터 로드 완료: 사용자=${userList.length}, 존정보=${zoneList.length}');
    } catch (e) {
      print('사용자존정보 데이터 로드 오류: $e');
      if (mounted) {
        setState(() {
          _userInfoList = [];
          _zoneInfoList = [];
        });
      }
    }
  }

  /// 사용자 정보 추가 모달 표시
  void showAddUserModal() {
    final customer = customerService.selectedCustomer;
    if (customer == null) {
      showToast(context, message: '고객을 먼저 선택해주세요.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _AddUserModal(
        controlManagementNumber: customer.controlManagementNumber,
      ),
    );
  }

  /// 존정보 추가 모달 표시
  void showAddZoneModal() {
    final customer = customerService.selectedCustomer;
    if (customer == null) {
      showToast(context, message: '고객을 먼저 선택해주세요.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _AddZoneModal(
        controlManagementNumber: customer.controlManagementNumber,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 상단바
            // 메인 컨텐츠
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 사용자 관리 테이블
                  Expanded(
                    flex: 1,
                    child: buildTable(
                      context: context,
                      title: '사용자 관리',
                      dataList: _userInfoList,
                      columns: userColumns,
                      columnWidths: _userColumnWidths,
                      onColumnResize: (columnIndex, newWidth) {
                        setState(() {
                          _userColumnWidths[columnIndex] = newWidth;
                        });
                      },
                      searchQuery: _pageSearchQuery,
                      showTotalCount: true,
                      onAdd: showAddUserModal,
                    ),
                  ),
                  SizedBox(height: 24),

                  // 존정보 관리 테이블
                  Expanded(
                    flex: 1,
                    child: buildTable(
                      context: context,
                      title: '존정보 관리',
                      dataList: _zoneInfoList,
                      columns: zoneColumns,
                      columnWidths: _zoneColumnWidths,
                      onColumnResize: (columnIndex, newWidth) {
                        setState(() {
                          _zoneColumnWidths[columnIndex] = newWidth;
                        });
                      },
                      searchQuery: _pageSearchQuery,
                      showTotalCount: true,
                      onAdd: showAddZoneModal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 사용자 정보 추가 모달
class _AddUserModal extends StatefulWidget {
  final String controlManagementNumber;

  const _AddUserModal({required this.controlManagementNumber});

  @override
  State<_AddUserModal> createState() => _AddUserModalState();
}

class _AddUserModalState extends State<_AddUserModal> {
  // 폼 컨트롤러
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _relationController = TextEditingController();
  final TextEditingController _phoneNumController = TextEditingController();
  final TextEditingController _homePhoneNumController = TextEditingController();
  final TextEditingController _regIdController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _etcController = TextEditingController();

  // 체크박스 상태
  bool _unauthorized = false;
  bool _sms = false;
  bool _agent = false;
  bool _app = false;
  bool _preparation = false;

  /// 사용자 정보 등록
  Future<void> _registerUser(BuildContext context) async {
    // 유효성 검사
    final userName = _userNameController.text.trim();

    if (userName.isEmpty) {
      showToast(context, message: '사용자 이름을 입력해주세요.');
      return;
    }

    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // TODO: API 호출 (api_service.dart에 추가)
      // final success = await DatabaseService.insertUserInfo(
      //   managementNumber: widget.customerDetail.controlManagementNumber ?? '',
      //   userName: userName,
      //   관계: _relationController.text.trim(),
      //   휴대전화: _phoneNumController.text.trim(),
      //   자택전화: _homePhoneNumController.text.trim(),
      //   주민번호: _regIdController.text.trim(),
      //   사용자: _userController.text.trim(),
      //   비고: _etcController.text.trim(),
      //   unauthorized: _무단허용,
      //   sms: _sms,
      //   agent: _요원,
      //   app: _app,
      //   preparation: _예비,
      // );

      // 임시로 성공 처리
      final success = true;

      // 로딩 닫기
      if (mounted) Navigator.of(context).pop();

      if (success) {
        if (mounted) {
          showToast(context, message: '사용자 정보가 등록되었습니다.');
          Navigator.of(context).pop(); // 모달 닫기
        }
      }
    } catch (e) {
      // 로딩 닫기
      if (mounted) Navigator.of(context).pop();

      print('사용자 정보 등록 오류: $e');
      if (mounted) {
        showToast(context, message: '사용자 정보 등록 중 오류가 발생했습니다: $e');
      }
    }
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _relationController.dispose();
    _phoneNumController.dispose();
    _homePhoneNumController.dispose();
    _regIdController.dispose();
    _userController.dispose();
    _etcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: context.colors.cardBackground,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 모달 제목
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '사용자 정보 입력',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 18,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 폼 필드들
              CommonTextField(label: '사용자명', controller: _userNameController),
              const SizedBox(height: 12),
              CommonTextField(label: '관계', controller: _relationController),
              const SizedBox(height: 12),
              CommonTextField(label: '휴대전화', controller: _phoneNumController),
              const SizedBox(height: 12),
              CommonTextField(
                label: '자택전화',
                controller: _homePhoneNumController,
              ),
              const SizedBox(height: 12),
              CommonTextField(label: '주민번호', controller: _regIdController),
              const SizedBox(height: 12),
              CommonTextField(label: '사용자', controller: _userController),
              const SizedBox(height: 12),
              CommonTextField(label: '비고', controller: _etcController),
              const SizedBox(height: 16),
              // 체크박스들
              Wrap(
                spacing: 20,
                runSpacing: 12,
                children: [
                  BuildCheckbox(
                    label: '무단허용',
                    value: _unauthorized,
                    onChanged: (val) {
                      setState(() => _unauthorized = val);
                    },
                  ),
                  BuildCheckbox(
                    label: 'SMS',
                    value: _sms,
                    onChanged: (val) {
                      setState(() => _sms = val);
                    },
                  ),
                  BuildCheckbox(
                    label: '요원',
                    value: _agent,
                    onChanged: (val) {
                      setState(() => _agent = val);
                    },
                  ),
                  BuildCheckbox(
                    label: 'APP',
                    value: _app,
                    onChanged: (val) {
                      setState(() => _app = val);
                    },
                  ),
                  BuildCheckbox(
                    label: '예비',
                    value: _preparation,
                    onChanged: (val) {
                      setState(() => _preparation = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 버튼들
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () async {
                          await _registerUser(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007AFF),
                          foregroundColor: context.colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '저장',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C6C6C),
                          foregroundColor: context.colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '취소',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 존정보 추가 모달
class _AddZoneModal extends StatefulWidget {
  final String controlManagementNumber;

  const _AddZoneModal({required this.controlManagementNumber});

  @override
  State<_AddZoneModal> createState() => _AddZoneModalState();
}

class _AddZoneModalState extends State<_AddZoneModal> {
  // 폼 컨트롤러
  final TextEditingController _zoneInfoController = TextEditingController();
  final TextEditingController _installLocationController =
      TextEditingController();
  final TextEditingController _detectorClassController =
      TextEditingController();
  final TextEditingController _etcController = TextEditingController();

  /// 존정보 등록
  Future<void> _registerZone(BuildContext context) async {
    // 유효성 검사
    final zoneInfo = _zoneInfoController.text.trim();

    if (zoneInfo.isEmpty) {
      showToast(context, message: '존정보를 입력해주세요.');
      return;
    }

    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // TODO: API 호출 (api_service.dart에 추가)
      // final success = await DatabaseService.insertZoneInfo(
      //   managementNumber: widget.customerDetail.controlManagementNumber ?? '',
      //   존정보: zoneInfo,
      //   감지기설치위치: _installLocationController.text.trim(),
      //   감지기종류: _detectorClassController.text.trim(),
      //   비고: _etcController.text.trim(),
      // );

      // 임시로 성공 처리
      final success = true;

      // 로딩 닫기
      if (mounted) Navigator.of(context).pop();

      if (success) {
        if (mounted) {
          showToast(context, message: '존정보가 등록되었습니다.');
          Navigator.of(context).pop(); // 모달 닫기
        }
      }
    } catch (e) {
      // 로딩 닫기
      if (mounted) Navigator.of(context).pop();

      print('존정보 등록 오류: $e');
      if (mounted) {
        showToast(context, message: '존정보 등록 중 오류가 발생했습니다: $e');
      }
    }
  }

  @override
  void dispose() {
    _zoneInfoController.dispose();
    _installLocationController.dispose();
    _detectorClassController.dispose();
    _etcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: context.colors.cardBackground,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 모달 제목
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '존정보 입력',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 폼 필드들
            CommonTextField(label: '존정보', controller: _zoneInfoController),
            const SizedBox(height: 12),
            CommonTextField(
              label: '감지기설치위치',
              controller: _installLocationController,
            ),
            const SizedBox(height: 12),
            CommonTextField(
              label: '감지기종류',
              controller: _detectorClassController,
            ),
            const SizedBox(height: 12),
            CommonTextField(label: '비고', controller: _etcController),
            const SizedBox(height: 24),
            // 버튼들
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _registerZone(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.selectedColor,
                        foregroundColor: context.colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '저장',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.gray30,
                        foregroundColor: context.colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
