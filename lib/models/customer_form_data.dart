import 'package:flutter/material.dart';
import '../functions.dart';
import '../services/api_service.dart';

/// 기본고객정보 / 고객등록 화면이 공유하는 폼 데이터
class CustomerFormData {
  // ==============================
  // 관제 물건 정보 컨트롤러
  // ==============================
  final controlTypeController = TextEditingController(); // 관제상호명
  final smsNameController = TextEditingController(); // SMS용 상호
  final contact1Controller = TextEditingController(); // 관제연락처1
  final contact2Controller = TextEditingController(); // 관제연락처2
  final addressController = TextEditingController(); // 물건지주소
  final referenceController = TextEditingController(); // 대처경로
  final representativeNameController = TextEditingController(); // 대표자 이름
  final representativePhoneController = TextEditingController(); // 대표자H.P

  // ==============================
  // 관제 기본 정보 컨트롤러
  // ==============================
  final managementNumberController = TextEditingController(); // 관제관리번호
  final erpCusNumberController = TextEditingController(); // 영업관리번호
  final publicNumberController = TextEditingController(); // 공중회선
  final transmissionNumberController = TextEditingController(); // 전용회선
  final publicTransmissionController = TextEditingController(); // 인터넷회선
  final remoteCodeController = TextEditingController(); // 원격포트구분
  final emergencyContactController = TextEditingController(); // 기관연락처
  final securityStartDateController = TextEditingController(); // 경비개시일자

  // ==============================
  // 관제 세부 정보 컨트롤러
  // ==============================
  final mainLocationController = TextEditingController(); // 주장치위치
  final remotePhoneController = TextEditingController(); // 원격전화
  final remotePasswordController = TextEditingController(); // 원격암호
  final arsPhoneController = TextEditingController(); // ARS전화
  final keypadController = TextEditingController(); // 키패드
  final keypadQuantityController = TextEditingController(); // 키패드수량
  final acquisitionController = TextEditingController(); // 인수수량
  final keyBoxesController = TextEditingController(); // 키BOX
  final emergencyPhoneController = TextEditingController(); // 연동전화번호

  // ==============================
  // 관제 액션 비고 컨트롤러
  // ==============================
  final controlActionController = TextEditingController(); // 관제액션비고
  final memo1Controller = TextEditingController(); // 메모1
  final memo2Controller = TextEditingController(); // 메모2

  // ========================================
  // 고객 추가 메모사항
  // ========================================
  final openingPhoneController = TextEditingController(); // 개통전화번호
  final openingDateController = TextEditingController(); // 개통일자
  final modemSerialController = TextEditingController(); // 모뎀일련번호
  final additionalMemoController = TextEditingController(); // 추가메모

  // ========================================
  // 고객 GPS 좌표
  // ========================================
  final gpsX1Controller = TextEditingController();
  final gpsY1Controller = TextEditingController();
  final gpsX2Controller = TextEditingController();
  final gpsY2Controller = TextEditingController();

  // ========================================
  // 전용회선 관리
  // ========================================
  final dedicatedNumberController = TextEditingController();
  final dedicatedMemoController = TextEditingController();

  // ==============================
  // 드롭다운 선택값
  // ==============================
  String? selectedCustomerStatus; // 관제고객상태
  String? selectedManagementArea; // 관리구역
  String? selectedOperationArea; // 출동권역
  String? selectedBusinessType; // 업종코드
  String? selectVehicleCode; // 차량코드
  String? selectedCallLocation; // 관할경찰서
  String? selectedCallArea; // 관할지구대
  String? selectedUsageType; // 주사용회선
  String? selectedServiceType; // 서비스종류
  String? selectedMainSystem; // 주장치종류
  String? selectedSubSystem; // 주장치분류
  String? selectedMiSettings; // 미경계설정
  String? selectedCompanyType; // 회사구분
  String? selectedBranchType; // 지사구분
  String? selectedAdditionalServiceType; // 부가서비스종류
  String? selectedAdditionalServiceETC; // 지사구분
  String? selectedDvrType; // 지사구분

  // ==============================
  // 필수 입력 오류 플래그
  // ==============================
  bool errorManagementNumber = false;
  bool errorControlType = false;
  bool errorManagementArea = false;
  bool errorMainSystem = false;
  bool errorCompanyType = false;
  bool errorBranchType = false;

  // ==============================
  // 드롭다운 목록
  // ==============================
  List<CodeData> customerStatusList = [];
  List<CodeData> managementAreaList = [];
  List<CodeData> operationAreaList = [];
  List<CodeData> businessTypeList = [];
  List<CodeData> vehicleCodeList = [];
  List<CodeData> policeStationList = [];
  List<CodeData> policeDistrictList = [];
  List<CodeData> usageLineList = [];
  List<CodeData> serviceTypeList = [];
  List<CodeData> mainSystemList = [];
  List<CodeData> subSystemList = [];
  List<CodeData> miSettingsList = [];
  List<CodeData> companyTypeList = [];
  List<CodeData> branchTypeList = [];
  List<CodeData> additionalServiceTypeList = [];
  List<CodeData> additionalServiceETCList = [];
  List<CodeData> dvrTypeList = [];

  /// 데이터 초기화 (순차 처리)
  Future<void> initializeData() async {
    // 1. 드롭다운 데이터 먼저 로드
    managementAreaList = await loadDropdownData('managementarea');
    operationAreaList = await loadDropdownData('operationarea');
    businessTypeList = await loadDropdownData('businesstype');
    vehicleCodeList = await loadDropdownData('vehiclecode');
    policeStationList = await loadDropdownData('policestation');
    policeDistrictList = await loadDropdownData('policedistrict');
    usageLineList = await loadDropdownData('usageline');
    serviceTypeList = await loadDropdownData('servicetype');
    mainSystemList = await loadDropdownData('mainsystem');
    subSystemList = await loadDropdownData('subsystem');
    miSettingsList = await loadDropdownData('misettings');
    customerStatusList = await loadDropdownData('customerstatus');
    companyTypeList = await loadDropdownData('companytype');
    branchTypeList = await loadDropdownData('branchtype');
    additionalServiceTypeList = await loadDropdownData('addservicetype');
    additionalServiceETCList = await loadDropdownData('addserviceetc');
    dvrTypeList = await loadDropdownData('dvrtype');
  }

  // ==============================
  // 경계약정 및 무단해제 설정
  // ==============================
  int? weekdayGuardStartHour;
  int? weekdayGuardStartMinute;
  int? weekdayGuardEndHour;
  int? weekdayGuardEndMinute;
  int? weekdayUnauthorizedStartHour;
  int? weekdayUnauthorizedStartMinute;
  int? weekdayUnauthorizedEndHour;
  int? weekdayUnauthorizedEndMinute;
  bool isWeekdayUsed = false;

  int? weekendGuardStartHour;
  int? weekendGuardStartMinute;
  int? weekendGuardEndHour;
  int? weekendGuardEndMinute;
  int? weekendUnauthorizedStartHour;
  int? weekendUnauthorizedStartMinute;
  int? weekendUnauthorizedEndHour;
  int? weekendUnauthorizedEndMinute;
  bool isWeekendUsed = false;

  int? holidayGuardStartHour;
  int? holidayGuardStartMinute;
  int? holidayGuardEndHour;
  int? holidayGuardEndMinute;
  int? holidayUnauthorizedStartHour;
  int? holidayUnauthorizedStartMinute;
  int? holidayUnauthorizedEndHour;
  int? holidayUnauthorizedEndMinute;
  bool isHolidayUsed = false;

  // ========================================
  // 주간 휴일설정
  // ========================================
  final List<List<bool>> weeklyHolidays = List.generate(
    5,
    (_) => List.generate(7, (_) => false),
  );

  // ==============================
  // 기타 상태
  // ==============================
  bool monthlyAggregation = false; // 월간집계 (발행=true, 미발행=false)
  bool hasKeyHolder = false; // 키 인수여부
  bool isDvrInspection = false; // DVR여부
  bool isWirelessSensorInspection = false; // 무선센서설치여부
  List<String> linkedPhoneNumbers = []; // 연동전화번호 목록

  // ========================================
  // 부가서비스 제공
  // ========================================
  String? newAsServiceCode;
  String? newAsProvisionCode;
  final newAsDateController = TextEditingController();
  final newAsMemoController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  List<Map<String, dynamic>> additionalServiceItems = [];
  // ========================================
  // DVR 설치현황
  // ========================================
  bool newDvrConnectionMethod = false; // false=CS, true=WEB
  String? newDvrTypeCode;
  final newDvrAddressController = TextEditingController();
  final newDvrPortController = TextEditingController();
  final newDvrIdController = TextEditingController();
  final newDvrPasswordController = TextEditingController();
  final dvrSNController = TextEditingController();
  List<Map<String, dynamic>> dvrItems = [];
  late TabController tabController;

  // ==============================
  // 모든 컨트롤러/상태 초기화
  // ==============================
  void clearAll() {
    controlTypeController.clear();
    smsNameController.clear();
    contact1Controller.clear();
    contact2Controller.clear();
    addressController.clear();
    referenceController.clear();
    representativeNameController.clear();
    representativePhoneController.clear();
    managementNumberController.clear();
    erpCusNumberController.clear();
    publicNumberController.clear();
    transmissionNumberController.clear();
    publicTransmissionController.clear();
    remoteCodeController.clear();
    emergencyContactController.clear();
    securityStartDateController.clear();
    mainLocationController.clear();
    remotePhoneController.clear();
    remotePasswordController.clear();
    arsPhoneController.clear();
    keypadController.clear();
    keypadQuantityController.clear();
    acquisitionController.clear();
    keyBoxesController.clear();
    emergencyPhoneController.clear();
    controlActionController.clear();
    memo1Controller.clear();
    memo2Controller.clear();

    selectedCustomerStatus = null;
    selectedManagementArea = null;
    selectedOperationArea = null;
    selectedBusinessType = null;
    selectVehicleCode = null;
    selectedCallLocation = null;
    selectedCallArea = null;
    selectedUsageType = null;
    selectedServiceType = null;
    selectedMainSystem = null;
    selectedSubSystem = null;
    selectedMiSettings = null;
    selectedMiSettings = null;
    selectedMiSettings = null;
    selectedCompanyType = null;
    selectedBranchType = null;
    selectedAdditionalServiceType = null;
    selectedAdditionalServiceETC = null;
    selectedDvrType = null;

    linkedPhoneNumbers = [];

    weekdayGuardStartHour = null;
    weekdayGuardStartMinute = null;
    weekdayGuardEndHour = null;
    weekdayGuardEndMinute = null;
    weekdayUnauthorizedStartHour = null;
    weekdayUnauthorizedStartMinute = null;
    weekdayUnauthorizedEndHour = null;
    weekdayUnauthorizedEndMinute = null;
    isWeekdayUsed = false;
    weekendGuardStartHour = null;
    weekendGuardStartMinute = null;
    weekendGuardEndHour = null;
    weekendGuardEndMinute = null;
    weekendUnauthorizedStartHour = null;
    weekendUnauthorizedStartMinute = null;
    weekendUnauthorizedEndHour = null;
    weekendUnauthorizedEndMinute = null;
    isWeekendUsed = false;
    holidayGuardStartHour = null;
    holidayGuardStartMinute = null;
    holidayGuardEndHour = null;
    holidayGuardEndMinute = null;
    holidayUnauthorizedStartHour = null;
    holidayUnauthorizedStartMinute = null;
    holidayUnauthorizedEndHour = null;
    holidayUnauthorizedEndMinute = null;
    isHolidayUsed = false;

    monthlyAggregation = false;
    hasKeyHolder = false;
    isDvrInspection = false;
    isWirelessSensorInspection = false;

    // 휴일주간 초기화
    for (var i = 0; i < 5; i++) {
      for (var j = 0; j < 7; j++) {
        weeklyHolidays[i][j] = false;
      }
    }
  }

  void dispose() {
    controlTypeController.dispose();
    smsNameController.dispose();
    contact1Controller.dispose();
    contact2Controller.dispose();
    addressController.dispose();
    referenceController.dispose();
    representativeNameController.dispose();
    representativePhoneController.dispose();
    managementNumberController.dispose();
    erpCusNumberController.dispose();
    publicNumberController.dispose();
    transmissionNumberController.dispose();
    publicTransmissionController.dispose();
    remoteCodeController.dispose();
    emergencyContactController.dispose();
    securityStartDateController.dispose();
    mainLocationController.dispose();
    remotePhoneController.dispose();
    remotePasswordController.dispose();
    arsPhoneController.dispose();
    keypadController.dispose();
    keypadQuantityController.dispose();
    acquisitionController.dispose();
    keyBoxesController.dispose();
    emergencyPhoneController.dispose();
    controlActionController.dispose();
    memo1Controller.dispose();
    memo2Controller.dispose();

    // 관제 액션 비고
    controlActionController.dispose();
    memo1Controller.dispose();
    memo2Controller.dispose();

    // 고객 추가 메모사항
    openingPhoneController.dispose();
    openingDateController.dispose();
    modemSerialController.dispose();
    additionalMemoController.dispose();

    // GPS 좌표
    gpsX1Controller.dispose();
    gpsY1Controller.dispose();
    gpsX2Controller.dispose();
    gpsY2Controller.dispose();

    // 전용회선
    dedicatedNumberController.dispose();
    dedicatedMemoController.dispose();

    // 부가서비스
    newAsDateController.dispose();
    newAsMemoController.dispose();

    // DVR
    newDvrAddressController.dispose();
    newDvrPortController.dispose();
    newDvrIdController.dispose();
    newDvrPasswordController.dispose();
    dvrSNController.dispose();

    tabController.dispose();
  }
}
