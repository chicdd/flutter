import 'package:flutter/material.dart';
import '../component/additionalServiceSection.dart';
import '../component/companyBranchSection.dart';
import '../component/customerBasicInfoSection.dart';
import '../component/customerDetailInfoSection.dart';
import '../component/dedicatedLineSection.dart';
import '../component/gpsSection.dart';
import '../component/customerMemoExtendedSection.dart';
import '../component/customerMemoSection.dart';
import '../component/customerPropertyInfoSection.dart';
import '../component/dvrSection.dart';
import '../component/securitySettingSection.dart';
import '../component/weeklyHolidaySection.dart';
import '../functions.dart';
import '../models/customer_form_data.dart';
import '../models/search_panel.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../style.dart';
import '../widgets/time_picker_modal.dart';

class CustomerRegistration extends StatefulWidget {
  final SearchPanel? searchpanel;

  const CustomerRegistration({super.key, this.searchpanel});

  @override
  State<CustomerRegistration> createState() => CustomerRegistrationState();
}

class CustomerRegistrationState extends State<CustomerRegistration>
    with TickerProviderStateMixin {
  late TabController _tabController;
  // ========================================
  // 관제 물건 정보
  // ========================================
  // final _controlTypeController = TextEditingController(); // 관제상호명
  // final _smsNameController = TextEditingController(); // SMS용 상호
  // final _contact1Controller = TextEditingController(); // 관제연락처1
  // final _contact2Controller = TextEditingController(); // 관제연락처2
  // final _addressController = TextEditingController(); // 물건지주소
  // final _referenceController = TextEditingController(); // 대처경로
  // final _representativeNameController = TextEditingController(); // 대표자 이름
  // final _representativePhoneController = TextEditingController(); // 대표자H.P
  //
  // // ========================================
  // // 관제 기본 정보
  // // ========================================
  // final _managementNumberController = TextEditingController(); // 관제관리번호
  // final _erpCusNumberController = TextEditingController(); // 영업관리번호
  // final _publicNumberController = TextEditingController(); // 공중회선
  // final _transmissionNumberController = TextEditingController(); // 전용회선
  // final _publicTransmissionController = TextEditingController(); // 인터넷회선
  // final _remoteCodeController = TextEditingController(); // 원격포트구분
  // final _emergencyContactController = TextEditingController(); // 기관연락처
  // final _securityStartDateController = TextEditingController(); // 경비개시일자
  //
  // String? _selectedCustomerStatus; // 관제고객상태
  // String? _selectedManagementArea; // 관리구역
  // String? _selectedOperationArea; // 출동권역
  // String? _selectedBusinessType; // 업종코드
  // String? _selectVehicleCode; // 차량코드
  // String? _selectedCallLocation; // 관할경찰서
  // String? _selectedCallArea; // 지구대

  // ========================================
  // 관제 세부 정보
  // ========================================
  // String? _selectedUsageType; // 주사용회선
  // String? _selectedServiceType; // 서비스종류
  // String? _selectedMainSystem; // 기기종류
  // String? _selectedSubSystem; // 주장치 분류
  // final _mainLocationController = TextEditingController(); // 주장치위치
  // final _remotePhoneController = TextEditingController(); // 원격전화
  // final _remotePasswordController = TextEditingController(); // 원격암호
  // final _arsPhoneController = TextEditingController(); // ARS전화
  // String? _selectedMiSettings; // 미경계 설정
  // bool _monthlyAggregation = false; // 월간집계
  // bool _hasKeyHolder = false; // 키 인수여부
  // final _acquisitionController = TextEditingController(); // 인수수량
  // final _keyBoxesController = TextEditingController(); // 키BOX
  // final _keypadController = TextEditingController(); // 키패드
  // final _keypadQuantityController = TextEditingController(); // 키패드수량
  // final _emergencyPhoneController = TextEditingController(); // 연동전화번호
  // bool _isDvrInspection = false; // DVR여부
  // bool _isWirelessSensorInspection = false; // 무선센서설치여부

  // 연동전화번호 목록
  List<String> _linkedPhoneNumbers = [];

  // 페이지 내 검색
  String _pageSearchQuery = '';

  // 검색 쿼리 업데이트 메서드
  void updateSearchQuery(String query) {
    setState(() {
      _pageSearchQuery = query;
    });
  }

  // 공유 폼 데이터
  final _formData = CustomerFormData();

  // FocusNode for TextFormFields
  final _controlActionFocusNode = FocusNode();
  final _memoFocusNode = FocusNode();
  // // ========================================
  // // 관제 액션 비고
  // // ========================================
  // int _selectedMemoTab = 0;
  // final _controlActionController = TextEditingController(); // 관제액션비고
  // final _memo1Controller = TextEditingController(); // 메모1
  // final _memo2Controller = TextEditingController(); // 메모2
  //
  // // ========================================
  // // 경계약정 및 무단해제 설정 - 평일
  // // ========================================
  // int? _weekdayGuardStartHour;
  // int? _weekdayGuardStartMinute;
  // int? _weekdayGuardEndHour;
  // int? _weekdayGuardEndMinute;
  // int? _weekdayUnauthorizedStartHour;
  // int? _weekdayUnauthorizedStartMinute;
  // int? _weekdayUnauthorizedEndHour;
  // int? _weekdayUnauthorizedEndMinute;
  // bool _isWeekdayUsed = false;
  //
  // // ========================================
  // // 경계약정 및 무단해제 설정 - 주말
  // // ========================================
  // int? _weekendGuardStartHour;
  // int? _weekendGuardStartMinute;
  // int? _weekendGuardEndHour;
  // int? _weekendGuardEndMinute;
  // int? _weekendUnauthorizedStartHour;
  // int? _weekendUnauthorizedStartMinute;
  // int? _weekendUnauthorizedEndHour;
  // int? _weekendUnauthorizedEndMinute;
  // bool _isWeekendUsed = false;
  //
  // // ========================================
  // // 경계약정 및 무단해제 설정 - 휴일
  // // ========================================
  // int? _holidayGuardStartHour;
  // int? _holidayGuardStartMinute;
  // int? _holidayGuardEndHour;
  // int? _holidayGuardEndMinute;
  // int? _holidayUnauthorizedStartHour;
  // int? _holidayUnauthorizedStartMinute;
  // int? _holidayUnauthorizedEndHour;
  // int? _holidayUnauthorizedEndMinute;
  // bool _isHolidayUsed = false;
  //
  // // ========================================
  // // 주간 휴일설정
  // // ========================================
  // final List<List<bool>> _weeklyHolidays = List.generate(
  //   5,
  //   (_) => List.generate(7, (_) => false),
  // );
  //
  // // ========================================
  // // 고객 추가 메모사항
  // // ========================================
  // final _openingPhoneController = TextEditingController(); // 개통전화번호
  // final _openingDateController = TextEditingController(); // 개통일자
  // final _modemSerialController = TextEditingController(); // 모뎀일련번호
  // final _additionalMemoController = TextEditingController(); // 추가메모
  //
  // // ========================================
  // // 고객 GPS 좌표
  // // ========================================
  // final _gpsX1Controller = TextEditingController();
  // final _gpsY1Controller = TextEditingController();
  // final _gpsX2Controller = TextEditingController();
  // final _gpsY2Controller = TextEditingController();
  //
  // // ========================================
  // // 회사 / 지사 구분
  // // ========================================
  // String? companyType;
  // String? branchType;
  //
  // // ========================================
  // // 전용회선 관리
  // // ========================================
  // final _dedicatedNumberController = TextEditingController();
  // final _dedicatedMemoController = TextEditingController();
  //
  // // ========================================
  // // 드롭다운 데이터 목록
  // // ========================================
  // List<CodeData> _managementAreaList = [];
  // List<CodeData> _operationAreaList = [];
  // List<CodeData> _businessTypeList = [];
  // List<CodeData> _vehicleCodeList = [];
  // List<CodeData> _policeStationList = [];
  // List<CodeData> _policeDistrictList = [];
  // List<CodeData> _usageLineList = [];
  // List<CodeData> _serviceTypeList = [];
  // List<CodeData> _mainSystemList = [];
  // List<CodeData> _subSystemList = [];
  // List<CodeData> _miSettingsList = [];
  // List<CodeData> _customerStatusList = [];
  // List<CodeData> companyTypeList = [];
  // List<CodeData> branchTypeList = [];
  //List<CodeData> _addServiceTypeList = [];
  // List<CodeData> _addServiceEtcList = [];
  //List<CodeData> _dvrTypeList = [];
  //
  // // ========================================
  // // 부가서비스 제공
  // // ========================================
  // String? _newAsServiceCode;
  // String? _newAsProvisionCode;
  // final _newAsDateController = TextEditingController();
  // final _newAsMemoController = TextEditingController();
  // final TextEditingController _dateController = TextEditingController();
  // List<Map<String, dynamic>> _additionalServiceItems = [];
  //
  // // ========================================
  // // DVR 설치현황
  // // ========================================
  // bool _newDvrConnectionMethod = false; // false=CS, true=WEB
  // String? _newDvrTypeCode;
  // final _newDvrAddressController = TextEditingController();
  // final _newDvrPortController = TextEditingController();
  // final _newDvrIdController = TextEditingController();
  // final _newDvrPasswordController = TextEditingController();
  // final _dvrSNController = TextEditingController();
  // List<Map<String, dynamic>> _dvrItems = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _formData.initializeData().then((_) {
      if (mounted) setState(() {});
    });
  }

  // @override
  // void dispose() {
  //   // 관제 물건 정보
  //   _controlTypeController.dispose();
  //   _smsNameController.dispose();
  //   _contact1Controller.dispose();
  //   _contact2Controller.dispose();
  //   _addressController.dispose();
  //   _referenceController.dispose();
  //   _representativeNameController.dispose();
  //   _representativePhoneController.dispose();
  //
  //   // 관제 기본 정보
  //   _managementNumberController.dispose();
  //   _erpCusNumberController.dispose();
  //   _publicNumberController.dispose();
  //   _transmissionNumberController.dispose();
  //   _publicTransmissionController.dispose();
  //   _remoteCodeController.dispose();
  //   _emergencyContactController.dispose();
  //   _securityStartDateController.dispose();
  //
  //   // 관제 세부 정보
  //   // _mainLocationController.dispose();
  //   // _remotePhoneController.dispose();
  //   // _remotePasswordController.dispose();
  //   // _arsPhoneController.dispose();
  //   // _acquisitionController.dispose();
  //   // _keyBoxesController.dispose();
  //   // _keypadController.dispose();
  //   // _keypadQuantityController.dispose();
  //   // _emergencyPhoneController.dispose();
  //
  //   // 관제 액션 비고
  //   _controlActionController.dispose();
  //   _memo1Controller.dispose();
  //   _memo2Controller.dispose();
  //
  //   // 고객 추가 메모사항
  //   _openingPhoneController.dispose();
  //   _openingDateController.dispose();
  //   _modemSerialController.dispose();
  //   _additionalMemoController.dispose();
  //
  //   // GPS 좌표
  //   _gpsX1Controller.dispose();
  //   _gpsY1Controller.dispose();
  //   _gpsX2Controller.dispose();
  //   _gpsY2Controller.dispose();
  //
  //   // 전용회선
  //   _dedicatedNumberController.dispose();
  //   _dedicatedMemoController.dispose();
  //
  //   // 부가서비스
  //   _newAsDateController.dispose();
  //   _newAsMemoController.dispose();
  //
  //   // DVR
  //   _newDvrAddressController.dispose();
  //   _newDvrPortController.dispose();
  //   _newDvrIdController.dispose();
  //   _newDvrPasswordController.dispose();
  //   _dvrSNController.dispose();
  //
  //   _tabController.dispose();
  //
  //   super.dispose();
  // }

  // /// 드롭다운 데이터 로드
  // Future<void> _loadDropdownData() async {
  //   setState(() {
  //     _isLoading = true;
  //   });
  //
  //   _managementAreaList = await loadDropdownData('managementarea');
  //   _operationAreaList = await loadDropdownData('operationarea');
  //   _businessTypeList = await loadDropdownData('businesstype');
  //   _vehicleCodeList = await loadDropdownData('vehiclecode');
  //   _policeStationList = await loadDropdownData('policestation');
  //   _policeDistrictList = await loadDropdownData('policedistrict');
  //   _usageLineList = await loadDropdownData('usageline');
  //   _serviceTypeList = await loadDropdownData('servicetype');
  //   _mainSystemList = await loadDropdownData('mainsystem');
  //   _subSystemList = await loadDropdownData('subsystem');
  //   _miSettingsList = await loadDropdownData('misettings');
  //   _customerStatusList = await loadDropdownData('customerstatus');
  //   companyTypeList = await loadDropdownData('companytype');
  //   branchTypeList = await loadDropdownData('branchtype');
  //   _addServiceTypeList = await loadDropdownData('addservicetype');
  //   _addServiceEtcList = await loadDropdownData('addserviceetc');
  //   _dvrTypeList = await loadDropdownData('dvrtype');
  //
  //   // CustomerDetailInfoSection이 사용하는 _formData의 리스트도 동기화
  //   _formData.managementAreaList = _managementAreaList;
  //   _formData.operationAreaList = _operationAreaList;
  //   _formData.businessTypeList = _businessTypeList;
  //   _formData.vehicleCodeList = _vehicleCodeList;
  //   _formData.policeStationList = _policeStationList;
  //   _formData.policeDistrictList = _policeDistrictList;
  //   _formData.usageLineList = _usageLineList;
  //   _formData.serviceTypeList = _serviceTypeList;
  //   _formData.mainSystemList = _mainSystemList;
  //   _formData.subSystemList = _subSystemList;
  //   _formData.miSettingsList = _miSettingsList;
  //   _formData.customerStatusList = _customerStatusList;
  //   _formData.companyTypeList = companyTypeList;
  //   _formData.branchTypeList = branchTypeList;
  //
  //   if (mounted) {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //   }
  // }

  /// 입력 검증
  bool _validateInputs() {
    bool hasError = false;

    _formData.errorManagementNumber =
        _formData.managementNumberController.text.isEmpty;
    _formData.errorControlType = _formData.controlTypeController.text.isEmpty;
    _formData.errorManagementArea = _formData.selectedManagementArea == null;
    _formData.errorMainSystem = _formData.selectedMainSystem == null;

    if (_formData.errorManagementNumber) {
      showToast(context, message: '관제관리번호는 필수입니다.');
      hasError = true;
    }
    if (_formData.errorControlType) {
      showToast(context, message: '관제상호명은 필수입니다.');
      hasError = true;
    }
    if (_formData.errorManagementArea) {
      showToast(context, message: '관리구역 선택은 필수입니다.');
      hasError = true;
    }
    if (_formData.errorMainSystem) {
      showToast(context, message: '주장치종류 선택은 필수입니다.');
      hasError = true;
    }

    setState(() {});
    return !hasError;
  }

  /// 고객 등록 저장
  Future<void> saveCustomer() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
    });

    try {
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

      // 고객 등록 API 호출 (기본 정보 + 확장 정보)
      final success = await DatabaseService.insertCustomer(
        managementNumber: _formData.managementNumberController.text,
        data: {
          // 기본 정보
          '관제관리번호': _formData.managementNumberController.text,
          '고객관리번호': _formData.erpCusNumberController.text,
          '관제상호': _formData.controlTypeController.text,
          '고객용상호': _formData.smsNameController.text,
          '관제연락처1': _formData.contact1Controller.text,
          '관제연락처2': _formData.contact2Controller.text,
          '물건주소': _formData.addressController.text,
          '대처경로1': _formData.referenceController.text,
          '대표자': _formData.representativeNameController.text,
          '대표자HP': _formData.representativePhoneController.text,
          '공중회선': _formData.publicNumberController.text,
          '전용회선': _formData.transmissionNumberController.text,
          '인터넷회선': _formData.publicTransmissionController.text,
          '원격포트': _formData.remoteCodeController.text,
          '소방서코드': _formData.emergencyContactController.text,
          '개통일자': _formData.securityStartDateController.text.isEmpty
              ? null
              : '${_formData.securityStartDateController.text} 00:00:00.000',
          '관제고객상태코드': _formData.selectedCustomerStatus,
          '관리구역코드': _formData.selectedManagementArea,
          '출동권역코드': _formData.selectedOperationArea,
          '업종대코드': _formData.selectedBusinessType,
          '차량코드': _formData.selectVehicleCode,
          '경찰서코드': _formData.selectedCallLocation,
          '지구대코드': _formData.selectedCallArea,
          '사용회선종류': _formData.selectedUsageType,
          '서비스종류코드': _formData.selectedServiceType,
          '기기종류코드': _formData.selectedMainSystem,
          '미경계분류코드': _formData.selectedSubSystem,
          '주장치위치': _formData.mainLocationController.text,
          '원격전화번호': _formData.remotePhoneController.text,
          '원격암호': _formData.remotePasswordController.text,
          'ARS전화번호': _formData.arsPhoneController.text,
          '미경계종류코드': _formData.selectedMiSettings,
          '월간집계': _formData.monthlyAggregation ? 1 : 0,
          '키인수여부': _formData.hasKeyHolder ? 1 : 0,
          'TMP1': _formData.acquisitionController.text,
          '키박스번호': _formData.keyBoxesController.text,
          'TMP2': _formData.keypadController.text,
          'TMP3': _formData.keypadQuantityController.text,
          'DVR여부': _formData.isDvrInspection ? 1 : 0,
          'TMP8': _formData.isWirelessSensorInspection ? 1 : 0,
          '관제액션': _formData.controlActionController.text,
          '메모': _formData.memo1Controller.text,
          '메모2': _formData.memo2Controller.text,

          // 확장 정보
          'cu1': _formData.openingPhoneController.text,
          'cu2': _formData.modemSerialController.text,
          'cu3': _formData.openingDateController.text,
          'cu4': _formData.additionalMemoController.text,
          'tmP4': _formData.gpsX1Controller.text,
          'tmP5': _formData.gpsY1Controller.text,
          'tmP6': _formData.gpsX2Controller.text,
          'tmP7': _formData.gpsY2Controller.text,
          '전용자번호': _formData.dedicatedNumberController.text,
          '전용자메모': _formData.dedicatedMemoController.text,
          '회사구분코드': _formData.selectedCompanyType,
          '지사구분코드': _formData.selectedBranchType,
          '평일경계': formatTime(
            _formData.weekdayGuardStartHour,
            _formData.weekdayGuardStartMinute,
          ),
          '평일해제': formatTime(
            _formData.weekdayGuardEndHour,
            _formData.weekdayGuardEndMinute,
          ),
          '평일무단범위': formatUnauthorizedRange(
            _formData.weekdayUnauthorizedStartHour,
            _formData.weekdayUnauthorizedStartMinute,
            _formData.weekdayUnauthorizedEndHour,
            _formData.weekdayUnauthorizedEndMinute,
          ),
          '평일무단사용': _formData.isWeekdayUsed ? 1 : 0,
          '주말경계': formatTime(
            _formData.weekendGuardStartHour,
            _formData.weekendGuardStartMinute,
          ),
          '주말해제': formatTime(
            _formData.weekendGuardEndHour,
            _formData.weekendGuardEndMinute,
          ),
          '주말무단범위': formatUnauthorizedRange(
            _formData.weekendUnauthorizedStartHour,
            _formData.weekendUnauthorizedStartMinute,
            _formData.weekendUnauthorizedEndHour,
            _formData.weekendUnauthorizedEndMinute,
          ),
          '주말무단사용': _formData.isWeekendUsed ? 1 : 0,
          '휴일경계': formatTime(
            _formData.holidayGuardStartHour,
            _formData.holidayGuardStartMinute,
          ),
          '휴일해제': formatTime(
            _formData.holidayGuardEndHour,
            _formData.holidayGuardEndMinute,
          ),
          '휴일무단범위': formatUnauthorizedRange(
            _formData.holidayUnauthorizedStartHour,
            _formData.holidayUnauthorizedStartMinute,
            _formData.holidayUnauthorizedEndHour,
            _formData.holidayUnauthorizedEndMinute,
          ),
          '휴일무단사용': _formData.isHolidayUsed ? 1 : 0,
        },
      );

      // 주간휴일설정 저장
      bool holidaySuccess = true;
      if (success) {
        List<String> holidayCodes = [];
        for (int weekIndex = 0; weekIndex < 5; weekIndex++) {
          for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
            if (_formData.weeklyHolidays[weekIndex][dayIndex]) {
              final code = ((weekIndex + 1) * 10 + dayIndex + 1).toString();
              holidayCodes.add(code);
            }
          }
        }

        if (holidayCodes.isNotEmpty) {
          holidaySuccess = await DatabaseService.updateHolidayWeek(
            managementNumber: _formData.managementNumberController.text,
            holidayCodes: holidayCodes,
          );
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success && holidaySuccess) {
          showToast(context, message: '고객이 등록되었습니다.');
          // 입력 필드 초기화 또는 화면 이동
          _clearAllFields();
        } else {
          showToast(context, message: '고객 등록에 실패했습니다.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showToast(context, message: '오류가 발생했습니다: $e');
      }
    }
  }

  /// 모든 필드 초기화
  void _clearAllFields() {
    // 관제 물건 정보
    _formData.controlTypeController.clear();
    _formData.smsNameController.clear();
    _formData.contact1Controller.clear();
    _formData.contact2Controller.clear();
    _formData.addressController.clear();
    _formData.referenceController.clear();
    _formData.representativeNameController.clear();
    _formData.representativePhoneController.clear();

    // 관제 기본 정보
    _formData.managementNumberController.clear();
    _formData.erpCusNumberController.clear();
    _formData.publicNumberController.clear();
    _formData.transmissionNumberController.clear();
    _formData.publicTransmissionController.clear();
    _formData.remoteCodeController.clear();
    _formData.emergencyContactController.clear();
    _formData.securityStartDateController.clear();

    //관제 세부 정보
    _formData.mainLocationController.clear();
    _formData.remotePhoneController.clear();
    _formData.remotePasswordController.clear();
    _formData.arsPhoneController.clear();
    _formData.acquisitionController.clear();
    _formData.keyBoxesController.clear();
    _formData.keypadController.clear();
    _formData.keypadQuantityController.clear();
    _formData.emergencyPhoneController.clear();

    // 관제 액션 비고
    _formData.controlActionController.clear();
    _formData.memo1Controller.clear();
    _formData.memo2Controller.clear();

    // 고객 추가 메모사항
    _formData.openingPhoneController.clear();
    _formData.openingDateController.clear();
    _formData.modemSerialController.clear();
    _formData.additionalMemoController.clear();

    // GPS 좌표
    _formData.gpsX1Controller.clear();
    _formData.gpsY1Controller.clear();
    _formData.gpsX2Controller.clear();
    _formData.gpsY2Controller.clear();

    // 전용회선
    _formData.dedicatedNumberController.clear();
    _formData.dedicatedMemoController.clear();

    // 부가서비스
    _formData.newAsDateController.clear();
    _formData.newAsMemoController.clear();

    // DVR
    _formData.newDvrAddressController.clear();
    _formData.newDvrPortController.clear();
    _formData.newDvrIdController.clear();
    _formData.newDvrPasswordController.clear();
    _formData.dvrSNController.clear();

    setState(() {
      _formData.selectedCustomerStatus = null;
      _formData.selectedManagementArea = null;
      _formData.selectedOperationArea = null;
      _formData.selectedBusinessType = null;
      _formData.selectVehicleCode = null;
      _formData.selectedCallLocation = null;
      _formData.selectedCallArea = null;
      _formData.selectedUsageType = null;
      _formData.selectedServiceType = null;
      _formData.selectedMainSystem = null;
      _formData.selectedSubSystem = null;
      _formData.selectedMiSettings = null;
      _formData.selectedCompanyType = null;
      _formData.selectedBranchType = null;
      _formData.monthlyAggregation = false;
      _formData.hasKeyHolder = false;
      _formData.isDvrInspection = false;
      _formData.isWirelessSensorInspection = false;
      _formData.linkedPhoneNumbers = [];
      _formData.newAsServiceCode = null;
      _formData.newAsProvisionCode = null;
      _formData.additionalServiceTypeList = [];
      _formData.additionalServiceETCList = [];
      _formData.newDvrConnectionMethod = false;
      _formData.newDvrTypeCode = null;

      // 시간 초기화
      _formData.weekdayGuardStartHour = null;
      _formData.weekdayGuardStartMinute = null;
      _formData.weekdayGuardEndHour = null;
      _formData.weekdayGuardEndMinute = null;
      _formData.weekdayUnauthorizedStartHour = null;
      _formData.weekdayUnauthorizedStartMinute = null;
      _formData.weekdayUnauthorizedEndHour = null;
      _formData.weekdayUnauthorizedEndMinute = null;
      _formData.isWeekdayUsed = false;

      _formData.weekendGuardStartHour = null;
      _formData.weekendGuardStartMinute = null;
      _formData.weekendGuardEndHour = null;
      _formData.weekendGuardEndMinute = null;
      _formData.weekendUnauthorizedStartHour = null;
      _formData.weekendUnauthorizedStartMinute = null;
      _formData.weekendUnauthorizedEndHour = null;
      _formData.weekendUnauthorizedEndMinute = null;
      _formData.isWeekendUsed = false;

      _formData.holidayGuardStartHour = null;
      _formData.holidayGuardStartMinute = null;
      _formData.holidayGuardEndHour = null;
      _formData.holidayGuardEndMinute = null;
      _formData.holidayUnauthorizedStartHour = null;
      _formData.holidayUnauthorizedStartMinute = null;
      _formData.holidayUnauthorizedEndHour = null;
      _formData.holidayUnauthorizedEndMinute = null;
      _formData.isHolidayUsed = false;

      // 휴일주간 초기화
      for (var i = 0; i < 5; i++) {
        for (var j = 0; j < 7; j++) {
          _formData.weeklyHolidays[i][j] = false;
        }
      }
    });
  }

  /// 기본고객정보 탭 필드 초기화
  void _clearBasicFields() {
    _formData.controlTypeController.clear();
    _formData.smsNameController.clear();
    _formData.contact1Controller.clear();
    _formData.contact2Controller.clear();
    _formData.addressController.clear();
    _formData.referenceController.clear();
    _formData.representativeNameController.clear();
    _formData.representativePhoneController.clear();
    _formData.managementNumberController.clear();
    _formData.erpCusNumberController.clear();
    _formData.publicNumberController.clear();
    _formData.transmissionNumberController.clear();
    _formData.publicTransmissionController.clear();
    _formData.remoteCodeController.clear();
    _formData.emergencyContactController.clear();
    _formData.securityStartDateController.clear();
    _formData.controlActionController.clear();
    _formData.memo1Controller.clear();
    _formData.memo2Controller.clear();
    _formData.mainLocationController.clear();
    _formData.remotePhoneController.clear();
    _formData.remotePasswordController.clear();
    _formData.arsPhoneController.clear();
    _formData.keypadController.clear();
    _formData.keypadQuantityController.clear();
    _formData.acquisitionController.clear();
    _formData.keyBoxesController.clear();
    _formData.emergencyPhoneController.clear();
    setState(() {
      _formData.selectedCustomerStatus = null;
      _formData.selectedManagementArea = null;
      _formData.selectedOperationArea = null;
      _formData.selectedBusinessType = null;
      _formData.selectVehicleCode = null;
      _formData.selectedCallLocation = null;
      _formData.selectedCallArea = null;
      _formData.selectedCustomerStatus = null;
      _formData.selectedUsageType = null;
      _formData.selectedServiceType = null;
      _formData.selectedMainSystem = null;
      _formData.selectedSubSystem = null;
      _formData.selectedMiSettings = null;
      _formData.linkedPhoneNumbers = [];
      _formData.monthlyAggregation = false;
      _formData.hasKeyHolder = false;
      _formData.isDvrInspection = false;
      _formData.isWirelessSensorInspection = false;
    });
  }

  /// 확장고객정보 탭 필드 초기화
  void _clearExtendedFields() {
    _formData.openingPhoneController.clear();
    _formData.openingDateController.clear();
    _formData.modemSerialController.clear();
    _formData.additionalMemoController.clear();
    _formData.gpsX1Controller.clear();
    _formData.gpsY1Controller.clear();
    _formData.gpsX2Controller.clear();
    _formData.gpsY2Controller.clear();
    _formData.dedicatedNumberController.clear();
    _formData.dedicatedMemoController.clear();
    _formData.newAsDateController.clear();
    _formData.newAsMemoController.clear();
    _formData.newDvrAddressController.clear();
    _formData.newDvrPortController.clear();
    _formData.newDvrIdController.clear();
    _formData.newDvrPasswordController.clear();
    _formData.dvrSNController.clear();
    setState(() {
      _formData.selectedCompanyType = null;
      _formData.selectedBranchType = null;
      _formData.newAsServiceCode = null;
      _formData.newDvrConnectionMethod = false;
      _formData.newDvrTypeCode = null;
      _formData.newAsProvisionCode = null;
      _formData.additionalServiceTypeList = [];
      _formData.additionalServiceETCList = [];
      _formData.dvrTypeList = [];
      _formData.weekdayGuardStartHour = null;
      _formData.weekdayGuardStartMinute = null;
      _formData.weekdayGuardEndHour = null;
      _formData.weekdayGuardEndMinute = null;
      _formData.weekdayUnauthorizedStartHour = null;
      _formData.weekdayUnauthorizedStartMinute = null;
      _formData.weekdayUnauthorizedEndHour = null;
      _formData.weekdayUnauthorizedEndMinute = null;
      _formData.isWeekdayUsed = false;
      _formData.weekendGuardStartHour = null;
      _formData.weekendGuardStartMinute = null;
      _formData.weekendGuardEndHour = null;
      _formData.weekendGuardEndMinute = null;
      _formData.weekendUnauthorizedStartHour = null;
      _formData.weekendUnauthorizedStartMinute = null;
      _formData.weekendUnauthorizedEndHour = null;
      _formData.weekendUnauthorizedEndMinute = null;
      _formData.isWeekendUsed = false;
      _formData.holidayGuardStartHour = null;
      _formData.holidayGuardStartMinute = null;
      _formData.holidayGuardEndHour = null;
      _formData.holidayGuardEndMinute = null;
      _formData.holidayUnauthorizedStartHour = null;
      _formData.holidayUnauthorizedStartMinute = null;
      _formData.holidayUnauthorizedEndHour = null;
      _formData.holidayUnauthorizedEndMinute = null;
      _formData.isHolidayUsed = false;
      for (var i = 0; i < 5; i++) {
        for (var j = 0; j < 7; j++) {
          _formData.weeklyHolidays[i][j] = false;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Column(
        children: [
          // 상단 버튼 영역
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: context.colors.cardBackground,
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (_tabController.index == 0) {
                          _clearBasicFields();
                        } else {
                          _clearExtendedFields();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.gray30,
                        foregroundColor: context.colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('초기화'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: saveCustomer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.selectedColor,
                        foregroundColor: context.colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('등록'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 탭 바
          Container(
            decoration: BoxDecoration(
              color: context.colors.cardBackground,
              boxShadow: AppTheme.cardShadow,
            ),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              controller: _tabController,
              tabs: const [
                Tab(text: '기본고객정보'),
                Tab(text: '확장고객정보'),
              ],
              labelColor: context.colors.selectedColor,
              unselectedLabelColor: context.colors.textSecondary,
              dividerColor: context.colors.cardBackground,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  width: 3,
                  color: context.colors.selectedColor,
                ),
                insets: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                ), // 인디케이터 양옆 여백
              ),
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // 탭 뷰
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                // ── 기본고객정보 탭 ──
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWideScreen = constraints.maxWidth >= 1700;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 32,
                        ),
                        child: isWideScreen
                            ? IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CustomerPropertyInfoSection(
                                            data: _formData,
                                            rebuildParent: setState,
                                          ),
                                          const SizedBox(height: 24),
                                          Expanded(
                                            child: CustomerMemoSection(
                                              data: _formData,
                                              controlActionFocusNode:
                                                  _controlActionFocusNode,
                                              memoFocusNode: _memoFocusNode,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: CustomerBasicInfoSection(
                                        data: _formData,
                                        rebuildParent: setState,
                                        managementNumberReadOnly: false,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: CustomerDetailInfoSection(
                                        data: _formData,
                                        rebuildParent: setState,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CustomerPropertyInfoSection(
                                            data: _formData,
                                            rebuildParent: setState,
                                          ),
                                          const SizedBox(height: 24),
                                          Expanded(
                                            child: CustomerMemoSection(
                                              data: _formData,
                                              controlActionFocusNode:
                                                  _controlActionFocusNode,
                                              memoFocusNode: _memoFocusNode,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: CustomerBasicInfoSection(
                                        data: _formData,
                                        rebuildParent: setState,
                                        managementNumberReadOnly: true,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: CustomerDetailInfoSection(
                                        data: _formData,
                                        rebuildParent: setState,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    );
                  },
                ),
                // ── 확장고객정보 탭 ──
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWideScreen = constraints.maxWidth >= 1700;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 32,
                        ),
                        child: isWideScreen
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // 상단 4열 레이아웃
                                  IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // 1열: 보안설정
                                        Expanded(
                                          flex: 3,
                                          child: SecuritySettingsSection(
                                            data: _formData,
                                            rebuildParent: setState,
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
                                                isEditMode: true,
                                              ),
                                              const SizedBox(height: 16),
                                              CompanyBranchSection(
                                                data: _formData,
                                                rebuildParent: setState,
                                                isEditMode: true,
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
                                              GPSSection(isEditMode: true),
                                              const SizedBox(height: 16),
                                              DedicatedLineSection(
                                                isEditMode: true,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // 4열: 주간휴일설정
                                        Expanded(
                                          flex: 2,
                                          child: WeeklyHolidaySection(
                                            weeklyHolidays:
                                                _formData.weeklyHolidays,
                                            isEditMode: true,
                                            onChanged:
                                                (weekIndex, dayIndex, value) {
                                                  setState(() {
                                                    _formData
                                                            .weeklyHolidays[weekIndex][dayIndex] =
                                                        value;
                                                  });
                                                },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // 부가서비스
                                  _buildAdditionalServiceSection(),
                                  const SizedBox(height: 16),
                                  // DVR 상태
                                  _buildDvrStatusSection(),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: SecuritySettingsSection(
                                            data: _formData,
                                            rebuildParent: setState,
                                            isEditMode: true,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          flex: 1,
                                          child: CustomerExtendMemoSection(
                                            isEditMode: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: WeeklyHolidaySection(
                                            weeklyHolidays:
                                                _formData.weeklyHolidays,
                                            isEditMode: true,
                                            onChanged:
                                                (weekIndex, dayIndex, value) {
                                                  setState(() {
                                                    _formData
                                                            .weeklyHolidays[weekIndex][dayIndex] =
                                                        value;
                                                  });
                                                },
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(flex: 2, child: GPSSection()),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          flex: 2,
                                          child: CompanyBranchSection(
                                            data: _formData,
                                            rebuildParent: setState,
                                            isEditMode: true,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          flex: 2,
                                          child: DedicatedLineSection(
                                            isEditMode: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _buildAdditionalServiceSection(),
                                  const SizedBox(height: 24),
                                  _buildDvrStatusSection(),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Expanded(
          //   child: SingleChildScrollView(
          //     padding: const EdgeInsets.all(16),
          //     child: Row(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //         // ── 왼쪽 컬럼 ──
          //         Expanded(
          //           child: Column(
          //             crossAxisAlignment: CrossAxisAlignment.stretch,
          //             children: [
          //               // Row: 관제 물건 정보 | 관제 액션 비고
          //               IntrinsicHeight(
          //                 child: Row(
          //                   crossAxisAlignment: CrossAxisAlignment.stretch,
          //                   children: [
          //                     Expanded(child: _buildPropertyInfoSection()),
          //                     const SizedBox(width: 16),
          //                     Expanded(child: _buildNotesSection()),
          //                   ],
          //                 ),
          //               ),
          //               const SizedBox(height: 16),
          //               _buildDetailInfoSection(),
          //               const SizedBox(height: 16),
          //               _buildBasicInfoSection(),
          //             ],
          //           ),
          //         ),
          //         const SizedBox(width: 16),
          //         // ── 오른쪽 컬럼 ──
          //         Expanded(
          //           child: Column(
          //             crossAxisAlignment: CrossAxisAlignment.stretch,
          //             children: [
          //               _buildSecuritySettingsSection(),
          //               const SizedBox(height: 16),
          //               // Row: 고객 추가 메모사항 | 회사/지사 구분
          //               IntrinsicHeight(
          //                 child: Row(
          //                   crossAxisAlignment: CrossAxisAlignment.stretch,
          //                   children: [
          //                     Expanded(child: _buildCustomerMemoSection()),
          //                     const SizedBox(width: 16),
          //                     Expanded(child: _buildCompanyBranchSection()),
          //                   ],
          //                 ),
          //               ),
          //               const SizedBox(height: 16),
          //               // Row: 고객 GPS 좌표 | 전용회선 관리
          //               IntrinsicHeight(
          //                 child: Row(
          //                   crossAxisAlignment: CrossAxisAlignment.stretch,
          //                   children: [
          //                     Expanded(child: _buildGPSSection()),
          //                     const SizedBox(width: 16),
          //                     Expanded(child: _buildDedicatedLineSection()),
          //                   ],
          //                 ),
          //               ),
          //               const SizedBox(height: 16),
          //               _buildWeeklyHolidaySettings(),
          //               const SizedBox(height: 16),
          //               _buildAdditionalServiceSection(),
          //               const SizedBox(height: 16),
          //               _buildDvrStatusSection(),
          //             ],
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  // ========================================
  // UI 빌더 메서드들
  // ========================================

  /// 관제 물건 정보 섹션
  // Widget _buildPropertyInfoSection() {
  //   return Container(
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: context.colors.cardBackground,
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: AppTheme.cardShadow,
  //       border: Border.all(color: context.colors.selectedColor, width: 1),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         buildSectionTitle('관제 물건 정보'),
  //         const SizedBox(height: 16),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: CommonTextField(
  //                 label: '관제 상호명 *',
  //                 controller: _controlTypeController,
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: CommonTextField(
  //                 label: 'SMS용 상호',
  //                 controller: _smsNameController,
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 16),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: CommonTextField(
  //                 label: '관제 연락처1',
  //                 controller: _contact1Controller,
  //                 suffixIcon: Icons.phone,
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: CommonTextField(
  //                 label: '관제 연락처2',
  //                 controller: _contact2Controller,
  //                 suffixIcon: Icons.phone,
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 16),
  //         CommonTextField(label: '물건지 주소 *', controller: _addressController),
  //         const SizedBox(height: 16),
  //         CommonTextField(label: '대처경로', controller: _referenceController),
  //         const SizedBox(height: 16),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: CommonTextField(
  //                 label: '대표자 이름',
  //                 controller: _representativeNameController,
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: CommonTextField(
  //                 label: '대표자 H.P',
  //                 controller: _representativePhoneController,
  //                 suffixIcon: Icons.phone_android,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  /// 관제 기본 정보 섹션
  // Widget _buildBasicInfoSection() {
  //   return Container(
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: context.colors.cardBackground,
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: AppTheme.cardShadow,
  //       border: Border.all(color: context.colors.selectedColor, width: 1),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         buildSectionTitle('관제 기본 정보'),
  //         const SizedBox(height: 16),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: CommonTextField(
  //                 label: '관제관리번호 *',
  //                 controller: _managementNumberController,
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: CommonTextField(
  //                 label: '영업관리번호',
  //                 controller: _erpCusNumberController,
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 16),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: CommonTextField(
  //                 label: '공중회선',
  //                 controller: _publicNumberController,
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: CommonTextField(
  //                 label: '전용회선',
  //                 controller: _transmissionNumberController,
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 16),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: CommonTextField(
  //                 label: '인터넷회선',
  //                 controller: _publicTransmissionController,
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: CommonTextField(
  //                 label: '원격포트 구분',
  //                 controller: _remoteCodeController,
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 16),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: BuildDropdownField(
  //                 label: '관리구역',
  //                 value: _selectedManagementArea,
  //                 items: _managementAreaList,
  //                 searchQuery: '',
  //                 onChanged: (String? newValue) {
  //                   setState(() {
  //                     _selectedManagementArea = newValue;
  //                   });
  //                 },
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: BuildDropdownField(
  //                 label: '출동권역',
  //                 value: _selectedOperationArea,
  //                 items: _operationAreaList,
  //                 searchQuery: '',
  //                 onChanged: (String? newValue) {
  //                   setState(() {
  //                     _selectedOperationArea = newValue;
  //                   });
  //                 },
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 16),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: BuildDropdownField(
  //                 label: '업종코드',
  //                 value: _selectedBusinessType,
  //                 items: _businessTypeList,
  //                 searchQuery: '',
  //                 onChanged: (String? newValue) {
  //                   setState(() {
  //                     _selectedBusinessType = newValue;
  //                   });
  //                 },
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: BuildDropdownField(
  //                 label: '차량코드',
  //                 value: _selectVehicleCode,
  //                 items: _vehicleCodeList,
  //                 searchQuery: '',
  //                 onChanged: (String? newValue) {
  //                   setState(() {
  //                     _selectVehicleCode = newValue;
  //                   });
  //                 },
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 16),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: BuildDropdownField(
  //                 label: '관할경찰서',
  //                 value: _selectedCallLocation,
  //                 items: _policeStationList,
  //                 searchQuery: '',
  //                 onChanged: (String? newValue) {
  //                   setState(() {
  //                     _selectedCallLocation = newValue;
  //                   });
  //                 },
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: BuildDropdownField(
  //                 label: '관할지구대',
  //                 value: _selectedCallArea,
  //                 items: _policeDistrictList,
  //                 searchQuery: '',
  //                 onChanged: (String? newValue) {
  //                   setState(() {
  //                     _selectedCallArea = newValue;
  //                   });
  //                 },
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 16),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: CommonTextField(
  //                 label: '기관연락처',
  //                 controller: _emergencyContactController,
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: CommonTextField(
  //                 label: '경비개시일자',
  //                 controller: _securityStartDateController,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // /// 관제 세부 정보 섹션
  // Widget _buildDetailInfoSection() {
  //   return Container(
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: context.colors.cardBackground,
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: AppTheme.cardShadow,
  //       border: Border.all(color: context.colors.selectedColor, width: 1),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         buildSectionTitle('관제 세부 정보'),
  //         const SizedBox(height: 16),
  //         BuildDropdownField(
  //           label: '관제고객상태',
  //           value: _selectedCustomerStatus,
  //           items: _customerStatusList,
  //           searchQuery: '',
  //           onChanged: (String? newValue) {
  //             setState(() {
  //               _selectedCustomerStatus = newValue;
  //             });
  //           },
  //         ),
  //         const SizedBox(height: 16),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: BuildDropdownField(
  //                 label: '주 사용회선',
  //                 value: _selectedUsageType,
  //                 items: _usageLineList,
  //                 searchQuery: '',
  //                 onChanged: (String? newValue) {
  //                   setState(() {
  //                     _selectedUsageType = newValue;
  //                   });
  //                 },
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: BuildDropdownField(
  //                 label: '서비스종류',
  //                 value: _selectedServiceType,
  //                 items: _serviceTypeList,
  //                 searchQuery: '',
  //                 onChanged: (String? newValue) {
  //                   setState(() {
  //                     _selectedServiceType = newValue;
  //                   });
  //                 },
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 16),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: BuildDropdownField(
  //                 label: '주장치종류',
  //                 value: _selectedMainSystem,
  //                 items: _mainSystemList,
  //                 searchQuery: '',
  //                 onChanged: (String? newValue) {
  //                   setState(() {
  //                     _selectedMainSystem = newValue;
  //                   });
  //                 },
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: BuildDropdownField(
  //                 label: '주장치분류',
  //                 value: _selectedSubSystem,
  //                 items: _subSystemList,
  //                 searchQuery: '',
  //                 onChanged: (String? newValue) {
  //                   setState(() {
  //                     _selectedSubSystem = newValue;
  //                   });
  //                 },
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 16),
  //         CommonTextField(label: '주장치위치', controller: _mainLocationController),
  //         const SizedBox(height: 16),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: CommonTextField(
  //                 label: '원격전화',
  //                 controller: _remotePhoneController,
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: CommonTextField(
  //                 label: '원격암호',
  //                 controller: _remotePasswordController,
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 16),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: CommonTextField(
  //                 label: 'ARS전화',
  //                 controller: _arsPhoneController,
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: CommonTextField(
  //                 label: '키패드',
  //                 controller: _keypadController,
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: CommonTextField(
  //                 label: '수량',
  //                 controller: _keypadQuantityController,
  //                 keyboardType: TextInputType.number,
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 16),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: BuildDropdownField(
  //                 label: '미경계설정',
  //                 value: _selectedMiSettings,
  //                 items: _miSettingsList,
  //                 searchQuery: '',
  //                 onChanged: (String? newValue) {
  //                   setState(() {
  //                     _selectedMiSettings = newValue;
  //                   });
  //                 },
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: CommonTextField(
  //                 label: '인수수량',
  //                 controller: _acquisitionController,
  //                 keyboardType: TextInputType.number,
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: CommonTextField(
  //                 label: '키BOX',
  //                 controller: _keyBoxesController,
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 16),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     '키 인수여부',
  //                     style: TextStyle(
  //                       fontSize: 12,
  //                       color: context.colors.textSecondary,
  //                       fontWeight: FontWeight.w500,
  //                     ),
  //                   ),
  //                   const SizedBox(height: 8),
  //                   Row(
  //                     children: [
  //                       BuildRadioOption(
  //                         label: 'Y',
  //                         value: _hasKeyHolder,
  //                         onChanged: (val) {
  //                           setState(() => _hasKeyHolder = true);
  //                         },
  //                       ),
  //                       const SizedBox(width: 16),
  //                       BuildRadioOption(
  //                         label: 'N',
  //                         value: !_hasKeyHolder,
  //                         onChanged: (val) {
  //                           setState(() => _hasKeyHolder = false);
  //                         },
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     '집계',
  //                     style: TextStyle(
  //                       fontSize: 12,
  //                       color: context.colors.textSecondary,
  //                       fontWeight: FontWeight.w500,
  //                     ),
  //                   ),
  //                   const SizedBox(height: 8),
  //                   Row(
  //                     children: [
  //                       BuildRadioOption(
  //                         label: '발행',
  //                         value: _monthlyAggregation,
  //                         onChanged: (val) {
  //                           setState(() => _monthlyAggregation = true);
  //                         },
  //                       ),
  //                       const SizedBox(width: 16),
  //                       BuildRadioOption(
  //                         label: '미발행',
  //                         value: !_monthlyAggregation,
  //                         onChanged: (val) {
  //                           setState(() => _monthlyAggregation = false);
  //                         },
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 16),
  //         // 연동전화번호
  //         Row(
  //           children: [
  //             Expanded(
  //               child: CommonTextField(
  //                 label: '연동전화번호',
  //                 controller: _emergencyPhoneController,
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.stretch,
  //                 children: [
  //                   const SizedBox(height: 20),
  //                   ElevatedButton(
  //                     onPressed: () {
  //                       final phone = _emergencyPhoneController.text.trim();
  //                       if (phone.isNotEmpty) {
  //                         setState(() {
  //                           _linkedPhoneNumbers.add(phone);
  //                           _emergencyPhoneController.clear();
  //                         });
  //                       }
  //                     },
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: context.colors.selectedColor,
  //                       padding: const EdgeInsets.symmetric(
  //                         horizontal: 16,
  //                         vertical: 12,
  //                       ),
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(6),
  //                       ),
  //                     ),
  //                     child: const Text(
  //                       '추가',
  //                       style: TextStyle(
  //                         color: Colors.white,
  //                         fontWeight: FontWeight.w600,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //         if (_linkedPhoneNumbers.isNotEmpty) ...[
  //           const SizedBox(height: 12),
  //           Wrap(
  //             spacing: 8.0,
  //             runSpacing: 8.0,
  //             children: List.generate(_linkedPhoneNumbers.length, (index) {
  //               return Container(
  //                 padding: const EdgeInsets.symmetric(
  //                   horizontal: 12,
  //                   vertical: 8,
  //                 ),
  //                 decoration: BoxDecoration(
  //                   color: context.colors.gray10,
  //                   border: Border.all(color: context.colors.dividerColor),
  //                   borderRadius: BorderRadius.circular(8),
  //                 ),
  //                 child: Row(
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     Icon(
  //                       Icons.phone,
  //                       size: 16,
  //                       color: context.colors.textSecondary,
  //                     ),
  //                     const SizedBox(width: 8),
  //                     Text(
  //                       _linkedPhoneNumbers[index],
  //                       style: const TextStyle(fontSize: 14),
  //                     ),
  //                     const SizedBox(width: 8),
  //                     InkWell(
  //                       onTap: () {
  //                         setState(() {
  //                           _linkedPhoneNumbers.removeAt(index);
  //                         });
  //                       },
  //                       child: const Icon(
  //                         Icons.close,
  //                         size: 16,
  //                         color: Colors.red,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               );
  //             }),
  //           ),
  //         ],
  //         const SizedBox(height: 16),
  //         Row(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             BuildCheckbox(
  //               label: 'DVR고객',
  //               value: _isDvrInspection,
  //               onChanged: (val) {
  //                 setState(() {
  //                   _isDvrInspection = val;
  //                 });
  //               },
  //             ),
  //             const SizedBox(width: 20),
  //             BuildCheckbox(
  //               label: '무선센서 설치고객',
  //               value: _isWirelessSensorInspection,
  //               onChanged: (val) {
  //                 setState(() {
  //                   _isWirelessSensorInspection = val;
  //                 });
  //               },
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  /// 경계약정 및 무단해제 설정 섹션
  // Widget _buildSecuritySettingsSection() {
  //   return Container(
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: context.colors.cardBackground,
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: AppTheme.cardShadow,
  //       border: Border.all(color: context.colors.selectedColor, width: 1),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         buildSectionTitle('경계약정 및 무단해제 설정'),
  //         const SizedBox(height: 16),
  //         Row(
  //           children: [
  //             Expanded(child: _buildTimeSettingCard('평일', true)),
  //             const SizedBox(width: 16),
  //             Expanded(child: _buildTimeSettingCard('주말', false)),
  //             const SizedBox(width: 16),
  //             Expanded(child: _buildTimeSettingCard('휴일', null)),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  /// 시간 설정 카드 (평일/주말/휴일)
  // Widget _buildTimeSettingCard(String title, bool? isWeekday) {
  //   int? guardStartHour, guardStartMinute, guardEndHour, guardEndMinute;
  //   int? unauthStartHour, unauthStartMinute, unauthEndHour, unauthEndMinute;
  //   bool isUsed;
  //
  //   if (isWeekday == true) {
  //     guardStartHour = _weekdayGuardStartHour;
  //     guardStartMinute = _weekdayGuardStartMinute;
  //     guardEndHour = _weekdayGuardEndHour;
  //     guardEndMinute = _weekdayGuardEndMinute;
  //     unauthStartHour = _weekdayUnauthorizedStartHour;
  //     unauthStartMinute = _weekdayUnauthorizedStartMinute;
  //     unauthEndHour = _weekdayUnauthorizedEndHour;
  //     unauthEndMinute = _weekdayUnauthorizedEndMinute;
  //     isUsed = _isWeekdayUsed;
  //   } else if (isWeekday == false) {
  //     guardStartHour = _weekendGuardStartHour;
  //     guardStartMinute = _weekendGuardStartMinute;
  //     guardEndHour = _weekendGuardEndHour;
  //     guardEndMinute = _weekendGuardEndMinute;
  //     unauthStartHour = _formData.weekendUnauthorizedStartHour;
  //     unauthStartMinute = _formData.weekendUnauthorizedStartMinute;
  //     unauthEndHour = _formData.weekendUnauthorizedEndHour;
  //     unauthEndMinute = _formData.weekendUnauthorizedEndMinute;
  //     isUsed = _formData.isWeekendUsed;
  //   } else {
  //     guardStartHour = _formData.holidayGuardStartHour;
  //     guardStartMinute = _formData.holidayGuardStartMinute;
  //     guardEndHour = _formData.holidayGuardEndHour;
  //     guardEndMinute = _formData.holidayGuardEndMinute;
  //     unauthStartHour = _formData.holidayUnauthorizedStartHour;
  //     unauthStartMinute = _formData.holidayUnauthorizedStartMinute;
  //     unauthEndHour = _formData.holidayUnauthorizedEndHour;
  //     unauthEndMinute = _formData.holidayUnauthorizedEndMinute;
  //     isUsed = _formData.isHolidayUsed;
  //   }
  //
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: context.colors.background,
  //       borderRadius: BorderRadius.circular(10),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Container(
  //           padding: const EdgeInsets.all(12),
  //           decoration: BoxDecoration(
  //             color: context.colors.cardBackground,
  //             borderRadius: BorderRadius.circular(10),
  //           ),
  //           child: Column(
  //             children: [
  //               Text(
  //                 title,
  //                 style: TextStyle(
  //                   color: context.colors.textPrimary,
  //                   fontSize: 17,
  //                   fontFamily: 'Inter',
  //                   fontWeight: FontWeight.w600,
  //                 ),
  //               ),
  //               const SizedBox(height: 12),
  //               Divider(color: context.colors.dividerColor),
  //               const SizedBox(height: 12),
  //               TimePickerButton(
  //                 label: '경계',
  //                 hour: guardStartHour,
  //                 minute: guardStartMinute,
  //                 allowNull: true,
  //                 enabled: true,
  //                 onTimeChanged: (hour, minute) {
  //                   setState(() {
  //                     if (isWeekday == true) {
  //                       _weekdayGuardStartHour = hour;
  //                       _weekdayGuardStartMinute = minute;
  //                     } else if (isWeekday == false) {
  //                       _weekendGuardStartHour = hour;
  //                       _weekendGuardStartMinute = minute;
  //                     } else {
  //                       _holidayGuardStartHour = hour;
  //                       _holidayGuardStartMinute = minute;
  //                     }
  //                   });
  //                 },
  //               ),
  //               const SizedBox(height: 12),
  //               Divider(color: context.colors.dividerColor),
  //               const SizedBox(height: 12),
  //               TimePickerButton(
  //                 label: '해제',
  //                 hour: guardEndHour,
  //                 minute: guardEndMinute,
  //                 allowNull: true,
  //                 enabled: true,
  //                 onTimeChanged: (hour, minute) {
  //                   setState(() {
  //                     if (isWeekday == true) {
  //                       _weekdayGuardEndHour = hour;
  //                       _weekdayGuardEndMinute = minute;
  //                     } else if (isWeekday == false) {
  //                       _weekendGuardEndHour = hour;
  //                       _weekendGuardEndMinute = minute;
  //                     } else {
  //                       _holidayGuardEndHour = hour;
  //                       _holidayGuardEndMinute = minute;
  //                     }
  //                   });
  //                 },
  //               ),
  //             ],
  //           ),
  //         ),
  //         const SizedBox(height: 12),
  //         Container(
  //           padding: const EdgeInsets.all(12),
  //           decoration: BoxDecoration(
  //             color: context.colors.cardBackground,
  //             borderRadius: BorderRadius.circular(10),
  //           ),
  //           child: Column(
  //             children: [
  //               Row(
  //                 children: [
  //                   Text(
  //                     '무단',
  //                     style: TextStyle(
  //                       color: context.colors.textPrimary,
  //                       fontSize: 15,
  //                       fontFamily: 'Inter',
  //                       fontWeight: FontWeight.w400,
  //                     ),
  //                   ),
  //                   const Spacer(),
  //                   BuildCheckbox(
  //                     label: '사용',
  //                     value: isUsed,
  //                     onChanged: (val) {
  //                       setState(() {
  //                         if (isWeekday == true) {
  //                           _isWeekdayUsed = val;
  //                         } else if (isWeekday == false) {
  //                           _isWeekendUsed = val;
  //                         } else {
  //                           _isHolidayUsed = val;
  //                         }
  //                       });
  //                     },
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 12),
  //               Divider(color: context.colors.dividerColor),
  //               const SizedBox(height: 12),
  //               TimePickerButton(
  //                 label: '경계',
  //                 hour: unauthStartHour,
  //                 minute: unauthStartMinute,
  //                 enabled: isUsed,
  //                 showXXForZero: true,
  //                 allowNull: true,
  //                 onTimeChanged: (hour, minute) {
  //                   setState(() {
  //                     if (isWeekday == true) {
  //                       _weekdayUnauthorizedStartHour = hour;
  //                       _weekdayUnauthorizedStartMinute = minute;
  //                     } else if (isWeekday == false) {
  //                       _weekendUnauthorizedStartHour = hour;
  //                       _weekendUnauthorizedStartMinute = minute;
  //                     } else {
  //                       _holidayUnauthorizedStartHour = hour;
  //                       _holidayUnauthorizedStartMinute = minute;
  //                     }
  //                   });
  //                 },
  //               ),
  //               const SizedBox(height: 12),
  //               Divider(color: context.colors.dividerColor),
  //               const SizedBox(height: 12),
  //               TimePickerButton(
  //                 label: '해제',
  //                 hour: unauthEndHour,
  //                 minute: unauthEndMinute,
  //                 enabled: isUsed,
  //                 showXXForZero: true,
  //                 allowNull: true,
  //                 onTimeChanged: (hour, minute) {
  //                   setState(() {
  //                     if (isWeekday == true) {
  //                       _weekdayUnauthorizedEndHour = hour;
  //                       _weekdayUnauthorizedEndMinute = minute;
  //                     } else if (isWeekday == false) {
  //                       _weekendUnauthorizedEndHour = hour;
  //                       _weekendUnauthorizedEndMinute = minute;
  //                     } else {
  //                       _holidayUnauthorizedEndHour = hour;
  //                       _holidayUnauthorizedEndMinute = minute;
  //                     }
  //                   });
  //                 },
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  /// 고객 추가 메모사항 섹션
  // Widget _buildCustomerMemoSection() {
  //   return Container(
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: context.colors.cardBackground,
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: AppTheme.cardShadow,
  //       border: Border.all(color: context.colors.selectedColor, width: 1),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         buildSectionTitle('고객 추가 메모사항'),
  //         const SizedBox(height: 12),
  //         CommonTextField(label: '개통일자', controller: _openingDateController),
  //         const SizedBox(height: 12),
  //         CommonTextField(label: '개통전화번호', controller: _openingPhoneController),
  //         const SizedBox(height: 12),
  //         CommonTextField(label: '모뎀일련번호', controller: _modemSerialController),
  //         const SizedBox(height: 12),
  //         CommonTextField(
  //           label: '추가메모',
  //           controller: _additionalMemoController,
  //           maxLines: 3,
  //         ),
  //       ],
  //     ),
  //   );
  // }

  /// 고객 GPS 좌표 섹션
  // Widget _buildGPSSection() {
  //   return Container(
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: context.colors.cardBackground,
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: AppTheme.cardShadow,
  //       border: Border.all(color: context.colors.selectedColor, width: 1),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         buildSectionTitle('고객 GPS 좌표'),
  //         const SizedBox(height: 12),
  //         CommonTextField(label: 'X 좌표1', controller: _gpsX1Controller),
  //         const SizedBox(height: 12),
  //         CommonTextField(label: 'Y 좌표1', controller: _gpsY1Controller),
  //         const SizedBox(height: 12),
  //         CommonTextField(label: 'X 좌표2', controller: _gpsX2Controller),
  //         const SizedBox(height: 12),
  //         CommonTextField(label: 'Y 좌표2', controller: _gpsY2Controller),
  //       ],
  //     ),
  //   );
  // }

  /// 회사/지사 구분 섹션
  // Widget _buildCompanyBranchSection() {
  //   return Container(
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: context.colors.cardBackground,
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: AppTheme.cardShadow,
  //       border: Border.all(color: context.colors.selectedColor, width: 1),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         buildSectionTitle('회사 / 지사 구분'),
  //         const SizedBox(height: 12),
  //         BuildDropdownField(
  //           label: '회사구분',
  //           value: companyType,
  //           items: companyTypeList,
  //           searchQuery: '',
  //           onChanged: (String? newValue) {
  //             setState(() {
  //               companyType = newValue;
  //             });
  //           },
  //         ),
  //         const SizedBox(height: 12),
  //         BuildDropdownField(
  //           label: '지사구분',
  //           value: branchType,
  //           items: branchTypeList,
  //           searchQuery: '',
  //           onChanged: (String? newValue) {
  //             setState(() {
  //               branchType = newValue;
  //             });
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }

  /// 전용회선 관리 섹션
  // Widget _buildDedicatedLineSection() {
  //   return Container(
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: context.colors.cardBackground,
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: AppTheme.cardShadow,
  //       border: Border.all(color: context.colors.selectedColor, width: 1),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         buildSectionTitle('전용회선 관리'),
  //         const SizedBox(height: 12),
  //         CommonTextField(
  //           label: '전용회선 번호',
  //           controller: _dedicatedNumberController,
  //         ),
  //         const SizedBox(height: 12),
  //         CommonTextField(
  //           label: '추가메모',
  //           controller: _dedicatedMemoController,
  //           maxLines: 3,
  //         ),
  //       ],
  //     ),
  //   );
  // }

  /// 주간 휴일설정 섹션
  // Widget _buildWeeklyHolidaySettings() {
  //   final days = ['일', '월', '화', '수', '목', '금', '토'];
  //
  //   return Container(
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: context.colors.cardBackground,
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: AppTheme.cardShadow,
  //       border: Border.all(color: context.colors.selectedColor, width: 1),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         buildSectionTitle('주간 휴일설정'),
  //         const SizedBox(height: 12),
  //         // 요일 헤더
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             const SizedBox(width: 27),
  //             ...days.asMap().entries.map((entry) {
  //               return Expanded(
  //                 child: Center(
  //                   child: Text(
  //                     entry.value,
  //                     textAlign: TextAlign.center,
  //                     style: TextStyle(
  //                       color: context.colors.textPrimary,
  //                       fontSize: 14,
  //                       fontFamily: 'Inter',
  //                       fontWeight: FontWeight.w400,
  //                     ),
  //                   ),
  //                 ),
  //               );
  //             }),
  //           ],
  //         ),
  //         const SizedBox(height: 4),
  //         // 5주 체크박스 그리드
  //         ...List.generate(5, (weekIndex) {
  //           return Padding(
  //             padding: const EdgeInsets.symmetric(vertical: 2),
  //             child: Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 // 주차 번호
  //                 Container(
  //                   width: 25,
  //                   height: 25,
  //                   decoration: const ShapeDecoration(
  //                     color: Color(0xFFF5F5F5),
  //                     shape: OvalBorder(),
  //                   ),
  //                   child: Center(
  //                     child: Text(
  //                       '${weekIndex + 1}',
  //                       textAlign: TextAlign.center,
  //                       style: const TextStyle(
  //                         color: Colors.black,
  //                         fontSize: 13,
  //                         fontFamily: 'Inter',
  //                         fontWeight: FontWeight.w400,
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //                 const SizedBox(width: 4),
  //                 // 7일 체크박스
  //                 ...List.generate(7, (dayIndex) {
  //                   Color bgColor = context.colors.textPrimary;
  //                   Color checkColor = context.colors.cardBackground;
  //                   if (dayIndex == 0) {
  //                     bgColor = const Color(0xFFFF7070);
  //                     checkColor = context.colors.white;
  //                   } else if (dayIndex == 6) {
  //                     bgColor = const Color(0xFF87C5FF);
  //                     checkColor = context.colors.white;
  //                   }
  //
  //                   return Expanded(
  //                     child: Center(
  //                       child: Transform.scale(
  //                         scale: 0.85,
  //                         child: Checkbox(
  //                           value: _formData.weeklyHolidays[weekIndex][dayIndex],
  //                           onChanged: (value) {
  //                             setState(() {
  //                               _formData.weeklyHolidays[weekIndex][dayIndex] =
  //                                   value ?? false;
  //                             });
  //                           },
  //                           activeColor: bgColor,
  //                           checkColor: checkColor,
  //                           side: BorderSide(
  //                             color: context.colors.textSecondary,
  //                             width: 1.5,
  //                           ),
  //                           materialTapTargetSize:
  //                               MaterialTapTargetSize.shrinkWrap,
  //                           visualDensity: VisualDensity.compact,
  //                         ),
  //                       ),
  //                     ),
  //                   );
  //                 }),
  //               ],
  //             ),
  //           );
  //         }),
  //       ],
  //     ),
  //   );
  // }

  /// 관제 액션 비고 섹션
  // Widget _buildNotesSection() {
  //   return Container(
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: context.colors.cardBackground,
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: AppTheme.cardShadow,
  //       border: Border.all(color: context.colors.selectedColor, width: 1),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         buildSectionTitle('관제 액션 비고'),
  //         const SizedBox(height: 16),
  //         // 비고사항 입력 영역
  //         TextFormField(
  //           controller: _controlActionController,
  //           maxLines: 5,
  //           style: const TextStyle(fontSize: 13, color: Color(0xFF1D1D1F)),
  //           decoration: InputDecoration(
  //             hintStyle: TextStyle(color: context.colors.textSecondary),
  //             contentPadding: const EdgeInsets.all(12),
  //             filled: true,
  //             fillColor: context.colors.textEnable,
  //             border: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(8),
  //               borderSide: BorderSide(color: context.colors.dividerColor),
  //             ),
  //             enabledBorder: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(8),
  //               borderSide: BorderSide(color: context.colors.dividerColor),
  //             ),
  //             focusedBorder: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(8),
  //               borderSide: BorderSide(
  //                 color: context.colors.selectedColor,
  //                 width: 2,
  //               ),
  //             ),
  //           ),
  //         ),
  //         const SizedBox(height: 16),
  //         // 메모 탭
  //         Row(children: [_buildMemoTab('메모1', 0), _buildMemoTab('메모2', 1)]),
  //         // 메모 내용 영역
  //         TextFormField(
  //           controller: _selectedMemoTab == 0
  //               ? _memo1Controller
  //               : _memo2Controller,
  //           maxLines: 6,
  //           style: TextStyle(fontSize: 13, color: context.colors.textPrimary),
  //           decoration: InputDecoration(
  //             hintStyle: TextStyle(color: context.colors.textSecondary),
  //             contentPadding: const EdgeInsets.all(12),
  //             filled: true,
  //             fillColor: context.colors.textEnable,
  //             border: OutlineInputBorder(
  //               borderRadius: const BorderRadius.only(
  //                 bottomLeft: Radius.circular(8),
  //                 bottomRight: Radius.circular(8),
  //               ),
  //               borderSide: BorderSide(color: context.colors.dividerColor),
  //             ),
  //             enabledBorder: OutlineInputBorder(
  //               borderRadius: const BorderRadius.only(
  //                 bottomLeft: Radius.circular(8),
  //                 bottomRight: Radius.circular(8),
  //               ),
  //               borderSide: BorderSide(color: context.colors.dividerColor),
  //             ),
  //             focusedBorder: OutlineInputBorder(
  //               borderRadius: const BorderRadius.only(
  //                 bottomLeft: Radius.circular(8),
  //                 bottomRight: Radius.circular(8),
  //               ),
  //               borderSide: BorderSide(
  //                 color: context.colors.selectedColor,
  //                 width: 2,
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  /// 메모 탭 위젯
  // Widget _buildMemoTab(String label, int index) {
  //   final isSelected = _selectedMemoTab == index;
  //   return Expanded(
  //     child: InkWell(
  //       onTap: () {
  //         setState(() {
  //           _selectedMemoTab = index;
  //         });
  //       },
  //       child: Container(
  //         padding: const EdgeInsets.symmetric(vertical: 12),
  //         decoration: BoxDecoration(
  //           color: isSelected
  //               ? context.colors.textReadOnly
  //               : context.colors.cardBackground,
  //           border: Border.all(color: context.colors.dividerColor, width: 1),
  //           borderRadius: BorderRadius.only(
  //             topLeft: index == 0 ? const Radius.circular(8) : Radius.zero,
  //             topRight: index == 1 ? const Radius.circular(8) : Radius.zero,
  //             bottomLeft: Radius.zero,
  //             bottomRight: Radius.zero,
  //           ),
  //         ),
  //         child: Center(
  //           child: Text(
  //             label,
  //             style: TextStyle(
  //               fontSize: 14,
  //               fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
  //               color: context.colors.textSecondary,
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // ========================================
  // 부가서비스 제공 섹션
  // ========================================
  Widget _buildAdditionalServiceSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: context.colors.selectedColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('부가서비스 제공'),
          const SizedBox(height: 16),
          // 추가 입력 행
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: BuildDropdownField(
                  label: '부가서비스',
                  value: _formData.newAsServiceCode,
                  items: _formData.additionalServiceTypeList,
                  searchQuery: '',
                  onChanged: (v) =>
                      setState(() => _formData.newAsServiceCode = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BuildDropdownField(
                  label: '부가서비스제공',
                  value: _formData.newAsProvisionCode,
                  items: _formData.additionalServiceETCList,
                  searchQuery: '',
                  onChanged: (v) =>
                      setState(() => _formData.newAsProvisionCode = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DateTextField(
                  label: '일자',
                  controller: _formData.dateController,
                  onCalendarPressed: (context, isStartDate) async {
                    final selectedDate = await showDatePickerDialog(context);
                    if (selectedDate != null) {
                      setState(() {
                        _formData.dateController.text = recordDateFormatted(
                          selectedDate,
                        );
                      });
                    }
                  },
                  onSubmitted: () {
                    final parsed = parseDateString(
                      _formData.dateController.text,
                    );
                    if (parsed != null) {
                      setState(() {
                        _formData.dateController.text = parsed;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '메모',
                  controller: _formData.newAsMemoController,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  if (_formData.newAsServiceCode == null) return;
                  setState(() {
                    _formData.additionalServiceItems.add({
                      'serviceCode': _formData.newAsServiceCode ?? '',
                      'provisionCode': _formData.newAsProvisionCode ?? '',
                      'date': _formData.dateController.text,
                      'memo': _formData.newAsMemoController.text,
                    });
                    _formData.newAsServiceCode = null;
                    _formData.newAsProvisionCode = null;
                    _formData.dateController.clear();
                    _formData.newAsMemoController.clear();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.selectedColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('추가'),
              ),
            ],
          ),
          if (_formData.additionalServiceItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            // 헤더
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.colors.gray10,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '부가서비스',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '부가서비스제공',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '일자',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '메모',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),
            ...List.generate(_formData.additionalServiceItems.length, (i) {
              final item = _formData.additionalServiceItems[i];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: context.colors.dividerColor),
                    left: BorderSide(color: context.colors.dividerColor),
                    right: BorderSide(color: context.colors.dividerColor),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['serviceCode'] as String,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item['provisionCode'] as String,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item['date'] as String,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item['memo'] as String,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(
                        () => _formData.additionalServiceItems.removeAt(i),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ========================================
  // DVR 설치현황 섹션
  // ========================================
  Widget _buildDvrStatusSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: context.colors.selectedColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('DVR 설치현황'),
          const SizedBox(height: 16),
          // 접속방식
          Text(
            '접속방식',
            style: TextStyle(
              fontSize: 12,
              color: context.colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              BuildRadioOption(
                label: 'CS',
                value: _formData.newDvrConnectionMethod,
                onChanged: (_) =>
                    setState(() => _formData.newDvrConnectionMethod = false),
              ),
              const SizedBox(width: 16),
              BuildRadioOption(
                label: 'WEB',
                value: _formData.newDvrConnectionMethod,
                onChanged: (_) =>
                    setState(() => _formData.newDvrConnectionMethod = true),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: BuildDropdownField(
                  label: 'DVR종류',
                  value: _formData.newDvrTypeCode,
                  items: _formData.dvrTypeList,
                  searchQuery: '',
                  onChanged: (v) =>
                      setState(() => _formData.newDvrTypeCode = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '접속주소',
                  controller: _formData.newDvrAddressController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '접속포트',
                  controller: _formData.newDvrPortController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '접속 ID',
                  controller: _formData.newDvrIdController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '접속 암호',
                  controller: _formData.newDvrPasswordController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: 'DVR시리얼N',
                  controller: _formData.dvrSNController,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _formData.dvrItems.add({
                      'connectionMethod': _formData.newDvrConnectionMethod,
                      'typeCode': _formData.newDvrTypeCode ?? '',
                      'address': _formData.newDvrAddressController.text,
                      'port': _formData.newDvrPortController.text,
                      'id': _formData.newDvrIdController.text,
                      'password': _formData.newDvrPasswordController.text,
                      'serial': _formData.dvrSNController.text,
                    });
                    _formData.newDvrConnectionMethod = false;
                    _formData.newDvrTypeCode = null;
                    _formData.newDvrAddressController.clear();
                    _formData.newDvrPortController.clear();
                    _formData.newDvrIdController.clear();
                    _formData.newDvrPasswordController.clear();
                    _formData.dvrSNController.clear();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.selectedColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('추가'),
              ),
            ],
          ),
          if (_formData.dvrItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            // 헤더
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.colors.gray10,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
              child: Row(
                children: [
                  for (final h in [
                    '접속방식',
                    'DVR종류',
                    '접속주소',
                    '포트',
                    'ID',
                    'DVR시리얼N',
                  ])
                    Expanded(
                      child: Text(
                        h,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ),
                  const SizedBox(width: 24),
                ],
              ),
            ),
            ...List.generate(_formData.dvrItems.length, (i) {
              final item = _formData.dvrItems[i];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: context.colors.dividerColor),
                    left: BorderSide(color: context.colors.dividerColor),
                    right: BorderSide(color: context.colors.dividerColor),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['connectionMethod'] == true ? 'WEB' : 'CS',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item['typeCode'] as String,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item['address'] as String,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item['port'] as String,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item['id'] as String,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item['serial'] as String,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    InkWell(
                      onTap: () =>
                          setState(() => _formData.dvrItems.removeAt(i)),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
