import 'package:flutter/material.dart';
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

  // ==============================
  // 기타 상태
  // ==============================
  bool monthlyAggregation = false; // 월간집계 (발행=true, 미발행=false)
  bool hasKeyHolder = false; // 키 인수여부
  bool isDvrInspection = false; // DVR여부
  bool isWirelessSensorInspection = false; // 무선센서설치여부
  List<String> linkedPhoneNumbers = []; // 연동전화번호 목록

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
    linkedPhoneNumbers = [];
    monthlyAggregation = false;
    hasKeyHolder = false;
    isDvrInspection = false;
    isWirelessSensorInspection = false;
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
  }
}
