import 'dart:ui';

import 'package:flutter/material.dart';
import '../models/search_panel.dart';
import '../models/customer_detail.dart';
import '../models/userZone.dart';
import '../services/api_service.dart';
import '../functions.dart';
import '../style.dart';
import '../theme.dart';

import '../widgets/custom_top_bar.dart';
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
    if (customer != null) {
      _loadUserZoneData(customer.controlManagementNumber);
    } else {
      setState(() {
        _userInfoList = [];
        _zoneInfoList = [];
      });
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
      builder: (context) => _AddUserModal(customerDetail: detail),
    );
  }

  /// 존정보 추가 모달 표시
  void showAddZoneModal() {
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
      builder: (context) => _AddZoneModal(customerDetail: detail),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
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
  final CustomerDetail customerDetail;

  const _AddUserModal({Key? key, required this.customerDetail})
    : super(key: key);

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('userName을 입력해주세요.'),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('사용자 정보가 등록되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // 모달 닫기
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('사용자 정보 등록에 실패했습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // 로딩 닫기
      if (mounted) Navigator.of(context).pop();

      print('사용자 정보 등록 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('사용자 정보 등록 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
      backgroundColor: Colors.white,
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
                  const Text(
                    '사용자 정보 입력',
                    style: TextStyle(
                      color: Color(0xFF252525),
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
                  buildCheckbox('무단허용', _unauthorized, (value) {
                    setState(() {
                      _unauthorized = value ?? false;
                    });
                  }),
                  buildCheckbox('SMS', _sms, (value) {
                    setState(() {
                      _sms = value ?? false;
                    });
                  }),
                  buildCheckbox('요원', _agent, (value) {
                    setState(() {
                      _agent = value ?? false;
                    });
                  }),
                  buildCheckbox('APP', _app, (value) {
                    setState(() {
                      _app = value ?? false;
                    });
                  }),
                  buildCheckbox('예비', _preparation, (value) {
                    setState(() {
                      _preparation = value ?? false;
                    });
                  }),
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
                          foregroundColor: Colors.white,
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
                          foregroundColor: Colors.white,
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
  final CustomerDetail customerDetail;

  const _AddZoneModal({Key? key, required this.customerDetail})
    : super(key: key);

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('존정보를 입력해주세요.'),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('존정보가 등록되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // 모달 닫기
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('존정보 등록에 실패했습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // 로딩 닫기
      if (mounted) Navigator.of(context).pop();

      print('존정보 등록 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('존정보 등록 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
                const Text(
                  '존정보 입력',
                  style: TextStyle(
                    color: Color(0xFF252525),
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
                        backgroundColor: const Color(0xFF007AFF),
                        foregroundColor: Colors.white,
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
                        foregroundColor: Colors.white,
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
