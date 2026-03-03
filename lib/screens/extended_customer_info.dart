import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/search_panel.dart';
import '../models/customer_detail.dart';
import '../models/additional_service.dart';
import '../models/dvr_info.dart';
import '../services/api_service.dart';
import '../services/selected_customer_service.dart';
import '../widgets/time_picker_modal.dart';
import '../widgets/base_add_modal.dart';
import '../style.dart';
import '../widgets/common_table.dart';
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

  // 주간 휴일설정 - 5주 x 7일
  final List<List<bool>> _weeklyHolidays = List.generate(
    5,
    (_) => List.generate(7, (_) => false),
  );

  // 내보내기 드롭다운
  bool _isExportDropdownOpen = false;

  bool _isloading = true;

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

  // 부가서비스 데이터 목록
  List<AdditionalService> _additionalServicesList = [];

  // DVR 연동 데이터 목록
  List<DVRInfo> _dvrInfoList = [];

  // 드롭다운 데이터 목록
  List<CodeData> _companyTypeList = [];
  List<CodeData> _branchTypeList = [];
  List<CodeData> _addServiceTypeList = [];
  List<CodeData> _addServiceEtcList = [];
  List<CodeData> _dvrTypeList = [];

  final Map<int, double> _serviceColumnWidths = {
    0: 200.0, // 서비스명
    1: 150.0, // 제공구분
    2: 150.0, // 제공일자
    3: 250.0, // 메모
  };
  late final List<TableColumnConfig> // 부가서비스 테이블 컬럼 설정
  _serviceColumns = [
    TableColumnConfig(
      header: '서비스명',
      width: _serviceColumnWidths[0],
      valueBuilder: (data) => data.serviceName ?? '-',
    ),
    TableColumnConfig(
      header: '제공구분',
      width: _serviceColumnWidths[1],
      valueBuilder: (data) => data.provisionType ?? '-',
    ),
    TableColumnConfig(
      header: '제공일자',
      width: _serviceColumnWidths[2],
      valueBuilder: (data) => data.provisionDate ?? '-',
    ),
    TableColumnConfig(
      header: '메모',
      width: _serviceColumnWidths[3],
      valueBuilder: (data) => data.memo ?? '-',
    ),
  ];

  final Map<int, double> _dvrColumnWidths = {
    0: 120.0, // 접속방식
    1: 130.0, // DVR종류코드
    2: 120.0, // 종류
    3: 200.0, // 접속주소
    4: 100.0, // 접속포트
    5: 120.0, // 접속ID
    6: 120.0, // 접속암호
    7: 120.0, // 추가일자
  };
  late final List<TableColumnConfig> _dvrColumns = [
    TableColumnConfig(
      header: '접속방식',
      width: _dvrColumnWidths[0],
      valueBuilder: (data) => data.connectionMethodText,
    ),
    TableColumnConfig(
      header: 'DVR종류코드',
      width: _dvrColumnWidths[1],
      valueBuilder: (data) => data.dvrTypeCode ?? '-',
    ),
    TableColumnConfig(
      header: '종류',
      width: _dvrColumnWidths[2],
      valueBuilder: (data) => data.dvrTypeName ?? '-',
    ),
    TableColumnConfig(
      header: '접속주소',
      width: _dvrColumnWidths[3],
      valueBuilder: (data) => data.connectionAddress ?? '-',
    ),
    TableColumnConfig(
      header: '접속포트',
      width: _dvrColumnWidths[4],
      valueBuilder: (data) => data.connectionPort ?? '-',
    ),
    TableColumnConfig(
      header: '접속ID',
      width: _dvrColumnWidths[5],
      valueBuilder: (data) => data.connectionId ?? '-',
    ),
    TableColumnConfig(
      header: '접속암호',
      width: _dvrColumnWidths[6],
      valueBuilder: (data) => data.connectionPassword ?? '-',
    ),
    TableColumnConfig(
      header: '추가일자',
      width: _dvrColumnWidths[7],
      valueBuilder: (data) => data.addedDate ?? '-',
    ),
  ];
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

        // 부가서비스 및 DVR 목록 초기화
        _additionalServicesList = [];
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
    _companyTypeList = await loadDropdownData('companytype');
    _branchTypeList = await loadDropdownData('branchtype');
    _addServiceTypeList = await loadDropdownData('addservicetype');
    _addServiceEtcList = await loadDropdownData('addserviceetc');
    _dvrTypeList = await loadDropdownData('dvrtype');

    // 2. 확장고객정보 화면에서는 고객 상세 정보를 로드
    if (_customerService.selectedCustomer != null) {
      _loadedCustomerManagementNumber =
          _customerService.selectedCustomer!.controlManagementNumber;
      await _customerService.loadCustomerDetail();
    }

    // 3. 고객 데이터 로드
    await _updateUIFromService();
  }

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

      // 휴일주간, 부가서비스, DVR 데이터 로드
      if (selectedCustomer != null) {
        _updateFieldsFromDetail(detail);
        _loadHolidayData(selectedCustomer.controlManagementNumber);
        _loadAdditionalServices(selectedCustomer.controlManagementNumber);
        _loadDVRInfo(selectedCustomer.controlManagementNumber);
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

  /// 부가서비스 데이터 로드
  Future<void> _loadAdditionalServices(String managementNumber) async {
    try {
      final services = await DatabaseService.getAdditionalServices(
        managementNumber,
      );
      _isloading = true;
      if (mounted) {
        setState(() {
          _additionalServicesList = services;
          _isloading = false;
        });
      }

      print('부가서비스 데이터 로드 완료: ${services.length}개');
    } catch (e) {
      print('부가서비스 데이터 로드 오류: $e');
      _isloading = false;
    }
  }

  /// DVR 연동 정보 로드
  Future<void> _loadDVRInfo(String managementNumber) async {
    try {
      final dvrList = await DatabaseService.getDVRInfo(managementNumber);
      _isloading = true;
      if (mounted) {
        setState(() {
          _dvrInfoList = dvrList;
          _isloading = false;
        });
      }

      print('DVR 정보 로드 완료: ${dvrList.length}개');
    } catch (e) {
      print('DVR 정보 로드 오류: $e');
      _isloading = false;
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
      '평일경계시작시': _weekdayGuardStartHour,
      '평일경계시작분': _weekdayGuardStartMinute,
      '평일경계종료시': _weekdayGuardEndHour,
      '평일경계종료분': _weekdayGuardEndMinute,
      '평일무단시작시': _weekdayUnauthorizedStartHour,
      '평일무단시작분': _weekdayUnauthorizedStartMinute,
      '평일무단종료시': _weekdayUnauthorizedEndHour,
      '평일무단종료분': _weekdayUnauthorizedEndMinute,
      '평일무단사용': _isWeekdayUsed,
      '주말경계시작시': _weekendGuardStartHour,
      '주말경계시작분': _weekendGuardStartMinute,
      '주말경계종료시': _weekendGuardEndHour,
      '주말경계종료분': _weekendGuardEndMinute,
      '주말무단시작시': _weekendUnauthorizedStartHour,
      '주말무단시작분': _weekendUnauthorizedStartMinute,
      '주말무단종료시': _weekendUnauthorizedEndHour,
      '주말무단종료분': _weekendUnauthorizedEndMinute,
      '주말무단사용': _isWeekendUsed,
      '휴일경계시작시': _holidayGuardStartHour,
      '휴일경계시작분': _holidayGuardStartMinute,
      '휴일경계종료시': _holidayGuardEndHour,
      '휴일경계종료분': _holidayGuardEndMinute,
      '휴일무단시작시': _holidayUnauthorizedStartHour,
      '휴일무단시작분': _holidayUnauthorizedStartMinute,
      '휴일무단종료시': _holidayUnauthorizedEndHour,
      '휴일무단종료분': _holidayUnauthorizedEndMinute,
      '휴일무단사용': _isHolidayUsed,
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
          '평일경계': formatTime(_weekdayGuardStartHour, _weekdayGuardStartMinute),
          '평일해제': formatTime(_weekdayGuardEndHour, _weekdayGuardEndMinute),
          '평일무단범위': formatUnauthorizedRange(
            _weekdayUnauthorizedStartHour,
            _weekdayUnauthorizedStartMinute,
            _weekdayUnauthorizedEndHour,
            _weekdayUnauthorizedEndMinute,
          ),
          '평일무단사용': _isWeekdayUsed ? 1 : 0,
          '주말경계': formatTime(_weekendGuardStartHour, _weekendGuardStartMinute),
          '주말해제': formatTime(_weekendGuardEndHour, _weekendGuardEndMinute),
          '주말무단범위': formatUnauthorizedRange(
            _weekendUnauthorizedStartHour,
            _weekendUnauthorizedStartMinute,
            _weekendUnauthorizedEndHour,
            _weekendUnauthorizedEndMinute,
          ),
          '주말무단사용': _isWeekendUsed ? 1 : 0,
          '휴일경계': formatTime(_holidayGuardStartHour, _holidayGuardStartMinute),
          '휴일해제': formatTime(_holidayGuardEndHour, _holidayGuardEndMinute),
          '휴일무단범위': formatUnauthorizedRange(
            _holidayUnauthorizedStartHour,
            _holidayUnauthorizedStartMinute,
            _holidayUnauthorizedEndHour,
            _holidayUnauthorizedEndMinute,
          ),
          '휴일무단사용': _isHolidayUsed ? 1 : 0,
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
    _weekdayGuardStartHour = _originalData['평일경계시작시'];
    _weekdayGuardStartMinute = _originalData['평일경계시작분'];
    _weekdayGuardEndHour = _originalData['평일경계종료시'];
    _weekdayGuardEndMinute = _originalData['평일경계종료분'];
    _weekdayUnauthorizedStartHour = _originalData['평일무단시작시'];
    _weekdayUnauthorizedStartMinute = _originalData['평일무단시작분'];
    _weekdayUnauthorizedEndHour = _originalData['평일무단종료시'];
    _weekdayUnauthorizedEndMinute = _originalData['평일무단종료분'];
    _isWeekdayUsed = _originalData['평일무단사용'] ?? false;
    _weekendGuardStartHour = _originalData['주말경계시작시'];
    _weekendGuardStartMinute = _originalData['주말경계시작분'];
    _weekendGuardEndHour = _originalData['주말경계종료시'];
    _weekendGuardEndMinute = _originalData['주말경계종료분'];
    _weekendUnauthorizedStartHour = _originalData['주말무단시작시'];
    _weekendUnauthorizedStartMinute = _originalData['주말무단시작분'];
    _weekendUnauthorizedEndHour = _originalData['주말무단종료시'];
    _weekendUnauthorizedEndMinute = _originalData['주말무단종료분'];
    _isWeekendUsed = _originalData['주말무단사용'] ?? false;
    _holidayGuardStartHour = _originalData['휴일경계시작시'];
    _holidayGuardStartMinute = _originalData['휴일경계시작분'];
    _holidayGuardEndHour = _originalData['휴일경계종료시'];
    _holidayGuardEndMinute = _originalData['휴일경계종료분'];
    _holidayUnauthorizedStartHour = _originalData['휴일무단시작시'];
    _holidayUnauthorizedStartMinute = _originalData['휴일무단시작분'];
    _holidayUnauthorizedEndHour = _originalData['휴일무단종료시'];
    _holidayUnauthorizedEndMinute = _originalData['휴일무단종료분'];
    _isHolidayUsed = _originalData['휴일무단사용'] ?? false;

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
            final isExtraWideScreen = constraints.maxWidth >= 1500;
            final isWideScreen = constraints.maxWidth >= 900;

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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [_buildSecuritySettingsSection()],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildCustomerMemoSection(),
                                  const SizedBox(height: 16),
                                  _buildCompanyBranchSection(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildGPSSection(),
                                  const SizedBox(height: 16),
                                  _buildDedicatedLineSection(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [_buildWeeklyHolidaySettings()],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 400,
                          child: SizedBox(height: 400, child: _buildService()),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(height: 400, child: _buildDVR()),
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
                              child: _buildCustomerMemoSection(),
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
                        SizedBox(height: 400, child: _buildService()),
                        const SizedBox(height: 24),
                        SizedBox(height: 400, child: _buildDVR()),
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
                        SizedBox(height: 400, child: _buildService()),
                        const SizedBox(height: 24),
                        SizedBox(height: 400, child: _buildDVR()),
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

  _buildService() {
    return buildTable(
      context: context,
      title: '부가서비스 제공',
      dataList: _additionalServicesList,
      columns: _serviceColumns,
      columnWidths: _serviceColumnWidths,
      onColumnResize: (columnIndex, newWidth) {
        setState(() {
          _serviceColumnWidths[columnIndex] = newWidth;
        });
      },
      searchQuery: _pageSearchQuery,
      isLoading: _isloading,
      onAdd: isEditMode
          ? () {
              _showAddServiceModal();
            }
          : null,
      onDelete: isEditMode
          ? (service) {
              _showDeleteServiceConfirmDialog(service as AdditionalService);
            }
          : null,
      isEditable: isEditMode,
    );
  }

  _buildDVR() {
    return buildTable(
      context: context,
      title: 'DVR 설치현황',
      dataList: _dvrInfoList,
      columns: _dvrColumns,
      columnWidths: _dvrColumnWidths,
      onColumnResize: (columnIndex, newWidth) {
        setState(() {
          _dvrColumnWidths[columnIndex] = newWidth;
        });
      },
      searchQuery: _pageSearchQuery,
      isLoading: _isloading,
      onAdd: isEditMode
          ? () {
              _showAddDVRModal();
            }
          : null,
      onDelete: isEditMode
          ? (dvr) {
              _showDeleteDVRConfirmDialog(dvr as DVRInfo);
            }
          : null,
      isEditable: isEditMode,
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
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
        border: isEditMode
            ? Border.all(color: context.colors.selectedColor, width: 1)
            : null,
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
        color: context.colors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.cardBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 17,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(color: context.colors.dividerColor),
                const SizedBox(height: 12),
                TimePickerButton(
                  label: '경계',
                  hour: guardStartHour,
                  minute: guardStartMinute,
                  allowNull: true,
                  enabled: isEditMode,
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
                    _trackChanges();
                  },
                ),
                const SizedBox(height: 12),
                Divider(color: context.colors.dividerColor),
                const SizedBox(height: 12),
                TimePickerButton(
                  label: '해제',
                  hour: guardEndHour,
                  minute: guardEndMinute,
                  allowNull: true,
                  enabled: isEditMode,
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
                    _trackChanges();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.cardBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      '무단',
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Spacer(),

                    BuildCheckbox(
                      label: '사용',
                      value: isUsed,
                      readOnly: !isEditMode,
                      onChanged: (val) {
                        setState(() {
                          if (isWeekday == true) {
                            _isWeekdayUsed = val;
                          } else if (isWeekday == false) {
                            _isWeekendUsed = val;
                          } else {
                            _isHolidayUsed = val;
                          }
                        });
                        _trackChanges();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: context.colors.dividerColor),
                const SizedBox(height: 12),
                TimePickerButton(
                  label: '경계',
                  hour: unauthStartHour,
                  minute: unauthStartMinute,
                  enabled: isUsed && isEditMode,
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
                    _trackChanges();
                  },
                ),
                const SizedBox(height: 12),
                Divider(color: context.colors.dividerColor),
                const SizedBox(height: 12),
                TimePickerButton(
                  label: '해제',
                  hour: unauthEndHour,
                  minute: unauthEndMinute,
                  enabled: isUsed && isEditMode,
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
                    _trackChanges();
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
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
        border: isEditMode
            ? Border.all(color: context.colors.selectedColor, width: 1)
            : null,
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
              const SizedBox(width: 27), // 주차 번호 공간
              ...days.asMap().entries.map((entry) {
                return Expanded(
                  child: Center(
                    child: Text(
                      entry.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.colors.textPrimary,
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
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 주차 번호
                  Container(
                    width: 25,
                    height: 25,
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
                    Color bgColor = isEditMode
                        ? context.colors.textPrimary
                        : context.colors.white;
                    Color checkColor = isEditMode
                        ? context.colors.cardBackground
                        : context.colors.white;
                    if (dayIndex == 0) {
                      // 일요일
                      bgColor = const Color(0xFFFF7070);
                      checkColor = isEditMode
                          ? context.colors.white
                          : Color(0xFFFF7070);
                    } else if (dayIndex == 6) {
                      // 토요일
                      bgColor = const Color(0xFF87C5FF);
                      checkColor = isEditMode
                          ? context.colors.white
                          : Color(0xFF87C5FF);
                    }

                    return Expanded(
                      child: Center(
                        child: Transform.scale(
                          scale: 0.85,
                          child: Theme(
                            data: ThemeData(
                              checkboxTheme: CheckboxThemeData(
                                side: BorderSide(
                                  color: context.colors.textSecondary,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                            child: Checkbox(
                              value: _weeklyHolidays[weekIndex][dayIndex],
                              onChanged: isEditMode
                                  ? (value) {
                                      setState(() {
                                        _weeklyHolidays[weekIndex][dayIndex] =
                                            value ?? false;
                                      });
                                      _trackChanges();
                                    }
                                  : null,
                              activeColor: bgColor,
                              checkColor: checkColor,
                              side: BorderSide(
                                color: context.colors.textSecondary,
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
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
        border: isEditMode
            ? Border.all(color: context.colors.selectedColor, width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('고객 추가 메모사항'),
          const SizedBox(height: 12),
          CommonTextField(
            label: '개통일자',
            controller: _openingDateController,
            searchQuery: _pageSearchQuery,
            readOnly: !isEditMode,
            onFocusLost: _trackChanges,
          ),
          const SizedBox(height: 12),
          CommonTextField(
            label: '개통전화번호',
            controller: _openingPhoneController,
            searchQuery: _pageSearchQuery,
            readOnly: !isEditMode,
            onFocusLost: _trackChanges,
          ),
          const SizedBox(height: 12),
          CommonTextField(
            label: '모뎀일련번호',
            controller: _modemSerialController,
            searchQuery: _pageSearchQuery,
            readOnly: !isEditMode,
            onFocusLost: _trackChanges,
          ),
          const SizedBox(height: 12),
          CommonTextField(
            label: '추가메모',
            controller: _additionalMemoController,
            searchQuery: _pageSearchQuery,
            readOnly: !isEditMode,
            onFocusLost: _trackChanges,
          ),
        ],
      ),
    );
  }

  Widget _buildGPSSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
        border: isEditMode
            ? Border.all(color: context.colors.selectedColor, width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('고객 GPS 좌표'),
          const SizedBox(height: 12),
          CommonTextField(
            label: 'X 좌표1',
            controller: _gpsX1Controller,
            readOnly: !isEditMode,
            onFocusLost: _trackChanges,
          ),
          const SizedBox(height: 12),
          CommonTextField(
            label: 'Y 좌표1',
            controller: _gpsY1Controller,
            readOnly: !isEditMode,
            onFocusLost: _trackChanges,
          ),
          const SizedBox(height: 12),
          CommonTextField(
            label: 'X 좌표2',
            controller: _gpsX2Controller,
            readOnly: !isEditMode,
            onFocusLost: _trackChanges,
          ),
          const SizedBox(height: 12),
          CommonTextField(
            label: 'Y 좌표2',
            controller: _gpsY2Controller,
            readOnly: !isEditMode,
            onFocusLost: _trackChanges,
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyBranchSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
        border: isEditMode
            ? Border.all(color: context.colors.selectedColor, width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('회사 / 지사 구분'),
          const SizedBox(height: 12),
          BuildDropdownField(
            label: '회사구분',
            value: companyType,
            items: _companyTypeList,
            searchQuery: _pageSearchQuery,
            onChanged: (String? newValue) {
              setState(() {
                companyType = newValue!;
              });
              _trackChanges();
            },
            onFocusLost: _trackChanges,
            readOnly: !isEditMode,
          ),
          const SizedBox(height: 12),
          BuildDropdownField(
            label: '지사구분',
            value: branchType,
            items: _branchTypeList,
            searchQuery: _pageSearchQuery,
            onChanged: (String? newValue) {
              setState(() {
                branchType = newValue!;
              });
              _trackChanges();
            },
            onFocusLost: _trackChanges,
            readOnly: !isEditMode,
          ),
        ],
      ),
    );
  }

  Widget _buildDedicatedLineSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
        border: isEditMode
            ? Border.all(color: context.colors.selectedColor, width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('전용회선 관리'),
          const SizedBox(height: 12),
          CommonTextField(
            label: '전용회선 번호',
            controller: _dedicatedNumberController,
            readOnly: !isEditMode,
            onFocusLost: _trackChanges,
          ),
          const SizedBox(height: 12),
          CommonTextField(
            label: '추가메모',
            controller: _dedicatedMemoController,
            readOnly: !isEditMode,
            onFocusLost: _trackChanges,
          ),
        ],
      ),
    );
  }

  /// 부가서비스 추가 모달 표시
  void _showAddServiceModal() {
    final managementNumber =
        _customerService.selectedCustomer?.controlManagementNumber;
    if (managementNumber == null) return;

    showDialog(
      context: context,
      builder: (context) => _AddServiceModal(
        controlManagementNumber: managementNumber,
        serviceTypeList: _addServiceTypeList,
        serviceEtcList: _addServiceEtcList,
        onSaved: () async {
          // 데이터 새로고침
          await _loadAdditionalServices(managementNumber);
        },
      ),
    );
  }

  /// DVR 추가 모달 표시
  void _showAddDVRModal() {
    final managementNumber =
        _customerService.selectedCustomer?.controlManagementNumber;
    if (managementNumber == null) return;

    showDialog(
      context: context,
      builder: (context) => _AddDVRModal(
        controlManagementNumber: managementNumber,
        dvrTypeList: _dvrTypeList,
        onSaved: () async {
          // 데이터 새로고침
          await _loadDVRInfo(managementNumber);
        },
      ),
    );
  }

  /// 부가서비스 삭제 확인 다이얼로그
  void _showDeleteServiceConfirmDialog(AdditionalService service) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('삭제 확인'),
          content: Text('${service.serviceName ?? "부가서비스"}를 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: context.colors.gray30,
                backgroundColor: context.colors.secondBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('아니오'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteAdditionalService(service);
              },
              style: TextButton.styleFrom(
                foregroundColor: context.colors.textPrimary,
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

  /// 부가서비스 삭제 실행
  Future<void> _deleteAdditionalService(AdditionalService service) async {
    if (service.managementId == null) {
      if (mounted) {
        showToast(context, message: '삭제할 수 없는 항목입니다.');
      }
      return;
    }

    try {
      final success = await DatabaseService.deleteAdditionalService(
        managementId: service.managementId!,
      );

      if (mounted) {
        if (success) {
          showToast(context, message: '부가서비스가 삭제되었습니다.');
          // 데이터 새로고침
          final managementNumber =
              _customerService.selectedCustomer?.controlManagementNumber;
          if (managementNumber != null) {
            await _loadAdditionalServices(managementNumber);
          }
        } else {
          showToast(context, message: '삭제에 실패했습니다.');
        }
      }
    } catch (e) {
      if (mounted) {
        showToast(context, message: '오류가 발생했습니다: $e');
      }
    }
  }

  /// DVR 삭제 확인 다이얼로그
  void _showDeleteDVRConfirmDialog(DVRInfo dvr) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('삭제 확인'),
          content: Text('${dvr.dvrTypeName ?? "DVR"}을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: context.colors.textPrimary,
                backgroundColor: context.colors.secondBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('아니오'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteDVR(dvr);
              },
              style: TextButton.styleFrom(
                foregroundColor: context.colors.textPrimary,
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

  /// DVR 삭제 실행
  Future<void> _deleteDVR(DVRInfo dvr) async {
    try {
      final success = await DatabaseService.deleteDVR(
        serialNumber: dvr.serialNumber,
      );

      if (mounted) {
        if (success) {
          showToast(context, message: 'DVR정보가 삭제되었습니다.');
          // 데이터 새로고침
          final managementNumber =
              _customerService.selectedCustomer?.controlManagementNumber;
          if (managementNumber != null) {
            await _loadDVRInfo(managementNumber);
          }
        } else {
          showToast(context, message: '삭제에 실패했습니다.');
        }
      }
    } catch (e) {
      if (mounted) {
        showToast(context, message: '오류가 발생했습니다: $e');
      }
    }
  }
}

// ========================================
// 부가서비스 추가 모달
// ========================================

class _AddServiceModal extends BaseAddModal {
  final String controlManagementNumber;
  final List<CodeData> serviceTypeList;
  final List<CodeData> serviceEtcList;

  const _AddServiceModal({
    required this.controlManagementNumber,
    required this.serviceTypeList,
    required this.serviceEtcList,
    required super.onSaved,
  });

  @override
  State<_AddServiceModal> createState() => _AddServiceModalState();
}

class _AddServiceModalState extends BaseAddModalState<_AddServiceModal> {
  String? _selectedServiceType;
  String? _selectedServiceEtc;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  @override
  void dispose() {
    _dateController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  String get modalTitle => '부가서비스 추가';

  @override
  String get saveButtonLabel => '추가';

  @override
  Future<bool> validateAndSave() async {
    if (_selectedServiceType == null || _selectedServiceType!.isEmpty) {
      showToast(context, message: '부가서비스를 선택해주세요.');
      return false;
    }

    if (_dateController.text.isEmpty) {
      showToast(context, message: '날짜를 입력해주세요.');
      return false;
    }

    try {
      final success = await DatabaseService.insertAdditionalService(
        controlManagementNumber: widget.controlManagementNumber,
        serviceCode: _selectedServiceType!,
        serviceEtcCode: _selectedServiceEtc,
        serviceDate: _dateController.text,
        memo: _memoController.text,
      );

      return success;
    } catch (e) {
      print('부가서비스 추가 오류: $e');
      return false;
    }
  }

  @override
  Widget buildFormFields() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            DateTextField(
              label: '제공일자',
              controller: _dateController,
              onCalendarPressed: (context, isStartDate) async {
                final selectedDate = await showDatePickerDialog(context);
                if (selectedDate != null) {
                  setState(() {
                    _dateController.text = recordDateFormatted(selectedDate);
                  });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: BuildDropdownField(
                label: '부가서비스',
                value: _selectedServiceType,
                items: widget.serviceTypeList,
                searchQuery: '',
                onChanged: (value) {
                  setState(() {
                    _selectedServiceType = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: BuildDropdownField(
                label: '부가서비스제공',
                value: _selectedServiceEtc,
                items: widget.serviceEtcList,
                searchQuery: '',
                onChanged: (value) {
                  setState(() {
                    _selectedServiceEtc = value;
                  });
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        CommonTextField(label: '비고', controller: _memoController, maxLines: 3),
      ],
    );
  }
}

// ========================================
// DVR 추가 모달
// ========================================

class _AddDVRModal extends BaseAddModal {
  final String controlManagementNumber;
  final List<CodeData> dvrTypeList;

  const _AddDVRModal({
    required this.controlManagementNumber,
    required this.dvrTypeList,
    required super.onSaved,
  });

  @override
  State<_AddDVRModal> createState() => _AddDVRModalState();
}

class _AddDVRModalState extends BaseAddModalState<_AddDVRModal> {
  bool _isCSMethod = true; // true: CS방식, false: 웹방식
  String? _selectedDVRType;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _serialController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    _portController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _serialController.dispose();
    super.dispose();
  }

  @override
  String get modalTitle => 'DVR 설치현황 추가';

  @override
  String get saveButtonLabel => '추가';

  @override
  Future<bool> validateAndSave() async {
    if (_selectedDVRType == null || _selectedDVRType!.isEmpty) {
      showToast(context, message: 'DVR종류를 선택해주세요.');
      return false;
    }

    if (_addressController.text.isEmpty) {
      showToast(context, message: 'DVR주소를 입력해주세요.');
      return false;
    }

    try {
      final success = await DatabaseService.insertDVR(
        controlManagementNumber: widget.controlManagementNumber,
        connectionMethod: _isCSMethod ? 0 : 1, // CS방식=0, 웹방식=1
        dvrTypeCode: _selectedDVRType!,
        connectionAddress: _addressController.text,
        connectionPort: _portController.text,
        connectionId: _idController.text,
        connectionPassword: _passwordController.text,
        serialNumber: _serialController.text,
      );

      return success;
    } catch (e) {
      print('DVR 추가 오류: $e');
      return false;
    }
  }

  @override
  Widget buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // DVR 종류 (라디오버튼 + 드롭다운)
        const SizedBox(height: 8),
        Row(
          children: [
            BuildRadioOption(
              label: 'CS방식',
              value: _isCSMethod,
              onChanged: (value) {
                setState(() {
                  _isCSMethod = true;
                });
              },
            ),

            BuildRadioOption(
              label: '웹방식',
              value: !_isCSMethod,
              onChanged: (value) {
                setState(() {
                  _isCSMethod = false;
                });
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: BuildDropdownField(
                label: 'DVR종류',
                value: _selectedDVRType,
                items: widget.dvrTypeList,
                searchQuery: '',
                onChanged: (value) {
                  setState(() {
                    _selectedDVRType = value;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 4,
              child: CommonTextField(
                label: 'DVR주소',
                controller: _addressController,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: CommonTextField(
                label: '포트',
                controller: _portController,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CommonTextField(label: '아이디', controller: _idController),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CommonTextField(
                label: '패스워드',
                controller: _passwordController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CommonTextField(label: 'DVR시리얼N', controller: _serialController),
      ],
    );
  }
}
