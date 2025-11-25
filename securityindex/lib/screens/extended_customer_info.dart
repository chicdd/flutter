import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/search_panel.dart';
import '../models/customer_detail.dart';
import '../models/customerHoliday.dart';
import '../models/additional_service.dart';
import '../models/dvr_info.dart';
import '../services/api_service.dart';
import '../services/selected_customer_service.dart';
import '../widgets/component.dart';
import '../widgets/time_picker_modal.dart';
import '../style.dart';
import '../widgets/custom_top_bar.dart';
import '../config/topbar_config.dart';

class ExtendedCustomerInfo extends StatefulWidget {
  final SearchPanel? searchpanel;

  const ExtendedCustomerInfo({super.key, this.searchpanel});

  @override
  State<ExtendedCustomerInfo> createState() => ExtendedCustomerInfoState();
}

class ExtendedCustomerInfoState extends State<ExtendedCustomerInfo> {
  final _customerService = SelectedCustomerService();
  // 경계약정 및 무단해제 설정 - 평일
  int? _weekdayGuardStartHour;
  int? _weekdayGuardStartMinute;
  int? _weekdayGuardEndHour;
  int? _weekdayGuardEndMinute;
  int? _weekdayUnauthorizedStartHour;
  int? _weekdayUnauthorizedStartMinute;
  int? _weekdayUnauthorizedEndHour;
  int? _weekdayUnauthorizedEndMinute;
  bool _isWeekdayUsed = false;

  // 경계약정 및 무단해제 설정 - 주말
  int? _weekendGuardStartHour;
  int? _weekendGuardStartMinute;
  int? _weekendGuardEndHour;
  int? _weekendGuardEndMinute;
  int? _weekendUnauthorizedStartHour;
  int? _weekendUnauthorizedStartMinute;
  int? _weekendUnauthorizedEndHour;
  int? _weekendUnauthorizedEndMinute;
  bool _isWeekendUsed = false;

  // 경계약정 및 무단해제 설정 - 휴일
  int? _holidayGuardStartHour;
  int? _holidayGuardStartMinute;
  int? _holidayGuardEndHour;
  int? _holidayGuardEndMinute;
  int? _holidayUnauthorizedStartHour;
  int? _holidayUnauthorizedStartMinute;
  int? _holidayUnauthorizedEndHour;
  int? _holidayUnauthorizedEndMinute;
  bool _isHolidayUsed = false;
  bool _isH2olidayUsed = false;

  // 주간 휴일설정 - 5주 x 7일
  final List<List<bool>> _weeklyHolidays = List.generate(
    5,
    (_) => List.generate(7, (_) => false),
  );

  // 내보내기 드롭다운
  bool _isExportDropdownOpen = false;

  // 검색 관련
  final _searchController = TextEditingController();

  // 고객 추가 메모사항 텍스트 컨트롤러
  final _openingPhoneController = TextEditingController();
  final _openingDateController = TextEditingController();
  final _modemSerialController = TextEditingController();
  final _additionalMemoController = TextEditingController();
  final _gpsX1Controller = TextEditingController();
  final _gpsY1Controller = TextEditingController();
  final _gpsX2Controller = TextEditingController();
  final _gpsY2Controller = TextEditingController();
  final _companyTypeController = TextEditingController();
  final _branchTypeController = TextEditingController();
  final _dedicatedNumberController = TextEditingController();
  final _dedicatedMemoController = TextEditingController();

  String? _companyType; // 회사구분
  String? _branchType; // 지사구분

  // 부가서비스 데이터 목록
  List<AdditionalService> _additionalServices = [];

  // DVR 연동 데이터 목록
  List<DVRInfo> _dvrInfoList = [];

  // 드롭다운 데이터 목록
  List<CodeData> _companyTypeList = [];
  List<CodeData> _branchTypeList = [];
  @override
  void dispose() {
    _customerService.removeListener(_onCustomerServiceChanged);
    _openingPhoneController.dispose();
    _openingDateController.dispose();
    _modemSerialController.dispose();
    _additionalMemoController.dispose();
    _gpsX1Controller.dispose();
    _gpsY1Controller.dispose();
    _gpsX2Controller.dispose();
    _gpsY2Controller.dispose();
    _companyTypeController.dispose();
    _branchTypeController.dispose();
    _dedicatedNumberController.dispose();
    _dedicatedMemoController.dispose();
    super.dispose();
  }

  /// 모든 필드 초기화
  @override
  void _clearAllFields() {
    _openingPhoneController.clear();
    _openingDateController.clear();
    _modemSerialController.clear();
    _additionalMemoController.clear();
    _gpsX1Controller.clear();
    _gpsY1Controller.clear();
    _gpsX2Controller.clear();
    _gpsY2Controller.clear();
    _companyTypeController.clear();
    _branchTypeController.clear();
    _dedicatedNumberController.clear();
    _dedicatedMemoController.clear();

    if (mounted) {
      setState(() {
        _companyType = null;
        _branchType = null;

        // 휴일주간 체크박스 초기화
        for (var i = 0; i < 5; i++) {
          for (var j = 0; j < 7; j++) {
            _weeklyHolidays[i][j] = false;
          }
        }

        // 부가서비스 및 DVR 목록 초기화
        _additionalServices = [];
        _dvrInfoList = [];

        // 경계/해제 시간 초기화 - 평일
        _weekdayGuardStartHour = null;
        _weekdayGuardStartMinute = null;
        _weekdayGuardEndHour = null;
        _weekdayGuardEndMinute = null;
        _weekdayUnauthorizedStartHour = null;
        _weekdayUnauthorizedStartMinute = null;
        _weekdayUnauthorizedEndHour = null;
        _weekdayUnauthorizedEndMinute = null;
        _isWeekdayUsed = false;

        // 경계/해제 시간 초기화- 주말
        _weekendGuardStartHour = null;
        _weekendGuardStartMinute = null;
        _weekendGuardEndHour = null;
        _weekendGuardEndMinute = null;
        _weekendUnauthorizedStartHour = null;
        _weekendUnauthorizedStartMinute = null;
        _weekendUnauthorizedEndHour = null;
        _weekendUnauthorizedEndMinute = null;
        _isWeekendUsed = false;

        // 경계/해제 시간 초기화 - 휴일
        _holidayGuardStartHour = null;
        _holidayGuardStartMinute = null;
        _holidayGuardEndHour = null;
        _holidayGuardEndMinute = null;
        _holidayUnauthorizedStartHour = null;
        _holidayUnauthorizedStartMinute = null;
        _holidayUnauthorizedEndHour = null;
        _holidayUnauthorizedEndMinute = null;
        _isHolidayUsed = false;
      });
    }
  }

  @override
  void didUpdateWidget(ExtendedCustomerInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 고객이 변경되었을 때 새로운 데이터 로드
    if (widget.searchpanel != oldWidget.searchpanel &&
        widget.searchpanel != null) {
      _loadDropdownData(); // 드롭다운 데이터 먼저 로드
      _loadCustomerDataFromService(); // 전역 서비스에서 고객 상세 정보 로드
    }
  }

  /// 상세 정보로부터 필드 업데이트
  void _updateFieldsFromDetail(CustomerDetail detail) {
    // 기본 필드 매핑
    _openingPhoneController.text = detail.openingPhone ?? ''; //개통전화번호
    _modemSerialController.text = detail.modemSerial ?? ''; // 모뎀일련번호
    _openingDateController.text = detail.openingDate ?? ''; // 개통일자
    _additionalMemoController.text = detail.additionalMemo ?? ''; //추가메모

    _gpsX1Controller.text = detail.gpsX1 ?? '';
    _gpsY1Controller.text = detail.gpsY1 ?? '';
    _gpsX2Controller.text = detail.gpsX2 ?? '';
    _gpsY2Controller.text = detail.gpsY2 ?? '';
    _dedicatedNumberController.text = detail.dedicatedNumber ?? '';
    _dedicatedMemoController.text = detail.dedicatedMemo ?? '';

    //드롭다운
    _companyType = isValidCode(detail.companyTypeCode)
        ? detail.companyTypeCode
        : null;

    _branchType = isValidCode(detail.branchTypeCode)
        ? detail.branchTypeCode
        : null;

    // 경계/해제 시간 파싱 - 평일
    _parseGuardTime(detail.weekdayGuardTime, isWeekday: true, isGuard: true);
    _parseGuardTime(detail.weekdayReleaseTime, isWeekday: true, isGuard: false);

    // 경계/해제 시간 파싱 - 주말
    _parseGuardTime(detail.weekendGuardTime, isWeekend: true, isGuard: true);
    _parseGuardTime(detail.weekendReleaseTime, isWeekend: true, isGuard: false);

    // 경계/해제 시간 파싱 - 휴일
    _parseGuardTime(detail.holidayGuardTime, isHoliday: true, isGuard: true);
    _parseGuardTime(detail.holidayReleaseTime, isHoliday: true, isGuard: false);

    // 무단 범위 파싱
    _parseUnauthorizedRange(detail.weekdayUnauthorizedRange, isWeekday: true);
    _parseUnauthorizedRange(detail.weekendUnauthorizedRange, isWeekend: true);
    _parseUnauthorizedRange(detail.holidayUnauthorizedRange, isHoliday: true);

    // 무단 사용 체크박스 설정
    _isWeekdayUsed = detail.weekdayUnauthorizedUse ?? false;
    _isWeekendUsed = detail.weekendUnauthorizedUse ?? false;
    _isHolidayUsed = detail.holidayUnauthorizedUse ?? false;
  }

  @override
  void initState() {
    super.initState();

    // ChangeNotifier 리스너 등록
    _customerService.addListener(_onCustomerServiceChanged);

    // 고객 데이터 로드
    _initializeData();
  }

  /// 데이터 초기화 (순차 처리)
  Future<void> _initializeData() async {
    // 1. 드롭다운 데이터 먼저 로드
    await _loadDropdownData();

    // 2. 고객 데이터 로드 (전역 서비스에서)
    await _loadCustomerDataFromService();
  }

  // 페이지 내 검색
  String _pageSearchQuery = '';

  // 검색 쿼리 업데이트 메서드
  void updateSearchQuery(String query) {
    setState(() {
      _pageSearchQuery = query;
    });
  }

  /// 드롭다운 데이터 로드
  Future<void> _loadDropdownData() async {
    try {
      // 캐시를 통해 드롭다운 데이터 로드
      _companyTypeList = await CodeDataCache.getCodeData('companytype');
      _branchTypeList = await CodeDataCache.getCodeData('branchtype');
    } catch (e) {
      print('드롭다운 데이터 로드 오류: $e');
    }
  }

  // 검색 쿼리를 포함한 CommonTextField 빌더
  Widget _buildSearchableTextField({
    required String label,
    TextEditingController? controller,
    String? hintText,
    IconData? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    int? maxLines,
  }) {
    return CommonTextField(
      label: label,
      controller: controller,
      hintText: hintText,
      suffixIcon: suffixIcon,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      maxLines: maxLines,
      searchQuery: _pageSearchQuery,
    );
  }

  /// 고객 서비스 변경 시 호출
  void _onCustomerServiceChanged() {
    if (mounted && !_customerService.isLoadingDetail) {
      // 로딩 중이 아닐 때만 UI 업데이트
      _updateUIFromService();
    }
  }

  /// 서비스에서 UI 업데이트 (무한 루프 방지)
  void _updateUIFromService() {
    final detail = _customerService.customerDetail;
    final selectedCustomer = _customerService.selectedCustomer;

    if (detail != null) {
      setState(() {
        _updateFieldsFromDetail(detail);
      });

      // 휴일주간, 부가서비스, DVR 데이터 로드
      if (selectedCustomer != null) {
        _loadHolidayData(selectedCustomer.controlManagementNumber);
        _loadAdditionalServices(selectedCustomer.controlManagementNumber);
        _loadDVRInfo(selectedCustomer.controlManagementNumber);
      }
    } else {
      _clearAllFields();
    }
  }

  /// 전역 서비스에서 고객 데이터 로드
  Future<void> _loadCustomerDataFromService() async {
    final selectedCustomer = _customerService.selectedCustomer;

    if (selectedCustomer == null) {
      // 선택된 고객이 없으면 필드 초기화
      _clearAllFields();
      return;
    }

    try {
      // 전역 서비스에서 상세 정보 로드
      await _customerService.loadCustomerDetail();

      final detail = _customerService.customerDetail;

      if (detail != null && mounted) {
        setState(() {
          _updateFieldsFromDetail(detail);
        });

        // 휴일주간, 부가서비스, DVR 데이터 로드
        await _loadHolidayData(selectedCustomer.controlManagementNumber);
        await _loadAdditionalServices(selectedCustomer.controlManagementNumber);
        await _loadDVRInfo(selectedCustomer.controlManagementNumber);
      }
    } catch (e) {
      print('고객 상세 정보 로드 오류: $e');
    }
  }

  /// 휴일주간 데이터 로드 및 체크박스 업데이트
  Future<void> _loadHolidayData(String managementNumber) async {
    try {
      final holidays = await DatabaseService.getHoliday(managementNumber);

      if (holidays.isEmpty || !mounted) {
        return;
      }

      setState(() {
        // 먼저 모든 체크박스 초기화
        for (var i = 0; i < 5; i++) {
          for (var j = 0; j < 7; j++) {
            _weeklyHolidays[i][j] = false;
          }
        }

        // 휴일주간 코드로 체크박스 체크
        for (var holiday in holidays) {
          final code = int.parse(holiday.holidayCode);

          // 첫번째 줄: 일요일(11) ~ 토요일(17)
          if (code >= 11 && code <= 17) {
            final dayIndex = code - 11; // 11->0(일), 12->1(월), ... 17->6(토)
            _weeklyHolidays[0][dayIndex] = true;
          }
          // 두번째 줄: 일요일(21) ~ 토요일(27)
          else if (code >= 21 && code <= 27) {
            final dayIndex = code - 21;
            _weeklyHolidays[1][dayIndex] = true;
          }
          // 세번째 줄: 일요일(31) ~ 토요일(37)
          else if (code >= 31 && code <= 37) {
            final dayIndex = code - 31;
            _weeklyHolidays[2][dayIndex] = true;
          }
          // 네번째 줄: 일요일(41) ~ 토요일(47)
          else if (code >= 41 && code <= 47) {
            final dayIndex = code - 41;
            _weeklyHolidays[3][dayIndex] = true;
          }
          // 다섯번째 줄: 일요일(51) ~ 토요일(57)
          else if (code >= 51 && code <= 57) {
            final dayIndex = code - 51;
            _weeklyHolidays[4][dayIndex] = true;
          }
        }
      });

      print('휴일주간 데이터 로드 완료: ${holidays.length}개');
    } catch (e) {
      print('휴일주간 데이터 로드 오류: $e');
    }
  }

  /// 부가서비스 데이터 로드
  Future<void> _loadAdditionalServices(String managementNumber) async {
    try {
      final services = await DatabaseService.getAdditionalServices(
        managementNumber,
      );

      if (mounted) {
        setState(() {
          _additionalServices = services;
        });
      }

      print('부가서비스 데이터 로드 완료: ${services.length}개');
    } catch (e) {
      print('부가서비스 데이터 로드 오류: $e');
    }
  }

  /// DVR 연동 정보 로드
  Future<void> _loadDVRInfo(String managementNumber) async {
    try {
      final dvrList = await DatabaseService.getDVRInfo(managementNumber);

      if (mounted) {
        setState(() {
          _dvrInfoList = dvrList;
        });
      }

      print('DVR 정보 로드 완료: ${dvrList.length}개');
    } catch (e) {
      print('DVR 정보 로드 오류: $e');
    }
  }

  /// 시간 파싱 헬퍼 메서드 (HH:MM 형식)
  void _parseGuardTime(
    String? timeString, {
    bool isWeekday = false,
    bool isWeekend = false,
    bool isHoliday = false,
    bool isGuard = true,
  }) {
    if (timeString == null || timeString.isEmpty) return;

    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return;

      final hour = int.parse(parts[0].trim());
      final minute = int.parse(parts[1].trim());

      if (isWeekday) {
        if (isGuard) {
          _weekdayGuardStartHour = hour;
          _weekdayGuardStartMinute = minute;
        } else {
          _weekdayGuardEndHour = hour;
          _weekdayGuardEndMinute = minute;
        }
      } else if (isWeekend) {
        if (isGuard) {
          _weekendGuardStartHour = hour;
          _weekendGuardStartMinute = minute;
        } else {
          _weekendGuardEndHour = hour;
          _weekendGuardEndMinute = minute;
        }
      } else if (isHoliday) {
        if (isGuard) {
          _holidayGuardStartHour = hour;
          _holidayGuardStartMinute = minute;
        } else {
          _holidayGuardEndHour = hour;
          _holidayGuardEndMinute = minute;
        }
      }
    } catch (e) {
      print('시간 파싱 오류: $timeString, $e');
    }
  }

  /// 무단 범위 파싱 헬퍼 메서드 (HH:MM~HH:MM 형식)
  void _parseUnauthorizedRange(
    String? rangeString, {
    bool isWeekday = false,
    bool isWeekend = false,
    bool isHoliday = false,
  }) {
    if (rangeString == null || rangeString.isEmpty) return;

    try {
      final parts = rangeString.split('~');
      if (parts.length != 2) return;

      // 시작 시간 파싱
      final startParts = parts[0].trim().split(':');
      if (startParts.length == 2) {
        // XX:00 처리 - XX는 00시를 의미
        int startHour = startParts[0] == 'XX' ? 0 : int.parse(startParts[0]);
        int startMinute = int.parse(startParts[1]);

        if (isWeekday) {
          _weekdayUnauthorizedStartHour = startHour;
          _weekdayUnauthorizedStartMinute = startMinute;
        } else if (isWeekend) {
          _weekendUnauthorizedStartHour = startHour;
          _weekendUnauthorizedStartMinute = startMinute;
        } else if (isHoliday) {
          _holidayUnauthorizedStartHour = startHour;
          _holidayUnauthorizedStartMinute = startMinute;
        }
      }

      // 종료 시간 파싱
      final endParts = parts[1].trim().split(':');
      if (endParts.length == 2) {
        // XX:00 처리
        int endHour = endParts[0] == 'XX' ? 0 : int.parse(endParts[0]);
        int endMinute = int.parse(endParts[1]);

        if (isWeekday) {
          _weekdayUnauthorizedEndHour = endHour;
          _weekdayUnauthorizedEndMinute = endMinute;
        } else if (isWeekend) {
          _weekendUnauthorizedEndHour = endHour;
          _weekendUnauthorizedEndMinute = endMinute;
        } else if (isHoliday) {
          _holidayUnauthorizedEndHour = endHour;
          _holidayUnauthorizedEndMinute = endMinute;
        }
      }
    } catch (e) {
      print('무단 범위 파싱 오류: $rangeString, $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 다른 곳 클릭 시 드롭다운 닫기
        if (_isExportDropdownOpen) {
          setState(() {
            _isExportDropdownOpen = false;
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isExtraWideScreen = constraints.maxWidth >= 1920;
            final isWideScreen = constraints.maxWidth >= 1200;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: isExtraWideScreen
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildSecuritySettingsSection(),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  Expanded(child: _buildCustomerMemoSection()),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildGPSSection()),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildWeeklyHolidaySettings()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildCompanyBranchSection()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildDedicatedLineSection()),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildServiceSection(),
                        const SizedBox(height: 24),
                        _buildDVRSection(),
                      ],
                    )
                  : isWideScreen
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildSecuritySettingsSection(),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: Row(
                                children: [
                                  Expanded(child: _buildCustomerMemoSection()),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildWeeklyHolidaySettings(),
                            ),
                            const SizedBox(width: 16),
                            Expanded(flex: 2, child: _buildGPSSection()),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: _buildCompanyBranchSection(),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: _buildDedicatedLineSection(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildServiceSection(),
                        const SizedBox(height: 24),
                        _buildDVRSection(),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSecuritySettingsSection(),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildCustomerMemoSection()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildGPSSection()),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildWeeklyHolidaySettings(),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildCompanyBranchSection()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildDedicatedLineSection()),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildServiceSection(),
                        const SizedBox(height: 24),
                        _buildDVRSection(),
                      ],
                    ),
            );
          },
        ),
        // body: SingleChildScrollView(
        //   padding: const EdgeInsets.all(24),
        //   child: Column(
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     children: [
        //       _buildSecuritySettingsSection(),
        //       const SizedBox(height: 32),
        //       _buildAdditionalInfoSection(),
        //       const SizedBox(height: 32),
        //       _buildServiceSection(),
        //       const SizedBox(height: 32),
        //       _buildDVRSection(),
        //     ],
        //   ),
        // ),
      ),
    );
  }

  Widget buildExportDropdown() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isExportDropdownOpen = !_isExportDropdownOpen;
            });
          },
          child: Container(
            width: 114,
            height: 35,
            decoration: ShapeDecoration(
              color: const Color(0xFFD8A68A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '내보내기',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isExportDropdownOpen
                      ? Icons.arrow_drop_up
                      : Icons.arrow_drop_down,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
        if (_isExportDropdownOpen)
          Positioned(
            top: 45,
            left: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDropdownItem('철거요청서 출력'),
                  _buildDropdownItem('고객정보시트 출력'),
                  _buildDropdownItem('감지기/존내역 출력'),
                  _buildDropdownItem('무선 정보 엑셀 저장'),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDropdownItem(String label) {
    return InkWell(
      onTap: () {
        setState(() {
          _isExportDropdownOpen = false;
        });
        // TODO: 각 항목별 동작 구현
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE5E5E5), width: 0.5),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF252525),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget buildTopButton(String label, Color color) {
    return GestureDetector(
      onTap: () {
        // TODO: 버튼 동작 구현
      },
      child: Container(
        height: 35,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: ShapeDecoration(
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecuritySettingsSection() {
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
          buildSectionTitle('경계약정 및 무단해제 설정'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTimeSettingCard('평일', true)),
              const SizedBox(width: 16),
              Expanded(child: _buildTimeSettingCard('주말', false)),
              const SizedBox(width: 16),
              Expanded(child: _buildTimeSettingCard('휴일', null)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSettingCard(String title, bool? isWeekday) {
    int? guardStartHour, guardStartMinute, guardEndHour, guardEndMinute;
    int? unauthStartHour, unauthStartMinute, unauthEndHour, unauthEndMinute;
    bool isUsed;

    if (isWeekday == true) {
      guardStartHour = _weekdayGuardStartHour;
      guardStartMinute = _weekdayGuardStartMinute;
      guardEndHour = _weekdayGuardEndHour;
      guardEndMinute = _weekdayGuardEndMinute;
      unauthStartHour = _weekdayUnauthorizedStartHour;
      unauthStartMinute = _weekdayUnauthorizedStartMinute;
      unauthEndHour = _weekdayUnauthorizedEndHour;
      unauthEndMinute = _weekdayUnauthorizedEndMinute;
      isUsed = _isWeekdayUsed;
    } else if (isWeekday == false) {
      guardStartHour = _weekendGuardStartHour;
      guardStartMinute = _weekendGuardStartMinute;
      guardEndHour = _weekendGuardEndHour;
      guardEndMinute = _weekendGuardEndMinute;
      unauthStartHour = _weekendUnauthorizedStartHour;
      unauthStartMinute = _weekendUnauthorizedStartMinute;
      unauthEndHour = _weekendUnauthorizedEndHour;
      unauthEndMinute = _weekendUnauthorizedEndMinute;
      isUsed = _isWeekendUsed;
    } else {
      guardStartHour = _holidayGuardStartHour;
      guardStartMinute = _holidayGuardStartMinute;
      guardEndHour = _holidayGuardEndHour;
      guardEndMinute = _holidayGuardEndMinute;
      unauthStartHour = _holidayUnauthorizedStartHour;
      unauthStartMinute = _holidayUnauthorizedStartMinute;
      unauthEndHour = _holidayUnauthorizedEndHour;
      unauthEndMinute = _holidayUnauthorizedEndMinute;
      isUsed = _isHolidayUsed;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF252525),
                    fontSize: 17,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFE5E5E5)),
                const SizedBox(height: 12),
                TimePickerButton(
                  label: '경계',
                  hour: guardStartHour,
                  minute: guardStartMinute,
                  allowNull: true,
                  onTimeChanged: (hour, minute) {
                    setState(() {
                      if (isWeekday == true) {
                        _weekdayGuardStartHour = hour;
                        _weekdayGuardStartMinute = minute;
                      } else if (isWeekday == false) {
                        _weekendGuardStartHour = hour;
                        _weekendGuardStartMinute = minute;
                      } else {
                        _holidayGuardStartHour = hour;
                        _holidayGuardStartMinute = minute;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFE5E5E5)),
                const SizedBox(height: 12),
                TimePickerButton(
                  label: '해제',
                  hour: guardEndHour,
                  minute: guardEndMinute,
                  allowNull: true,
                  onTimeChanged: (hour, minute) {
                    setState(() {
                      if (isWeekday == true) {
                        _weekdayGuardEndHour = hour;
                        _weekdayGuardEndMinute = minute;
                      } else if (isWeekday == false) {
                        _weekendGuardEndHour = hour;
                        _weekendGuardEndMinute = minute;
                      } else {
                        _holidayGuardEndHour = hour;
                        _holidayGuardEndMinute = minute;
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      '무단',
                      style: TextStyle(
                        color: Color(0xFF252525),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    Checkbox(
                      value: isUsed,
                      onChanged: (value) {
                        setState(() {
                          if (isWeekday == true) {
                            _isWeekdayUsed = value ?? false;
                          } else if (isWeekday == false) {
                            _isWeekendUsed = value ?? false;
                          } else {
                            _isHolidayUsed = value ?? false;
                          }
                        });
                      },
                      activeColor: AppTheme.selectedColor,
                    ),
                    const Text(
                      '사용',
                      style: TextStyle(
                        color: Color(0xFF252525),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFE5E5E5)),
                const SizedBox(height: 12),
                TimePickerButton(
                  label: '경계',
                  hour: unauthStartHour,
                  minute: unauthStartMinute,
                  enabled: isUsed,
                  showXXForZero: true,
                  allowNull: true,
                  onTimeChanged: (hour, minute) {
                    setState(() {
                      if (isWeekday == true) {
                        _weekdayUnauthorizedStartHour = hour;
                        _weekdayUnauthorizedStartMinute = minute;
                      } else if (isWeekday == false) {
                        _weekendUnauthorizedStartHour = hour;
                        _weekendUnauthorizedStartMinute = minute;
                      } else {
                        _holidayUnauthorizedStartHour = hour;
                        _holidayUnauthorizedStartMinute = minute;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFE5E5E5)),
                const SizedBox(height: 12),
                TimePickerButton(
                  label: '해제',
                  hour: unauthEndHour,
                  minute: unauthEndMinute,
                  enabled: isUsed,
                  showXXForZero: true,
                  allowNull: true,
                  onTimeChanged: (hour, minute) {
                    setState(() {
                      if (isWeekday == true) {
                        _weekdayUnauthorizedEndHour = hour;
                        _weekdayUnauthorizedEndMinute = minute;
                      } else if (isWeekday == false) {
                        _weekendUnauthorizedEndHour = hour;
                        _weekendUnauthorizedEndMinute = minute;
                      } else {
                        _holidayUnauthorizedEndHour = hour;
                        _holidayUnauthorizedEndMinute = minute;
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyHolidaySettings() {
    final days = ['일', '월', '화', '수', '목', '금', '토'];

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
          buildSectionTitle('주간 휴일설정'),
          const SizedBox(height: 12),
          // 요일 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 29), // 주차 번호 공간
              ...days.asMap().entries.map((entry) {
                return Expanded(
                  child: Center(
                    child: Text(
                      entry.value,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF252525),
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 4),
          // 5주 체크박스 그리드
          ...List.generate(5, (weekIndex) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 주차 번호
                  Container(
                    width: 25,
                    height: 22,
                    decoration: const ShapeDecoration(
                      color: Color(0xFFF5F5F5),
                      shape: OvalBorder(),
                    ),
                    child: Center(
                      child: Text(
                        '${weekIndex + 1}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // 7일 체크박스
                  ...List.generate(7, (dayIndex) {
                    Color bgColor = const Color(0xFF8D8D8D);
                    Color checkColor = Colors.white;
                    if (dayIndex == 0) {
                      // 일요일
                      bgColor = const Color(0xFFFF7070);
                      checkColor = Colors.white;
                    } else if (dayIndex == 6) {
                      // 토요일
                      bgColor = const Color(0xFF87C5FF);
                      checkColor = Colors.white;
                    }

                    return Expanded(
                      child: Center(
                        child: Transform.scale(
                          scale: 0.85,
                          child: Theme(
                            data: ThemeData(
                              checkboxTheme: CheckboxThemeData(
                                side: const BorderSide(
                                  color: Color(0xFFA8A8A8),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                            child: Checkbox(
                              value: _weeklyHolidays[weekIndex][dayIndex],
                              onChanged: (value) {
                                setState(() {
                                  _weeklyHolidays[weekIndex][dayIndex] =
                                      value ?? false;
                                });
                              },
                              activeColor: bgColor,
                              checkColor: checkColor,
                              side: const BorderSide(
                                color: Color(0xFFA8A8A8),
                                width: 1.5,
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCustomerMemoSection() {
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
          buildSectionTitle('고객 추가 메모사항'),
          const SizedBox(height: 16),
          _buildSearchableTextField(
            label: '개통일자',
            controller: _openingDateController,
          ),
          const SizedBox(height: 12),
          _buildSearchableTextField(
            label: '개통전화번호',
            controller: _openingPhoneController,
          ),
          const SizedBox(height: 12),
          _buildSearchableTextField(
            label: '모뎀일련번호',
            controller: _modemSerialController,
          ),
          const SizedBox(height: 12),
          _buildSearchableTextField(
            label: '추가메모',
            controller: _additionalMemoController,
          ),
        ],
      ),
    );
  }

  Widget _buildGPSSection() {
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
          buildSectionTitle('고객 GPS 좌표'),
          const SizedBox(height: 16),
          CommonTextField(label: 'X 좌표1', controller: _gpsX1Controller),
          const SizedBox(height: 12),
          CommonTextField(label: 'Y 좌표1', controller: _gpsY1Controller),
          const SizedBox(height: 16),
          CommonTextField(label: 'X 좌표2', controller: _gpsX2Controller),
          const SizedBox(height: 12),
          CommonTextField(label: 'Y 좌표2', controller: _gpsY2Controller),
        ],
      ),
    );
  }

  Widget _buildCompanyBranchSection() {
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
          buildSectionTitle('회사 / 지사 구분'),
          const SizedBox(height: 16),
          buildDropdownField(
            label: '회사구분',
            value: _companyType,
            items: _companyTypeList,
            searchQuery: _pageSearchQuery,
            onChanged: (String? newValue) {
              setState(() {
                _companyType = newValue!;
              });
            },
          ),
          const SizedBox(height: 12),
          buildDropdownField(
            label: '지사구분',
            value: _branchType,
            items: _branchTypeList,
            searchQuery: _pageSearchQuery,
            onChanged: (String? newValue) {
              setState(() {
                _branchType = newValue!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDedicatedLineSection() {
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
          buildSectionTitle('전용회선 관리'),
          const SizedBox(height: 16),
          CommonTextField(
            label: '전용회선 번호',
            controller: _dedicatedNumberController,
          ),
          const SizedBox(height: 12),
          CommonTextField(label: '추가메모', controller: _dedicatedMemoController),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildCustomerMemoSection()),
            const SizedBox(width: 16),
            Expanded(child: _buildGPSSection()),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildCompanyBranchSection()),
            const SizedBox(width: 16),
            Expanded(child: _buildDedicatedLineSection()),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceSection() {
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
            '부가서비스 제공',
            style: TextStyle(
              color: Color(0xFF252525),
              fontSize: 18,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
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
                    '서비스명',
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
                    '제공구분',
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
                    '제공일자',
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
                  flex: 3,
                  child: Text(
                    '메모',
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
          if (_additionalServices.isEmpty)
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
                  '부가서비스 데이터가 없습니다.',
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
            ..._additionalServices.asMap().entries.map((entry) {
              final index = entry.key;
              final service = entry.value;
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
                      child: Center(
                        child: HighlightedText(
                          text: service.serviceName ?? '-',
                          query: _pageSearchQuery,
                          style: const TextStyle(
                            color: Color(0xFF252525),
                            fontSize: 15,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: HighlightedText(
                          text: service.provisionType ?? '-',
                          query: _pageSearchQuery,
                          style: const TextStyle(
                            color: Color(0xFF252525),
                            fontSize: 15,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: HighlightedText(
                          text: service.provisionDate ?? '-',
                          query: _pageSearchQuery,
                          style: const TextStyle(
                            color: Color(0xFF252525),
                            fontSize: 15,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: HighlightedText(
                          text: service.memo ?? '-',
                          query: _pageSearchQuery,
                          style: const TextStyle(
                            color: Color(0xFF252525),
                            fontSize: 15,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
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

  Widget _buildDVRSection() {
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
            'DVR 설치현황',
            style: TextStyle(
              color: Color(0xFF252525),
              fontSize: 18,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
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
              children: const [
                Expanded(child: Text('접속방식', textAlign: TextAlign.center)),
                Expanded(child: Text('DVR종류코드', textAlign: TextAlign.center)),
                Expanded(child: Text('종류', textAlign: TextAlign.center)),
                Expanded(child: Text('접속주소', textAlign: TextAlign.center)),
                Expanded(child: Text('접속포트', textAlign: TextAlign.center)),
                Expanded(child: Text('접속ID', textAlign: TextAlign.center)),
                Expanded(child: Text('접속암호', textAlign: TextAlign.center)),
                Expanded(child: Text('추가일자', textAlign: TextAlign.center)),
              ],
            ),
          ),
          // 테이블 내용 (실제 DVR 데이터)
          if (_dvrInfoList.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: const Center(
                child: Text(
                  'DVR 정보가 없습니다.',
                  style: TextStyle(color: Color(0xFF999999), fontSize: 14),
                ),
              ),
            )
          else
            ..._dvrInfoList.asMap().entries.map((entry) {
              final index = entry.key;
              final dvr = entry.value;
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
                      child: Center(
                        child: HighlightedText(
                          text: dvr.connectionMethodText,
                          query: _pageSearchQuery,
                          style: const TextStyle(
                            color: Color(0xFF252525),
                            fontSize: 15,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: HighlightedText(
                          text: dvr.dvrTypeCode ?? '-',
                          query: _pageSearchQuery,
                          style: const TextStyle(
                            color: Color(0xFF252525),
                            fontSize: 15,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: HighlightedText(
                          text: dvr.dvrTypeName ?? '-',
                          query: _pageSearchQuery,
                          style: const TextStyle(
                            color: Color(0xFF252525),
                            fontSize: 15,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: HighlightedText(
                          text: dvr.connectionAddress ?? '-',
                          query: _pageSearchQuery,
                          style: const TextStyle(
                            color: Color(0xFF252525),
                            fontSize: 15,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: HighlightedText(
                          text: dvr.connectionPort ?? '-',
                          query: _pageSearchQuery,
                          style: const TextStyle(
                            color: Color(0xFF252525),
                            fontSize: 15,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: HighlightedText(
                          text: dvr.connectionId ?? '-',
                          query: _pageSearchQuery,
                          style: const TextStyle(
                            color: Color(0xFF252525),
                            fontSize: 15,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: HighlightedText(
                          text: dvr.connectionPassword ?? '-',
                          query: _pageSearchQuery,
                          style: const TextStyle(
                            color: Color(0xFF252525),
                            fontSize: 15,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: HighlightedText(
                          text: dvr.addedDate ?? '-',
                          query: _pageSearchQuery,
                          style: const TextStyle(
                            color: Color(0xFF252525),
                            fontSize: 15,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
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
