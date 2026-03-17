import 'package:flutter/material.dart';
import '../component/additionalServiceSection.dart';
import '../component/companyBranchSection.dart';
import '../component/gpsSection.dart';
import '../component/customerMemoExtendedSection.dart';
import '../component/dedicatedLineSection.dart';
import '../component/dvrSection.dart';
import '../component/securitySettingSection.dart';
import '../component/weeklyHolidaySection.dart';
import '../models/customer_form_data.dart';
import '../theme.dart';
import '../models/search_panel.dart';
import '../models/customer_detail.dart';
import '../services/api_service.dart';
import '../services/selected_customer_service.dart';
import '../style.dart';
import '../widgets/content_area.dart';
import '../functions.dart';

class ExtendedCustomerInfo extends StatefulWidget {
  final SearchPanel? searchpanel;

  const ExtendedCustomerInfo({super.key, this.searchpanel});

  @override
  State<ExtendedCustomerInfo> createState() => ExtendedCustomerInfoState();
}

class ExtendedCustomerInfoState extends State<ExtendedCustomerInfo> {
  final _customerService = SelectedCustomerService();

  // 현재 로드된 고객의 관제관리번호 (중복 API 호출 방지)
  String? _loadedCustomerManagementNumber;

  // 편집 모드 상태
  bool isEditMode = false;
  bool _hasChanges = false;
  Map<String, dynamic> _originalData = {};

  // 경계약정 및 무단해제 설정 데이터
  final _securityData = CustomerFormData();

  // 주간 휴일설정 - 5주 x 7일
  final List<List<bool>> _weeklyHolidays = List.generate(
    5,
    (_) => List.generate(7, (_) => false),
  );

  // 내보내기 드롭다운
  bool _isExportDropdownOpen = false;

  // 검색 관련

  // 고객 추가 메모사항 텍스트 컨트롤러
  final _openingPhoneController = TextEditingController();
  final _openingDateController = TextEditingController();
  final _modemSerialController = TextEditingController();
  final _additionalMemoController = TextEditingController();
  final _gpsX1Controller = TextEditingController();
  final _gpsY1Controller = TextEditingController();
  final _gpsX2Controller = TextEditingController();
  final _gpsY2Controller = TextEditingController();
  final _dedicatedNumberController = TextEditingController();
  final _dedicatedMemoController = TextEditingController();

  String? companyType; // 회사구분
  String? branchType; // 지사구분

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
    _dedicatedNumberController.dispose();
    _dedicatedMemoController.dispose();
    super.dispose();
  }

  /// 모든 필드 초기화
  void _clearAllFields() {
    _openingPhoneController.clear();
    _openingDateController.clear();
    _modemSerialController.clear();
    _additionalMemoController.clear();
    _gpsX1Controller.clear();
    _gpsY1Controller.clear();
    _gpsX2Controller.clear();
    _gpsY2Controller.clear();
    _dedicatedNumberController.clear();
    _dedicatedMemoController.clear();

    if (mounted) {
      setState(() {
        companyType = null;
        branchType = null;

        // 휴일주간 체크박스 초기화
        for (var i = 0; i < 5; i++) {
          for (var j = 0; j < 7; j++) {
            _weeklyHolidays[i][j] = false;
          }
        }

        // 경계/해제 시간 초기화
        _securityData.weekdayGuardStartHour = null;
        _securityData.weekdayGuardStartMinute = null;
        _securityData.weekdayGuardEndHour = null;
        _securityData.weekdayGuardEndMinute = null;
        _securityData.weekdayUnauthorizedStartHour = null;
        _securityData.weekdayUnauthorizedStartMinute = null;
        _securityData.weekdayUnauthorizedEndHour = null;
        _securityData.weekdayUnauthorizedEndMinute = null;
        _securityData.isWeekdayUsed = false;
        _securityData.weekendGuardStartHour = null;
        _securityData.weekendGuardStartMinute = null;
        _securityData.weekendGuardEndHour = null;
        _securityData.weekendGuardEndMinute = null;
        _securityData.weekendUnauthorizedStartHour = null;
        _securityData.weekendUnauthorizedStartMinute = null;
        _securityData.weekendUnauthorizedEndHour = null;
        _securityData.weekendUnauthorizedEndMinute = null;
        _securityData.isWeekendUsed = false;
        _securityData.holidayGuardStartHour = null;
        _securityData.holidayGuardStartMinute = null;
        _securityData.holidayGuardEndHour = null;
        _securityData.holidayGuardEndMinute = null;
        _securityData.holidayUnauthorizedStartHour = null;
        _securityData.holidayUnauthorizedStartMinute = null;
        _securityData.holidayUnauthorizedEndHour = null;
        _securityData.holidayUnauthorizedEndMinute = null;
        _securityData.isHolidayUsed = false;
      });
    }
  }

  /// 상세 정보로부터 필드 업데이트
  Future<void> _updateFieldsFromDetail(CustomerDetail detail) async {
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
    companyType = isValidCode(detail.companyTypeCode)
        ? detail.companyTypeCode
        : null;
    branchType = isValidCode(detail.branchTypeCode)
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
    _securityData.isWeekdayUsed = detail.weekdayUnauthorizedUse ?? false;
    _securityData.isWeekendUsed = detail.weekendUnauthorizedUse ?? false;
    _securityData.isHolidayUsed = detail.holidayUnauthorizedUse ?? false;
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
    _companyTypeList = await loadDropdownData('companytype');
    _branchTypeList = await loadDropdownData('branchtype');
    _formData.companyTypeList = _companyTypeList;
    _formData.branchTypeList = _branchTypeList;

    // 2. 확장고객정보 화면에서는 고객 상세 정보를 로드
    if (_customerService.selectedCustomer != null) {
      _loadedCustomerManagementNumber =
          _customerService.selectedCustomer!.controlManagementNumber;
      await _customerService.loadCustomerDetail();
    }

    // 3. 고객 데이터 로드
    await _updateUIFromService();
  }

  // 공유 폼 데이터
  final _formData = CustomerFormData();

  // 페이지 내 검색
  String _pageSearchQuery = '';

  // 검색 쿼리 업데이트 메서드
  void updateSearchQuery(String query) {
    setState(() {
      _pageSearchQuery = query;
    });
  }

  /// 고객 서비스 변경 시 호출
  void _onCustomerServiceChanged() {
    // 편집 모드 중이거나 로딩 중일 때는 UI 업데이트 안 함
    if (mounted && !_customerService.isLoadingDetail && !isEditMode) {
      final currentCustomerNumber =
          _customerService.selectedCustomer?.controlManagementNumber;

      // 고객이 변경된 경우에만 API 호출
      if (currentCustomerNumber != _loadedCustomerManagementNumber) {
        _loadedCustomerManagementNumber = currentCustomerNumber;

        // 선택된 고객이 있으면 상세 정보 로드
        if (_customerService.selectedCustomer != null) {
          _customerService.loadCustomerDetail();
        }
      }

      // 로딩 중이 아닐 때만 UI 업데이트
      _updateUIFromService();
    }
  }

  /// 서비스에서 UI 업데이트 (무한 루프 방지)
  Future<void> _updateUIFromService() async {
    final detail = _customerService.customerDetail;
    final selectedCustomer = _customerService.selectedCustomer;

    if (detail != null) {
      setState(() {});

      // 휴일주간 데이터 로드
      if (selectedCustomer != null) {
        _updateFieldsFromDetail(detail);
        _loadHolidayData(selectedCustomer.controlManagementNumber);
      }
    } else {
      _clearAllFields();
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
        print('데이터 목록: ${holidays.map((e) => e.holidayCode).toList()}');
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
          _securityData.weekdayGuardStartHour = hour;
          _securityData.weekdayGuardStartMinute = minute;
        } else {
          _securityData.weekdayGuardEndHour = hour;
          _securityData.weekdayGuardEndMinute = minute;
        }
      } else if (isWeekend) {
        if (isGuard) {
          _securityData.weekendGuardStartHour = hour;
          _securityData.weekendGuardStartMinute = minute;
        } else {
          _securityData.weekendGuardEndHour = hour;
          _securityData.weekendGuardEndMinute = minute;
        }
      } else if (isHoliday) {
        if (isGuard) {
          _securityData.holidayGuardStartHour = hour;
          _securityData.holidayGuardStartMinute = minute;
        } else {
          _securityData.holidayGuardEndHour = hour;
          _securityData.holidayGuardEndMinute = minute;
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
          _securityData.weekdayUnauthorizedStartHour = startHour;
          _securityData.weekdayUnauthorizedStartMinute = startMinute;
        } else if (isWeekend) {
          _securityData.weekendUnauthorizedStartHour = startHour;
          _securityData.weekendUnauthorizedStartMinute = startMinute;
        } else if (isHoliday) {
          _securityData.holidayUnauthorizedStartHour = startHour;
          _securityData.holidayUnauthorizedStartMinute = startMinute;
        }
      }

      // 종료 시간 파싱
      final endParts = parts[1].trim().split(':');
      if (endParts.length == 2) {
        // XX:00 처리
        int endHour = endParts[0] == 'XX' ? 0 : int.parse(endParts[0]);
        int endMinute = int.parse(endParts[1]);

        if (isWeekday) {
          _securityData.weekdayUnauthorizedEndHour = endHour;
          _securityData.weekdayUnauthorizedEndMinute = endMinute;
        } else if (isWeekend) {
          _securityData.weekendUnauthorizedEndHour = endHour;
          _securityData.weekendUnauthorizedEndMinute = endMinute;
        } else if (isHoliday) {
          _securityData.holidayUnauthorizedEndHour = endHour;
          _securityData.holidayUnauthorizedEndMinute = endMinute;
        }
      }
    } catch (e) {
      print('무단 범위 파싱 오류: $rangeString, $e');
    }
  }

  /// 편집 모드 진입
  void enterEditMode() {
    setState(() {
      isEditMode = true;
      _hasChanges = false;
      _saveOriginalData();
    });
    // 서비스에 편집 모드 시작 등록
    _customerService.startEditing(_showCancelConfirmDialogForService);
    // ContentArea의 setState를 호출하여 topbar 버튼 업데이트
    if (mounted) {
      context.findAncestorStateOfType<ContentAreaState>()?.setState(() {});
    }
  }

  /// 편집 모드 종료 (취소)
  void exitEditMode() {
    if (_hasChanges) {
      _showCancelConfirmDialog();
    } else {
      setState(() {
        isEditMode = false;
      });
      // ContentArea의 setState를 호출하여 topbar 버튼 업데이트
      if (mounted) {
        context.findAncestorStateOfType<ContentAreaState>()?.setState(() {});
      }
    }
  }

  // /// 편집 모드 강제 종료 (화면 전환 시 사용)
  // void forceExitEditMode() {
  //   if (isEditMode) {
  //     setState(() {
  //       isEditMode = false;
  //       _hasChanges = false;
  //     });
  //     // 서비스에 편집 종료 알림
  //     _customerService.endEditing();
  //     // ContentArea의 setState를 호출하여 topbar 버튼 업데이트
  //     if (mounted) {
  //       context.findAncestorStateOfType<ContentAreaState>()?.setState(() {});
  //     }
  //   }
  // }

  /// 원본 데이터 저장
  void _saveOriginalData() {
    _originalData = {
      '개통전화번호': _openingPhoneController.text,
      '개통일자': _openingDateController.text,
      '모뎀일련번호': _modemSerialController.text,
      '추가메모': _additionalMemoController.text,
      'GPSX1': _gpsX1Controller.text,
      'GPSY1': _gpsY1Controller.text,
      'GPSX2': _gpsX2Controller.text,
      'GPSY2': _gpsY2Controller.text,
      '전용자번호': _dedicatedNumberController.text,
      '전용자메모': _dedicatedMemoController.text,
      '회사구분코드': companyType,
      '지사구분코드': branchType,
      '평일경계시작시': _securityData.weekdayGuardStartHour,
      '평일경계시작분': _securityData.weekdayGuardStartMinute,
      '평일경계종료시': _securityData.weekdayGuardEndHour,
      '평일경계종료분': _securityData.weekdayGuardEndMinute,
      '평일무단시작시': _securityData.weekdayUnauthorizedStartHour,
      '평일무단시작분': _securityData.weekdayUnauthorizedStartMinute,
      '평일무단종료시': _securityData.weekdayUnauthorizedEndHour,
      '평일무단종료분': _securityData.weekdayUnauthorizedEndMinute,
      '평일무단사용': _securityData.isWeekdayUsed,
      '주말경계시작시': _securityData.weekendGuardStartHour,
      '주말경계시작분': _securityData.weekendGuardStartMinute,
      '주말경계종료시': _securityData.weekendGuardEndHour,
      '주말경계종료분': _securityData.weekendGuardEndMinute,
      '주말무단시작시': _securityData.weekendUnauthorizedStartHour,
      '주말무단시작분': _securityData.weekendUnauthorizedStartMinute,
      '주말무단종료시': _securityData.weekendUnauthorizedEndHour,
      '주말무단종료분': _securityData.weekendUnauthorizedEndMinute,
      '주말무단사용': _securityData.isWeekendUsed,
      '휴일경계시작시': _securityData.holidayGuardStartHour,
      '휴일경계시작분': _securityData.holidayGuardStartMinute,
      '휴일경계종료시': _securityData.holidayGuardEndHour,
      '휴일경계종료분': _securityData.holidayGuardEndMinute,
      '휴일무단시작시': _securityData.holidayUnauthorizedStartHour,
      '휴일무단시작분': _securityData.holidayUnauthorizedStartMinute,
      '휴일무단종료시': _securityData.holidayUnauthorizedEndHour,
      '휴일무단종료분': _securityData.holidayUnauthorizedEndMinute,
      '휴일무단사용': _securityData.isHolidayUsed,
      '주간휴일설정': List.generate(5, (i) => List.from(_weeklyHolidays[i])),
    };
  }

  /// 변경사항 확인
  void _trackChanges() {
    setState(() {
      _hasChanges = true;
    });
    // 서비스에 변경사항 알림
    _customerService.markAsChanged();
  }

  /// 저장 확인 및 실행
  Future<void> saveChanges() async {
    try {
      final managementNumber =
          _customerService.selectedCustomer?.controlManagementNumber;
      if (managementNumber == null) return;

      // 시간 형식 변환 헬퍼
      String? formatTime(int? hour, int? minute) {
        if (hour == null || minute == null) return null;
        return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      }

      // 무단 범위 형식 변환 헬퍼
      String? formatUnauthorizedRange(
        int? startHour,
        int? startMinute,
        int? endHour,
        int? endMinute,
      ) {
        if (startHour == null ||
            startMinute == null ||
            endHour == null ||
            endMinute == null) {
          return null;
        }
        final startHourStr = startHour == 0
            ? 'XX'
            : startHour.toString().padLeft(2, '0');
        final endHourStr = endHour == 0
            ? 'XX'
            : endHour.toString().padLeft(2, '0');
        return '$startHourStr:${startMinute.toString().padLeft(2, '0')}~$endHourStr:${endMinute.toString().padLeft(2, '0')}';
      }

      // 기본 정보 저장
      final success = await DatabaseService.updateExtendedCustomerInfo(
        managementNumber: managementNumber,
        data: {
          'cu1': _openingPhoneController.text, //개통전화번호
          'cu2': _modemSerialController.text, //모뎀일련번호
          'cu3': _openingDateController.text, //개통일자
          'cu4': _additionalMemoController.text, //추가메모
          'tmP4': _gpsX1Controller.text, //gpsX1
          'tmP5': _gpsY1Controller.text, //GPSY1
          'tmP6': _gpsX2Controller.text, //GPSX2
          'tmP7': _gpsY2Controller.text, //GPSY2
          '전용자번호': _dedicatedNumberController.text, //전용회선번호
          '전용자메모': _dedicatedMemoController.text, //전용회선메모
          '회사구분코드': companyType,
          '지사구분코드': branchType,
          '평일경계': formatTime(
            _securityData.weekdayGuardStartHour,
            _securityData.weekdayGuardStartMinute,
          ),
          '평일해제': formatTime(
            _securityData.weekdayGuardEndHour,
            _securityData.weekdayGuardEndMinute,
          ),
          '평일무단범위': formatUnauthorizedRange(
            _securityData.weekdayUnauthorizedStartHour,
            _securityData.weekdayUnauthorizedStartMinute,
            _securityData.weekdayUnauthorizedEndHour,
            _securityData.weekdayUnauthorizedEndMinute,
          ),
          '평일무단사용': _securityData.isWeekdayUsed ? 1 : 0,
          '주말경계': formatTime(
            _securityData.weekendGuardStartHour,
            _securityData.weekendGuardStartMinute,
          ),
          '주말해제': formatTime(
            _securityData.weekendGuardEndHour,
            _securityData.weekendGuardEndMinute,
          ),
          '주말무단범위': formatUnauthorizedRange(
            _securityData.weekendUnauthorizedStartHour,
            _securityData.weekendUnauthorizedStartMinute,
            _securityData.weekendUnauthorizedEndHour,
            _securityData.weekendUnauthorizedEndMinute,
          ),
          '주말무단사용': _securityData.isWeekendUsed ? 1 : 0,
          '휴일경계': formatTime(
            _securityData.holidayGuardStartHour,
            _securityData.holidayGuardStartMinute,
          ),
          '휴일해제': formatTime(
            _securityData.holidayGuardEndHour,
            _securityData.holidayGuardEndMinute,
          ),
          '휴일무단범위': formatUnauthorizedRange(
            _securityData.holidayUnauthorizedStartHour,
            _securityData.holidayUnauthorizedStartMinute,
            _securityData.holidayUnauthorizedEndHour,
            _securityData.holidayUnauthorizedEndMinute,
          ),
          '휴일무단사용': _securityData.isHolidayUsed ? 1 : 0,
        },
      );

      // 주간휴일설정 저장
      bool holidaySuccess = true;
      if (success) {
        // 체크된 항목을 휴일주간코드로 변환
        List<String> holidayCodes = [];
        for (int weekIndex = 0; weekIndex < 5; weekIndex++) {
          for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
            if (_weeklyHolidays[weekIndex][dayIndex]) {
              // 주차(1~5) * 10 + 요일(1~7)
              final code = ((weekIndex + 1) * 10 + dayIndex + 1).toString();
              holidayCodes.add(code);
            }
          }
        }

        holidaySuccess = await DatabaseService.updateHolidayWeek(
          managementNumber: managementNumber,
          holidayCodes: holidayCodes,
        );
      }

      if (success && holidaySuccess && mounted) {
        showToast(context, message: '저장되었습니다.');
        // 편집 모드 종료
        setState(() {
          isEditMode = false;
          _hasChanges = false;
        });

        // 서비스에 편집 종료 알림 (notifyListeners 호출하지 않음 - 중복 API 호출 방지)
        _customerService.endEditingSilent();

        // 데이터 새로고침 (리스너가 자동으로 _updateUIFromService를 호출하여 모든 데이터 새로고침)
        await _customerService.loadCustomerDetail(force: true);

        // ContentArea의 setState를 호출하여 topbar 버튼 업데이트
        if (mounted) {
          context.findAncestorStateOfType<ContentAreaState>()?.setState(() {});
        }
      } else if (mounted) {
        if (!success) {
          showToast(context, message: '기본 정보 저장에 실패했습니다.');
        } else if (!holidaySuccess) {
          showToast(context, message: '주간휴일설정 저장에 실패했습니다.');
        }
      }
    } catch (e) {
      if (mounted) {
        showToast(context, message: '오류가 발생했습니다: $e');
      }
    }
  }

  /// 취소 확인 다이얼로그
  void _showCancelConfirmDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('편집 취소'),
          content: const Text('변경사항이 저장되지 않습니다. 그래도 나가시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: context.colors.gray30,
                foregroundColor: context.colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0), // 원하는 둥글기 정도 설정
                ),
              ),
              child: const Text('아니오'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  isEditMode = false;
                  _hasChanges = false;
                  // 원본 데이터로 복원
                  _restoreOriginalData();
                  print('복원됨');
                });
                // 서비스에 편집 종료 알림
                _customerService.endEditing();
                // ContentArea의 setState를 호출하여 topbar 버튼 업데이트
                if (mounted) {
                  context.findAncestorStateOfType<ContentAreaState>()?.setState(
                    () {},
                  );
                }
                showToast(context, message: '편집 모드가 취소되었습니다.');
              },
              style: TextButton.styleFrom(
                foregroundColor: context.colors.white,
                backgroundColor: context.colors.selectedColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('예'),
            ),
          ],
        );
      },
    );
  }

  /// 서비스에서 호출할 취소 확인 다이얼로그 (콜백 포함)
  void _showCancelConfirmDialogForService(Function onConfirmed) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('편집 취소'),
          content: const Text('변경사항이 저장되지 않습니다. 그래도 나가시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: context.colors.gray30,
                foregroundColor: context.colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0), // 원하는 둥글기 정도 설정
                ),
              ),
              child: const Text('아니오'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  isEditMode = false;
                  _hasChanges = false;
                  // 원본 데이터로 복원
                  _restoreOriginalData();
                });
                // 서비스에 편집 종료 알림
                _customerService.endEditing();
                // ContentArea의 setState를 호출하여 topbar 버튼 업데이트
                if (mounted) {
                  context.findAncestorStateOfType<ContentAreaState>()?.setState(
                    () {},
                  );
                }
                // 확인 후 콜백 실행
                onConfirmed();
                showToast(context, message: '편집 모드가 취소되었습니다.');
              },
              style: TextButton.styleFrom(
                foregroundColor: context.colors.white,
                backgroundColor: context.colors.selectedColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('예'),
            ),
          ],
        );
      },
    );
  }

  /// 원본 데이터 복원
  void _restoreOriginalData() {
    _openingPhoneController.text = _originalData['개통전화번호'] ?? '';
    _openingDateController.text = _originalData['개통일자'] ?? '';
    _modemSerialController.text = _originalData['모뎀일련번호'] ?? '';
    _additionalMemoController.text = _originalData['추가메모'] ?? '';
    _gpsX1Controller.text = _originalData['GPSX1'] ?? '';
    _gpsY1Controller.text = _originalData['GPSY1'] ?? '';
    _gpsX2Controller.text = _originalData['GPSX2'] ?? '';
    _gpsY2Controller.text = _originalData['GPSY2'] ?? '';
    _dedicatedNumberController.text = _originalData['전용자번호'] ?? '';
    _dedicatedMemoController.text = _originalData['전용자메모'] ?? '';
    companyType = _originalData['회사구분코드'];
    branchType = _originalData['회사구분코드'];
    _securityData.weekdayGuardStartHour = _originalData['평일경계시작시'];
    _securityData.weekdayGuardStartMinute = _originalData['평일경계시작분'];
    _securityData.weekdayGuardEndHour = _originalData['평일경계종료시'];
    _securityData.weekdayGuardEndMinute = _originalData['평일경계종료분'];
    _securityData.weekdayUnauthorizedStartHour = _originalData['평일무단시작시'];
    _securityData.weekdayUnauthorizedStartMinute = _originalData['평일무단시작분'];
    _securityData.weekdayUnauthorizedEndHour = _originalData['평일무단종료시'];
    _securityData.weekdayUnauthorizedEndMinute = _originalData['평일무단종료분'];
    _securityData.isWeekdayUsed = _originalData['평일무단사용'] ?? false;
    _securityData.weekendGuardStartHour = _originalData['주말경계시작시'];
    _securityData.weekendGuardStartMinute = _originalData['주말경계시작분'];
    _securityData.weekendGuardEndHour = _originalData['주말경계종료시'];
    _securityData.weekendGuardEndMinute = _originalData['주말경계종료분'];
    _securityData.weekendUnauthorizedStartHour = _originalData['주말무단시작시'];
    _securityData.weekendUnauthorizedStartMinute = _originalData['주말무단시작분'];
    _securityData.weekendUnauthorizedEndHour = _originalData['주말무단종료시'];
    _securityData.weekendUnauthorizedEndMinute = _originalData['주말무단종료분'];
    _securityData.isWeekendUsed = _originalData['주말무단사용'] ?? false;
    _securityData.holidayGuardStartHour = _originalData['휴일경계시작시'];
    _securityData.holidayGuardStartMinute = _originalData['휴일경계시작분'];
    _securityData.holidayGuardEndHour = _originalData['휴일경계종료시'];
    _securityData.holidayGuardEndMinute = _originalData['휴일경계종료분'];
    _securityData.holidayUnauthorizedStartHour = _originalData['휴일무단시작시'];
    _securityData.holidayUnauthorizedStartMinute = _originalData['휴일무단시작분'];
    _securityData.holidayUnauthorizedEndHour = _originalData['휴일무단종료시'];
    _securityData.holidayUnauthorizedEndMinute = _originalData['휴일무단종료분'];
    _securityData.isHolidayUsed = _originalData['휴일무단사용'] ?? false;

    // 주간 휴일설정 복원
    if (_originalData['주간휴일설정'] != null) {
      final savedHolidays = _originalData['주간휴일설정'] as List<dynamic>;
      for (var i = 0; i < 5; i++) {
        final week = savedHolidays[i] as List<dynamic>;
        for (var j = 0; j < 7; j++) {
          _weeklyHolidays[i][j] = week[j] as bool;
        }
      }
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
        backgroundColor: context.colors.background,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth >= 1700;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: isWideScreen
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 상단 4열 레이아웃
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1열: 보안설정
                              Expanded(
                                flex: 4,
                                child: SecuritySettingsSection(
                                  data: _securityData,
                                  rebuildParent: setState,
                                  isEditMode: isEditMode,
                                  onChanged: _trackChanges,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // 2열: 고객메모 (위) + 회사지점 (아래)
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    CustomerExtendMemoSection(
                                      openingDateController:
                                          _openingDateController,
                                      openingPhoneController:
                                          _openingPhoneController,
                                      modemSerialController:
                                          _modemSerialController,
                                      additionalMemoController:
                                          _additionalMemoController,
                                      isEditMode: isEditMode,
                                      searchQuery: _pageSearchQuery,
                                      onChanged: _trackChanges,
                                    ),
                                    const SizedBox(height: 16),
                                    CompanyBranchSection(
                                      data: _formData,
                                      rebuildParent: setState,
                                      isEditMode: isEditMode,
                                      searchQuery: _pageSearchQuery,
                                      onCompanyChanged: (v) =>
                                          setState(() => companyType = v),
                                      onBranchChanged: (v) =>
                                          setState(() => branchType = v),
                                      onChanged: _trackChanges,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // 3열: GPS (위) + 전용선 (아래)
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    GPSSection(
                                      gpsX1Controller: _gpsX1Controller,
                                      gpsY1Controller: _gpsY1Controller,
                                      gpsX2Controller: _gpsX2Controller,
                                      gpsY2Controller: _gpsY2Controller,
                                      isEditMode: isEditMode,
                                      onChanged: _trackChanges,
                                    ),
                                    const SizedBox(height: 16),
                                    DedicatedLineSection(
                                      dedicatedNumberController:
                                          _dedicatedNumberController,
                                      dedicatedMemoController:
                                          _dedicatedMemoController,
                                      isEditMode: isEditMode,
                                      onChanged: _trackChanges,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // 4열: 주간휴일설정
                              Expanded(
                                flex: 2,
                                child: WeeklyHolidaySection(
                                  weeklyHolidays: _weeklyHolidays,
                                  isEditMode: isEditMode,
                                  onChanged: (weekIndex, dayIndex, value) {
                                    setState(() {
                                      _weeklyHolidays[weekIndex][dayIndex] =
                                          value;
                                    });
                                    _trackChanges();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 부가서비스
                        SizedBox(
                          height: 400,
                          child: AdditionalServiceSection(
                            controlManagementNumber: _customerService
                                .selectedCustomer
                                ?.controlManagementNumber,
                            isEditMode: isEditMode,
                            searchQuery: _pageSearchQuery,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // DVR 상태
                        SizedBox(
                          height: 400,
                          child: DVRSection(
                            controlManagementNumber: _customerService
                                .selectedCustomer
                                ?.controlManagementNumber,
                            isEditMode: isEditMode,
                            searchQuery: _pageSearchQuery,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 2,
                                child: SecuritySettingsSection(
                                  data: _securityData,
                                  rebuildParent: setState,
                                  isEditMode: isEditMode,
                                  onChanged: _trackChanges,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: CustomerExtendMemoSection(
                                  openingDateController: _openingDateController,
                                  openingPhoneController:
                                      _openingPhoneController,
                                  modemSerialController: _modemSerialController,
                                  additionalMemoController:
                                      _additionalMemoController,
                                  isEditMode: isEditMode,
                                  searchQuery: _pageSearchQuery,
                                  onChanged: _trackChanges,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 3,
                                child: WeeklyHolidaySection(
                                  weeklyHolidays: _weeklyHolidays,
                                  isEditMode: isEditMode,
                                  onChanged: (weekIndex, dayIndex, value) {
                                    setState(() {
                                      _weeklyHolidays[weekIndex][dayIndex] =
                                          value;
                                    });
                                    _trackChanges();
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: GPSSection(
                                  gpsX1Controller: _gpsX1Controller,
                                  gpsY1Controller: _gpsY1Controller,
                                  gpsX2Controller: _gpsX2Controller,
                                  gpsY2Controller: _gpsY2Controller,
                                  isEditMode: isEditMode,
                                  onChanged: _trackChanges,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: CompanyBranchSection(
                                  data: _formData,
                                  rebuildParent: setState,
                                  isEditMode: isEditMode,
                                  searchQuery: _pageSearchQuery,
                                  onCompanyChanged: (v) =>
                                      setState(() => companyType = v),
                                  onBranchChanged: (v) =>
                                      setState(() => branchType = v),
                                  onChanged: _trackChanges,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: DedicatedLineSection(
                                  dedicatedNumberController:
                                      _dedicatedNumberController,
                                  dedicatedMemoController:
                                      _dedicatedMemoController,
                                  isEditMode: isEditMode,
                                  onChanged: _trackChanges,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 400,
                          child: AdditionalServiceSection(
                            controlManagementNumber: _customerService
                                .selectedCustomer
                                ?.controlManagementNumber,
                            isEditMode: isEditMode,
                            searchQuery: _pageSearchQuery,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 400,
                          child: DVRSection(
                            controlManagementNumber: _customerService
                                .selectedCustomer
                                ?.controlManagementNumber,
                            isEditMode: isEditMode,
                            searchQuery: _pageSearchQuery,
                          ),
                        ),
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

  // Widget buildExportDropdown() {
  //   return Stack(
  //     clipBehavior: Clip.none,
  //     children: [
  //       GestureDetector(
  //         onTap: () {
  //           setState(() {
  //             _isExportDropdownOpen = !_isExportDropdownOpen;
  //           });
  //         },
  //         child: Container(
  //           width: 114,
  //           height: 35,
  //           decoration: ShapeDecoration(
  //             color: const Color(0xFFD8A68A),
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(30),
  //             ),
  //           ),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               const Text(
  //                 '내보내기',
  //                 textAlign: TextAlign.center,
  //                 style: TextStyle(
  //                   color: Colors.white,
  //                   fontSize: 16,
  //                   fontFamily: 'Inter',
  //                   fontWeight: FontWeight.w700,
  //                 ),
  //               ),
  //               const SizedBox(width: 4),
  //               Icon(
  //                 _isExportDropdownOpen
  //                     ? Icons.arrow_drop_up
  //                     : Icons.arrow_drop_down,
  //                 color: Colors.white,
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //       if (_isExportDropdownOpen)
  //         Positioned(
  //           top: 45,
  //           left: 0,
  //           child: AnimatedContainer(
  //             duration: const Duration(milliseconds: 200),
  //             curve: Curves.easeOut,
  //             width: 200,
  //             decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.circular(12),
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: Colors.black.withOpacity(0.1),
  //                   blurRadius: 8,
  //                   offset: const Offset(0, 4),
  //                 ),
  //               ],
  //             ),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 _buildDropdownItem('철거요청서 출력'),
  //                 _buildDropdownItem('고객정보시트 출력'),
  //                 _buildDropdownItem('감지기/존내역 출력'),
  //                 _buildDropdownItem('무선 정보 엑셀 저장'),
  //               ],
  //             ),
  //           ),
  //         ),
  //     ],
  //   );
  // }

  // Widget _buildDropdownItem(String label) {
  //   return InkWell(
  //     onTap: () {
  //       setState(() {
  //         _isExportDropdownOpen = false;
  //       });
  //       // TODO: 각 항목별 동작 구현
  //     },
  //     child: Container(
  //       width: double.infinity,
  //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //       decoration: const BoxDecoration(
  //         border: Border(
  //           bottom: BorderSide(color: Color(0xFFE5E5E5), width: 0.5),
  //         ),
  //       ),
  //       child: Text(
  //         label,
  //         style: const TextStyle(
  //           fontSize: 14,
  //           color: Color(0xFF252525),
  //           fontWeight: FontWeight.w500,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Widget buildTopButton(String label, Color color) {
  //   return GestureDetector(
  //     onTap: () {
  //       // TODO: 버튼 동작 구현
  //     },
  //     child: Container(
  //       height: 35,
  //       padding: const EdgeInsets.symmetric(horizontal: 20),
  //       decoration: ShapeDecoration(
  //         color: color,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(30),
  //         ),
  //       ),
  //       child: Center(
  //         child: Text(
  //           label,
  //           textAlign: TextAlign.center,
  //           style: const TextStyle(
  //             color: Colors.white,
  //             fontSize: 16,
  //             fontFamily: 'Inter',
  //             fontWeight: FontWeight.w700,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
