import 'package:flutter/material.dart';
import '../functions.dart';
import '../theme.dart';
import '../models/search_panel.dart';
import '../models/customer_detail.dart';
import '../services/api_service.dart';
import '../services/selected_customer_service.dart';
import '../style.dart';
import '../widgets/custom_top_bar.dart';
import '../widgets/content_area.dart';

class BasicCustomerInfo extends StatefulWidget {
  final SearchPanel? searchpanel;

  const BasicCustomerInfo({super.key, this.searchpanel});

  @override
  State<BasicCustomerInfo> createState() => BasicCustomerInfoState();
}

class BasicCustomerInfoState extends State<BasicCustomerInfo> {
  final _customerService = SelectedCustomerService();
  final
  // 상세 정보 로딩 상태
  bool
  _isLoading = false;
  CustomerDetail? _customerDetail;

  // 현재 로드된 고객의 관제관리번호 (중복 API 호출 방지)
  String? _loadedCustomerManagementNumber;

  // 편집 모드 상태
  bool isEditMode = false;
  bool _hasChanges = false;
  Map<String, dynamic> _originalData = {};

  // 페이지 내 검색
  String _pageSearchQuery = '';

  // 검색 쿼리 업데이트 메서드
  void updateSearchQuery(String query) {
    setState(() {
      _pageSearchQuery = query;
    });
  }

  // 관제 물건 정보
  final _controlTypeController = TextEditingController(); // 관제상호명
  final _smsNameController = TextEditingController(); // SMS용 상호 (고객용상호)
  final _contact1Controller = TextEditingController(); // 관제연락처1
  final _contact2Controller = TextEditingController(); // 관제연락처2
  final _addressController = TextEditingController(); // 물건지주소
  final _referenceController = TextEditingController(); // 대처경로
  final _representativeNameController = TextEditingController(); // 대표자 이름
  final _representativePhoneController = TextEditingController(); // 대표자H.P

  // 관제 기본 정보
  final _managementNumberController = TextEditingController(); // 관제관리번호
  final _erpCusNumberController = TextEditingController(); // 영업관리번호
  final _publicNumberController = TextEditingController(); // 공중회선
  final _transmissionNumberController = TextEditingController(); // 전용회선
  final _publicTransmissionController = TextEditingController(); // 인터넷회선
  final _remoteCodeController = TextEditingController(); // 원격포트구분

  String? _selectedCustomerStatus; // 관제고객상태
  String? _selectedManagementArea; // 관리구역
  String? _selectedOperationArea; // 출동권역
  String? _selectedBusinessType; // 업종코드
  String? _selectVehicleCode; // 차량코드
  String? _selectedCallLocation; // 관할경찰서
  String? _selectedCallArea; // 지구대
  final _emergencyContactController = TextEditingController(); //기관연락처
  final _securityStartDateController = TextEditingController(); // 경비개시일자

  // 관제 세부 정보
  String? _selectedUsageType; // 주사용회선
  String? _selectedServiceType; // 서비스종류
  String? _selectedMainSystem; // 기기종류
  String? _selectedSubSystem; // 주장치 분류
  final _mainLocationController = TextEditingController(); // 주장치 분류
  final _remotePhoneController = TextEditingController(); // 원격전화
  final _remotePasswordController = TextEditingController(); // 원격암호
  final _arsPhoneController = TextEditingController(); // ARS전화
  String? _selectedMiSettings; // 미경계 설정
  bool _monthlyAggregation = false; // 월간집계 (발행 = true, 미발행 = false)
  bool _hasKeyHolder = false; // 키 인수여부
  final _acquisitionController = TextEditingController(); // 인수수량
  final _keyBoxesController = TextEditingController(); //키BOX
  final _keypadController = TextEditingController(); //키패드
  final _keypadQuantityController = TextEditingController(); //키패드수량
  final _emergencyPhoneController = TextEditingController();
  bool _isDvrInspection = false; // dvr여부
  bool _isWirelessSensorInspection = false; // 무선센서설치여부

  // 검색 관련
  final _searchController = TextEditingController();

  // 연동전화번호 목록
  List<String> _linkedPhoneNumbers = [];

  // 메모 탭
  int _selectedMemoTab = 0;
  final _controlActionController = TextEditingController(); //관제액션비고
  final _memo1Controller = TextEditingController(); // 메모1
  final _memo2Controller = TextEditingController(); // 메모2

  // FocusNode for TextFormFields
  final _controlActionFocusNode = FocusNode();
  final _memoFocusNode = FocusNode();

  // 드롭다운 데이터 목록
  List<CodeData> _managementAreaList = [];
  List<CodeData> _operationAreaList = [];
  List<CodeData> _businessTypeList = [];
  List<CodeData> _vehicleCodeList = [];
  List<CodeData> _policeStationList = [];
  List<CodeData> _policeDistrictList = [];
  List<CodeData> _usageLineList = [];
  List<CodeData> _serviceTypeList = [];
  List<CodeData> _mainSystemList = [];
  List<CodeData> _subSystemList = [];
  List<CodeData> _miSettingsList = [];
  List<CodeData> _customerStatusList = []; // 관제고객상태 목록

  @override
  void dispose() {
    _customerService.removeListener(_onCustomerServiceChanged);
    _controlTypeController.dispose(); //관제상호명
    _smsNameController.dispose();
    _contact1Controller.dispose();
    _contact2Controller.dispose();
    _addressController.dispose();
    _referenceController.dispose();
    _representativeNameController.dispose();
    _representativePhoneController.dispose();
    _managementNumberController.dispose();
    _erpCusNumberController.dispose();
    _publicNumberController.dispose();
    _transmissionNumberController.dispose();
    _publicTransmissionController.dispose();
    _remoteCodeController.dispose();
    _emergencyContactController.dispose();
    _remotePhoneController.dispose();
    _remotePasswordController.dispose();
    _arsPhoneController.dispose();
    _acquisitionController.dispose();
    _keyBoxesController.dispose();
    _keypadController.dispose();
    _keypadQuantityController.dispose();
    _emergencyPhoneController.dispose();
    _mainLocationController.dispose();
    _searchController.dispose();
    _memo1Controller.dispose();
    _memo2Controller.dispose();
    _controlActionController.dispose();
    _controlActionFocusNode.dispose();
    _memoFocusNode.dispose();
    super.dispose();
  }

  void _clearAllFields() {
    // 모든 필드 초기화
    _managementNumberController.clear();
    _erpCusNumberController.clear();
    _controlTypeController.clear();
    _smsNameController.clear();
    _contact1Controller.clear();
    _contact2Controller.clear();
    _addressController.clear();
    _referenceController.clear();
    _representativeNameController.clear();
    _representativePhoneController.clear();
    _publicNumberController.clear();
    _transmissionNumberController.clear();
    _publicTransmissionController.clear();
    _remoteCodeController.clear();
    _emergencyContactController.clear();
    _securityStartDateController.clear();
    _mainLocationController.clear();
    _remotePhoneController.clear();
    _remotePasswordController.clear();
    _arsPhoneController.clear();
    _acquisitionController.clear();
    _keyBoxesController.clear();
    _keypadController.clear();
    _keypadQuantityController.clear();
    _emergencyPhoneController.clear();
    _memo1Controller.clear();
    _memo2Controller.clear();
    _controlActionController.clear();

    setState(() {
      _selectedCustomerStatus = null;
      _selectedManagementArea = null;
      _selectedOperationArea = null;
      _selectedBusinessType = null;
      _selectVehicleCode = null;
      _selectedCallLocation = null;
      _selectedCallArea = null;
      _selectedUsageType = null;
      _selectedServiceType = null;
      _selectedMainSystem = null;
      _selectedSubSystem = null;
      _selectedMiSettings = null;
      _linkedPhoneNumbers = [];
      _customerDetail = null;
      _monthlyAggregation = false;
      _hasKeyHolder = false;
      _isDvrInspection = false;
      _isWirelessSensorInspection = false;
    });
  }

  void _updateFieldsFromDetail(CustomerDetail detail) {
    // 관제 물건 정보
    _managementNumberController.text = detail.controlManagementNumber;
    _erpCusNumberController.text = detail.erpCusNumber ?? '';
    _controlTypeController.text = detail.controlBusinessName ?? '';
    _smsNameController.text = detail.customerBusinessName ?? '';
    _contact1Controller.text = detail.controlContact1 ?? '';
    _contact2Controller.text = detail.controlContact2 ?? '';
    _addressController.text = detail.propertyAddress ?? '';
    _referenceController.text = detail.responsePath1 ?? '';
    _representativeNameController.text = detail.representative ?? '';
    _representativePhoneController.text = detail.representativeHP ?? '';
    _emergencyContactController.text = detail.emergencyContact ?? '';
    // 관제 기본 정보
    _securityStartDateController.text = detail.securityStartDateFormatted;
    _publicNumberController.text = detail.publicLine ?? '';
    _transmissionNumberController.text = detail.dedicatedLine ?? '';
    _publicTransmissionController.text = detail.internetLine ?? '';
    _remoteCodeController.text = detail.remotePort ?? '';

    // 관제 세부 정보 - 코드값 사용 (DB 값 그대로 사용, 빈 문자열은 null로 처리)
    _selectedUsageType = isValidCode(detail.usageLineTypeCode)
        ? detail.usageLineTypeCode
        : null;
    _selectedCustomerStatus = isValidCode(detail.customerStatusCode)
        ? detail.customerStatusCode
        : null;
    _selectedManagementArea = isValidCode(detail.managementAreaCode)
        ? detail.managementAreaCode
        : null;
    _selectedOperationArea = isValidCode(detail.dispatchAreaCode)
        ? detail.dispatchAreaCode
        : null;
    _selectedBusinessType = isValidCode(detail.businessTypeLargeCode)
        ? detail.businessTypeLargeCode
        : null;
    _selectVehicleCode = isValidCode(detail.vehicleCode)
        ? detail.vehicleCode
        : null;
    _selectedCallLocation = isValidCode(detail.policeStationCode)
        ? detail.policeStationCode
        : null;
    _selectedCallArea = isValidCode(detail.policeSubstationCode)
        ? detail.policeSubstationCode
        : null;

    _arsPhoneController.text = detail.arsPhoneNumber ?? '';
    _remotePhoneController.text = detail.remotePhoneNumber ?? '';
    _selectedMainSystem = isValidCode(detail.deviceTypeCode)
        ? detail.deviceTypeCode
        : null;
    _selectedMiSettings = isValidCode(detail.unguardedTypeCode)
        ? detail.unguardedTypeCode
        : null;
    _remotePasswordController.text = detail.remotePassword ?? '';
    _acquisitionController.text = detail.acquisition ?? '';
    _keyBoxesController.text = detail.keyBoxes ?? '';
    _keypadController.text = detail.keypad ?? '';
    _keypadQuantityController.text = detail.keypadQuantity ?? '';

    // bool 값 직접 사용
    _monthlyAggregation = detail.monthlyAggregationChecked;
    _hasKeyHolder = detail.keyReceiptStatusChecked;
    _isDvrInspection = detail.dvrChecked;
    _isWirelessSensorInspection = stringToBool(detail.wirelessChecked);

    _mainLocationController.text = detail.unguardedClassificationName ?? '';
    _selectedServiceType = isValidCode(detail.serviceTypeCode)
        ? detail.serviceTypeCode
        : null;

    // 메모
    _controlActionController.text = detail.controlAction ?? ''; // 관제액션비고
    _memo1Controller.text = detail.memo1 ?? '';
    _memo2Controller.text = detail.memo2 ?? '';
  }

  @override
  void initState() {
    super.initState();

    // ChangeNotifier 리스너 등록
    _customerService.addListener(_onCustomerServiceChanged);

    // FocusNode 리스너 등록
    _controlActionFocusNode.addListener(() {
      if (!_controlActionFocusNode.hasFocus && isEditMode) {
        _trackChanges();
      }
    });
    _memoFocusNode.addListener(() {
      if (!_memoFocusNode.hasFocus && isEditMode) {
        _trackChanges();
      }
    });

    // 드롭다운 데이터를 먼저 로드한 후 고객 데이터 로드
    _initializeData();
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

      _updateUIFromService();
    }
  }

  /// 서비스에서 UI 업데이트 (무한 루프 방지)
  Future<void> _updateUIFromService() async {
    final detail = _customerService.customerDetail;

    if (detail != null) {
      setState(() {
        _customerDetail = detail;
        _updateFieldsFromDetail(detail);
      });
    }
    //else if (customer != null) {
    //   setState(() {
    //     _loadBasicCustomerInfo(customer);
    //   });
    // }
    else {
      _clearAllFields();
    }
  }

  /// 데이터 초기화 (순차 처리)
  Future<void> _initializeData() async {
    // 1. 드롭다운 데이터 먼저 로드
    _managementAreaList = await loadDropdownData('managementarea');
    _operationAreaList = await loadDropdownData('operationarea');
    _businessTypeList = await loadDropdownData('businesstype');
    _vehicleCodeList = await loadDropdownData('vehiclecode');
    _policeStationList = await loadDropdownData('policestation');
    _policeDistrictList = await loadDropdownData('policedistrict');
    _usageLineList = await loadDropdownData('usageline');
    _serviceTypeList = await loadDropdownData('servicetype');
    _mainSystemList = await loadDropdownData('mainsystem');
    _subSystemList = await loadDropdownData('subsystem');
    _miSettingsList = await loadDropdownData('misettings');
    _customerStatusList = await loadDropdownData('customerstatus');

    // 2. 기본고객정보 화면에서는 고객 상세 정보를 로드
    if (_customerService.selectedCustomer != null) {
      _loadedCustomerManagementNumber =
          _customerService.selectedCustomer!.controlManagementNumber;
      await _customerService.loadCustomerDetail();
    }

    // 3. 고객 데이터 로드 (전역 서비스에서)
    await _updateUIFromService();
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

  /// 원본 데이터 저장
  void _saveOriginalData() {
    _originalData = {
      '관제상호': _controlTypeController.text,
      'SMS용상호': _smsNameController.text,
      '관제연락처1': _contact1Controller.text,
      '관제연락처2': _contact2Controller.text,
      '물건주소': _addressController.text,
      '대처경로1': _referenceController.text,
      '대표자이름': _representativeNameController.text,
      '대표자HP': _representativePhoneController.text,
      '공중회선': _publicNumberController.text,
      '전용회선': _transmissionNumberController.text,
      '인터넷회선': _publicTransmissionController.text,
      '원격포트': _remoteCodeController.text,
      '기관연락처': _emergencyContactController.text,
      '경비개시일자': _securityStartDateController.text,
      '관제고객상태': _selectedCustomerStatus,
      '관리구역': _selectedManagementArea,
      '출동권역': _selectedOperationArea,
      '업종코드': _selectedBusinessType,
      '차량코드': _selectVehicleCode,
      '관할경찰서': _selectedCallLocation,
      '관할지구대': _selectedCallArea,
      '주사용회선': _selectedUsageType,
      '서비스종류': _selectedServiceType,
      '주장치종류': _selectedMainSystem,
      '주장치분류': _selectedSubSystem,
      '주장치위치': _mainLocationController.text,
      '원격전화': _remotePhoneController.text,
      '원격암호': _remotePasswordController.text,
      'ARS전화': _arsPhoneController.text,
      '미경계설정': _selectedMiSettings,
      '인수수량': _acquisitionController.text,
      '키BOX': _keyBoxesController.text,
      '키패드': _keypadController.text,
      '키패드수량': _keypadQuantityController.text,
      '키인수여부': _hasKeyHolder,
      '월간집계': _monthlyAggregation,
      'DVR여부': _isDvrInspection,
      '무선센서': _isWirelessSensorInspection,
      '관제액션비고': _controlActionController.text,
      '메모1': _memo1Controller.text,
      '메모2': _memo2Controller.text,
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
      final success = await DatabaseService.updateBasicCustomerInfo(
        managementNumber: _managementNumberController.text,
        data: {
          '사용회선종류': _selectedUsageType,
          '관제고객상태코드': _selectedCustomerStatus,
          '공중회선': _publicNumberController.text,
          '전용회선': _transmissionNumberController.text,
          '인터넷회선': _publicTransmissionController.text,
          '관제상호': _controlTypeController.text,
          '관제연락처1': _contact1Controller.text,
          '관제연락처2': _contact2Controller.text,
          '물건주소': _addressController.text,
          '대처경로1': _referenceController.text,
          '대표자': _representativeNameController.text,
          '대표자HP': _representativePhoneController.text,
          '개통일자': _securityStartDateController.text.isEmpty
              ? null
              : '${_securityStartDateController.text} 00:00:00.000',
          '관리구역코드': _selectedManagementArea,
          '출동권역코드': _selectedOperationArea,
          '차량코드': _selectVehicleCode,
          '경찰서코드': _selectedCallLocation,
          '지구대코드': _selectedCallArea,
          '소방서코드': _emergencyContactController.text, //기관연락처
          '업종대코드': _selectedBusinessType,
          '원격전화번호': _remotePhoneController.text,
          '기기종류코드': _selectedMainSystem,

          '미경계종류코드': _selectedMiSettings,

          '원격암호': _remotePasswordController.text,
          '월간집계': _monthlyAggregation ? 1 : 0,
          '관제액션': _controlActionController.text,
          '키인수여부': _hasKeyHolder ? 1 : 0,
          'ARS전화번호': _arsPhoneController.text,
          '미경계분류코드': _selectedSubSystem,
          '서비스종류코드': _selectedServiceType,
          'DVR여부': _isDvrInspection ? 1 : 0,
          '키박스번호': _keyBoxesController.text,
          '원격포트': _remoteCodeController.text,
          'TMP1': _acquisitionController.text, //인수수량
          'TMP2': _keypadController.text, //키패드
          'TMP3': _keypadQuantityController.text, //키패드수량

          'TMP8': _isWirelessSensorInspection ? 1 : 0, //무선센서설치여부

          '메모': _memo1Controller.text,
          '메모2': _memo2Controller.text,
          '고객용상호': _smsNameController.text,
        },
      );

      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('저장되었습니다.')));
        setState(() {
          isEditMode = false;
          _hasChanges = false;
        });
        // 서비스에 편집 종료 알림
        _customerService.endEditing();
        // 데이터 새로고침 (force: true로 캐시 무시하고 서버에서 최신 데이터 가져오기)
        await _customerService.loadCustomerDetail(force: true);
        // 명시적으로 UI 업데이트
        if (_customerService.customerDetail != null && mounted) {
          setState(() {
            _customerDetail = _customerService.customerDetail;
            _updateFieldsFromDetail(_customerService.customerDetail!);
          });
        }
        // ContentArea의 setState를 호출하여 topbar 버튼 업데이트
        if (mounted) {
          context.findAncestorStateOfType<ContentAreaState>()?.setState(() {});
        }
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('저장에 실패했습니다.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
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
              },
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
              },
              child: const Text('예'),
            ),
          ],
        );
      },
    );
  }

  /// 원본 데이터 복원
  void _restoreOriginalData() {
    _controlTypeController.text = _originalData['관제상호'] ?? '';
    _smsNameController.text = _originalData['SMS용상호'] ?? '';
    _contact1Controller.text = _originalData['관제연락처1'] ?? '';
    _contact2Controller.text = _originalData['관제연락처2'] ?? '';
    _addressController.text = _originalData['물건주소'] ?? '';
    _referenceController.text = _originalData['대처경로'] ?? '';
    _representativeNameController.text = _originalData['대표자이름'] ?? '';
    _representativePhoneController.text = _originalData['대표자HP'] ?? '';
    _publicNumberController.text = _originalData['공중회선'] ?? '';
    _transmissionNumberController.text = _originalData['전용회선'] ?? '';
    _publicTransmissionController.text = _originalData['인터넷회선'] ?? '';
    _remoteCodeController.text = _originalData['원격포트'] ?? '';
    _emergencyContactController.text = _originalData['기관연락처'] ?? '';
    _securityStartDateController.text = _originalData['경비개시일자'] ?? '';
    _selectedCustomerStatus = _originalData['관제고객상태'];
    _selectedManagementArea = _originalData['관리구역'];
    _selectedOperationArea = _originalData['출동권역'];
    _selectedBusinessType = _originalData['업종코드'];
    _selectVehicleCode = _originalData['차량코드'];
    _selectedCallLocation = _originalData['관할경찰서'];
    _selectedCallArea = _originalData['관할지구대'];
    _selectedUsageType = _originalData['주사용회선'];
    _selectedServiceType = _originalData['서비스종류'];
    _selectedMainSystem = _originalData['주장치종류'];
    _selectedSubSystem = _originalData['주장치분류'];
    _mainLocationController.text = _originalData['주장치위치'] ?? '';
    _remotePhoneController.text = _originalData['원격전화'] ?? '';
    _remotePasswordController.text = _originalData['원격암호'] ?? '';
    _selectedMiSettings = _originalData['미경계설정'];
    _acquisitionController.text = _originalData['인수수량'] ?? '';
    _keyBoxesController.text = _originalData['키BOX'] ?? '';
    _keypadController.text = _originalData['키패드'] ?? '';
    _keypadQuantityController.text = _originalData['키패드수량'] ?? '';
    _hasKeyHolder = _originalData['키인수여부'] ?? false;
    _monthlyAggregation = _originalData['월간집계'] ?? false;
    _isDvrInspection = _originalData['DVR여부'] ?? false;
    _isWirelessSensorInspection = _originalData['무선센서'] ?? false;
    _controlActionController.text = _originalData['관제액션비고'] ?? '';
    _memo1Controller.text = _originalData['메모1'] ?? '';
    _memo2Controller.text = _originalData['메모2'] ?? '';
  }

  // /// 드롭다운 데이터 로드
  // Future<void> _loadDropdownData() async {
  //   try {
  //     // 캐시를 통해 드롭다운 데이터 로드
  //     _managementAreaList = await CodeDataCache.getCodeData(
  //       'managementarea',
  //     ); //관리구역
  //     _operationAreaList = await CodeDataCache.getCodeData('operationarea');
  //     _businessTypeList = await CodeDataCache.getCodeData('businesstype');
  //     _vehicleCodeList = await CodeDataCache.getCodeData('vehiclecode');
  //     _policeStationList = await CodeDataCache.getCodeData('policestation');
  //     _policeDistrictList = await CodeDataCache.getCodeData('policedistrict');
  //     _usageLineList = await CodeDataCache.getCodeData('usageline');
  //     _serviceTypeList = await CodeDataCache.getCodeData('servicetype');
  //     _mainSystemList = await CodeDataCache.getCodeData('mainsystem');
  //     _subSystemList = await CodeDataCache.getCodeData('subsystem');
  //     _miSettingsList = await CodeDataCache.getCodeData('misettings');
  //     _customerStatusList = await CodeDataCache.getCodeData('customerstatus');
  //   } catch (e) {
  //     print('드롭다운 데이터 로드 오류: $e');
  //   }
  // }

  // /// 전역 서비스에서 고객 데이터 로드
  // Future<void> _loadCustomerDataFromService() async {
  //   final selectedCustomer = _customerService.selectedCustomer;
  //
  //   if (selectedCustomer == null) {
  //     // 선택된 고객이 없으면 필드 초기화
  //     _clearAllFields();
  //     return;
  //   }
  //
  //   setState(() {
  //     _isLoading = true;
  //   });
  //
  //   try {
  //     // 전역 서비스에서 상세 정보 로드
  //     await _customerService.loadCustomerDetail();
  //
  //     final detail = _customerService.customerDetail;
  //
  //     if (detail != null && mounted) {
  //       setState(() {
  //         _customerDetail = detail;
  //         _updateFieldsFromDetail(detail);
  //         _isLoading = false;
  //       });
  //     } else if (mounted) {
  //       setState(() {
  //         _isLoading = false;
  //       });
  //       // API에서 상세 정보를 가져오지 못한 경우 기본 고객 정보만 표시
  //       //_loadBasicCustomerInfo(selectedCustomer);
  //     }
  //   } catch (e) {
  //     print('고객 상세 정보 로드 오류: $e');
  //     if (mounted) {
  //       setState(() {
  //         _isLoading = false;
  //       });
  //       //_loadBasicCustomerInfo(selectedCustomer);
  //     }
  //   }
  // }

  // void _loadBasicCustomerInfo(SearchPanel customer) {
  //   // API 실패 시 기본 고객 정보만 로드
  //   _managementNumberController.text = customer.controlManagementNumber;
  //   _controlTypeController.text = customer.controlBusinessName;
  //   _contact1Controller.text = widget.searchpanel?.phoneNumber ?? '';
  //   _addressController.text = customer.propertyAddress;
  //   _representativeNameController.text = customer.representative ?? '';
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth >= 1200;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: isWideScreen
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 좌측: 관제 물건 정보
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPropertyInfoSection(),
                            const SizedBox(height: 24),
                            _buildDetailInfoSection(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // 우측: 관제 기본 정보
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBasicInfoSection(),
                            const SizedBox(height: 24),
                            _buildNotesSection(),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPropertyInfoSection(),
                      const SizedBox(height: 24),
                      _buildDetailInfoSection(),
                      const SizedBox(height: 24),
                      _buildBasicInfoSection(),
                      const SizedBox(height: 24),
                      _buildNotesSection(),
                    ],
                  ),
          );
        },
      ),
    );
  }

  // 관제 물건 정보 섹션
  Widget _buildPropertyInfoSection() {
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
          buildSectionTitle('관제 물건 정보'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CommonTextField(
                  label: '관제 상호명',
                  controller: _controlTypeController,
                  searchQuery: _pageSearchQuery,
                  readOnly: !isEditMode,
                  onFocusLost: _trackChanges,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: 'SMS용 상호',
                  controller: _smsNameController,
                  searchQuery: _pageSearchQuery,
                  readOnly: !isEditMode,
                  onFocusLost: _trackChanges,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CommonTextField(
                  label: '관제 연락처1',
                  controller: _contact1Controller,
                  suffixIcon: Icons.phone,
                  searchQuery: _pageSearchQuery,
                  readOnly: !isEditMode,
                  onFocusLost: _trackChanges,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '관제 연락처2',
                  controller: _contact2Controller,
                  suffixIcon: Icons.phone,
                  searchQuery: _pageSearchQuery,
                  readOnly: !isEditMode,
                  onFocusLost: _trackChanges,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CommonTextField(
            searchQuery: _pageSearchQuery,
            label: '물건지 주소',
            controller: _addressController,
            readOnly: !isEditMode,
            onChanged: (_) => _trackChanges(),
          ),
          const SizedBox(height: 16),
          CommonTextField(
            searchQuery: _pageSearchQuery,
            label: '대처경로',
            controller: _referenceController,
            readOnly: !isEditMode,
            onChanged: (_) => _trackChanges(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CommonTextField(
                  searchQuery: _pageSearchQuery,
                  label: '대표자 이름',
                  controller: _representativeNameController,
                  readOnly: !isEditMode,
                  onFocusLost: _trackChanges,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  searchQuery: _pageSearchQuery,
                  label: '대표자 H.P',
                  controller: _representativePhoneController,
                  suffixIcon: Icons.phone_android,
                  readOnly: !isEditMode,
                  onFocusLost: _trackChanges,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 관제 기본 정보 섹션
  Widget _buildBasicInfoSection() {
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
          buildSectionTitle('관제 기본 정보'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CommonTextField(
                  searchQuery: _pageSearchQuery,
                  label: '관제관리번호',
                  controller: _managementNumberController,
                  readOnly: true,
                  onFocusLost: _trackChanges,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  searchQuery: _pageSearchQuery,
                  label: '영업관리번호',
                  controller: _erpCusNumberController,
                  readOnly: !isEditMode,
                  onFocusLost: _trackChanges,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CommonTextField(
                  searchQuery: _pageSearchQuery,
                  label: '공중회선',
                  controller: _publicNumberController,
                  readOnly: !isEditMode,
                  onFocusLost: _trackChanges,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  searchQuery: _pageSearchQuery,
                  label: '전용회선',
                  controller: _transmissionNumberController,
                  readOnly: !isEditMode,
                  onFocusLost: _trackChanges,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CommonTextField(
                  searchQuery: _pageSearchQuery,
                  label: '인터넷회선',
                  controller: _publicTransmissionController,
                  readOnly: !isEditMode,
                  onFocusLost: _trackChanges,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  searchQuery: _pageSearchQuery,
                  label: '원격포트 구분',
                  controller: _remoteCodeController,
                  readOnly: !isEditMode,
                  onFocusLost: _trackChanges,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: BuildDropdownField(
                  label: '관리구역',
                  value: _selectedManagementArea,
                  items: _managementAreaList,
                  searchQuery: _pageSearchQuery,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedManagementArea = newValue!;
                    });
                    _trackChanges();
                  },
                  readOnly: !isEditMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BuildDropdownField(
                  label: '출동권역',
                  value: _selectedOperationArea,
                  items: _operationAreaList,
                  searchQuery: _pageSearchQuery,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedOperationArea = newValue!;
                    });
                    _trackChanges();
                  },
                  readOnly: !isEditMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: BuildDropdownField(
                  label: '업종코드',
                  value: _selectedBusinessType,
                  items: _businessTypeList,
                  searchQuery: _pageSearchQuery,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedBusinessType = newValue!;
                    });
                    _trackChanges();
                  },
                  readOnly: !isEditMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BuildDropdownField(
                  label: '차량코드',
                  value: _selectVehicleCode,
                  items: _vehicleCodeList,
                  searchQuery: _pageSearchQuery,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectVehicleCode = newValue!;
                    });
                    _trackChanges();
                  },
                  readOnly: !isEditMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: BuildDropdownField(
                  label: '관할경찰서',
                  value: _selectedCallLocation,
                  items: _policeStationList,
                  searchQuery: _pageSearchQuery,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCallLocation = newValue!;
                    });
                    _trackChanges();
                  },
                  readOnly: !isEditMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BuildDropdownField(
                  label: '관할지구대',
                  value: _selectedCallArea,
                  items: _policeDistrictList,
                  searchQuery: _pageSearchQuery,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCallArea = newValue!;
                    });
                    _trackChanges();
                  },
                  readOnly: !isEditMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CommonTextField(
                  searchQuery: _pageSearchQuery,
                  label: '기관연락처',
                  controller: _emergencyContactController,
                  readOnly: !isEditMode,
                  onFocusLost: _trackChanges,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  searchQuery: _pageSearchQuery,
                  label: '경비개시일자',
                  controller: _securityStartDateController,
                  readOnly: !isEditMode,
                  onFocusLost: _trackChanges,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 관제 세부 정보 섹션
  Widget _buildDetailInfoSection() {
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
          buildSectionTitle('관제 세부 정보'),
          const SizedBox(height: 16),
          BuildDropdownField(
            label: '관제고객상태',
            value: _selectedCustomerStatus,
            items: _customerStatusList,
            onChanged: (String? newValue) {
              setState(() {
                _selectedCustomerStatus = newValue!;
              });
              _trackChanges();
            },
            readOnly: !isEditMode,
            searchQuery: '',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: BuildDropdownField(
                  label: '주 사용회선',
                  value: _selectedUsageType,
                  items: _usageLineList,
                  searchQuery: _pageSearchQuery,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedUsageType = newValue!;
                    });
                    _trackChanges();
                  },
                  readOnly: !isEditMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BuildDropdownField(
                  label: '서비스종류',
                  value: _selectedServiceType,
                  items: _serviceTypeList,
                  searchQuery: _pageSearchQuery,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedServiceType = newValue!;
                    });
                    _trackChanges();
                  },
                  readOnly: !isEditMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: BuildDropdownField(
                  label: '주장치종류',
                  value: _selectedMainSystem,
                  items: _mainSystemList,
                  searchQuery: _pageSearchQuery,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedMainSystem = newValue!;
                    });
                    _trackChanges();
                  },
                  readOnly: !isEditMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BuildDropdownField(
                  label: '주장치분류',
                  value: _selectedSubSystem,
                  items: _subSystemList,
                  searchQuery: _pageSearchQuery,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedSubSystem = newValue!;
                    });
                    _trackChanges();
                  },
                  readOnly: !isEditMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CommonTextField(
            searchQuery: _pageSearchQuery,
            label: '주장치위치',
            controller: _mainLocationController,
            readOnly: !isEditMode,
            onChanged: (_) => _trackChanges(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CommonTextField(
                  searchQuery: _pageSearchQuery,
                  label: '원격전화',
                  controller: _remotePhoneController,
                  readOnly: !isEditMode,
                  onFocusLost: _trackChanges,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  searchQuery: _pageSearchQuery,
                  label: '원격암호',
                  controller: _remotePasswordController,
                  readOnly: !isEditMode,
                  onFocusLost: _trackChanges,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CommonTextField(
                  searchQuery: _pageSearchQuery,
                  label: 'ARS전화',
                  controller: _arsPhoneController,
                  readOnly: !isEditMode,
                  onFocusLost: _trackChanges,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  searchQuery: _pageSearchQuery,
                  label: '키패드',
                  controller: _keypadController,
                  readOnly: !isEditMode,
                  onFocusLost: _trackChanges,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  searchQuery: _pageSearchQuery,
                  label: '수량',
                  controller: _keypadQuantityController,
                  readOnly: !isEditMode,
                  onFocusLost: _trackChanges,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: BuildDropdownField(
                  label: '미경계설정',
                  value: _selectedMiSettings,
                  items: _miSettingsList,
                  searchQuery: _pageSearchQuery,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedMiSettings = newValue!;
                    });
                    _trackChanges();
                  },
                  readOnly: !isEditMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CommonTextField(
                        searchQuery: _pageSearchQuery,
                        label: '인수수량',
                        controller: _acquisitionController,
                        readOnly: !isEditMode,
                        onFocusLost: _trackChanges,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CommonTextField(
                        searchQuery: _pageSearchQuery,
                        label: '키BOX',
                        controller: _keyBoxesController,
                        readOnly: !isEditMode,
                        onFocusLost: _trackChanges,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '키 인수여부',
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
                          label: 'Y',
                          value: _hasKeyHolder,
                          readOnly: !isEditMode,
                          onChanged: (val) {
                            setState(() => _hasKeyHolder = true);
                            _trackChanges();
                          },
                        ),
                        const SizedBox(width: 16),
                        BuildRadioOption(
                          label: 'N',
                          value: !_hasKeyHolder,
                          readOnly: !isEditMode,
                          onChanged: (val) {
                            setState(() => _hasKeyHolder = false);
                            _trackChanges();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '집계',
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
                          label: '발행',
                          value: _monthlyAggregation,
                          readOnly: !isEditMode,
                          onChanged: (val) {
                            setState(() => _monthlyAggregation = true);
                            _trackChanges();
                          },
                        ),
                        const SizedBox(width: 16),
                        BuildRadioOption(
                          label: '미발행',
                          value: !_monthlyAggregation,
                          readOnly: !isEditMode,
                          onChanged: (val) {
                            setState(() => _monthlyAggregation = false);
                            _trackChanges();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CommonTextField(
                  searchQuery: _pageSearchQuery,
                  label: '연동전화번호',
                  controller: _emergencyPhoneController,
                  readOnly: !isEditMode,
                  onFocusLost: _trackChanges,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    if (isEditMode)
                      ElevatedButton(
                        onPressed: () {
                          final phoneNumber = _emergencyPhoneController.text
                              .trim();
                          if (phoneNumber.isNotEmpty) {
                            setState(() {
                              _linkedPhoneNumbers.add(phoneNumber);
                              _emergencyPhoneController.clear();
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.selectedColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          '추가',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 추가된 연동전화번호 목록 표시
          if (_linkedPhoneNumbers.isNotEmpty)
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: List.generate(_linkedPhoneNumbers.length, (index) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.gray10,
                    border: Border.all(color: context.colors.dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.phone,
                        size: 16,
                        color: context.colors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _linkedPhoneNumbers[index],
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _linkedPhoneNumbers.removeAt(index);
                          });
                        },
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
            ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildCheckbox(
                label: 'DVR고객',
                value: _isDvrInspection,
                readOnly: !isEditMode,
                onChanged: (val) {
                  setState(() {
                    _isDvrInspection = val;
                  });
                  _trackChanges();
                },
              ),
              const SizedBox(width: 20),
              buildCheckbox(
                label: '무선센서 설치고객',
                value: _isWirelessSensorInspection,
                readOnly: !isEditMode,
                onChanged: (val) {
                  setState(() {
                    _isWirelessSensorInspection = val;
                  });
                  _trackChanges();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 관제액션 비고 섹션
  Widget _buildNotesSection() {
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
          buildSectionTitle('관제 액션 비고'),
          const SizedBox(height: 16),
          // 비고사항 입력 영역
          TextFormField(
            controller: _controlActionController,
            focusNode: _controlActionFocusNode,
            maxLines: 5,
            style: const TextStyle(fontSize: 13, color: Color(0xFF1D1D1F)),
            decoration: InputDecoration(
              //hintText:  '여기에 비고사항을 입력하세요...',
              hintStyle: TextStyle(color: context.colors.textSecondary),
              contentPadding: const EdgeInsets.all(12),
              filled: true,
              fillColor: isEditMode
                  ? context.colors.textEnable
                  : context.colors.gray10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.colors.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.colors.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isEditMode
                      ? context.colors.selectedColor
                      : context.colors.dividerColor,
                  width: isEditMode ? 2 : 1,
                ),
              ),
            ),
            readOnly: !isEditMode,
          ),
          const SizedBox(height: 16),
          // 메모 탭
          Row(children: [_buildMemoTab('메모1', 0), _buildMemoTab('메모2', 1)]),
          // 메모 내용 영역
          TextFormField(
            controller: _selectedMemoTab == 0
                ? _memo1Controller
                : _memo2Controller,
            focusNode: _memoFocusNode,
            maxLines: 8,
            style: TextStyle(fontSize: 13, color: context.colors.textPrimary),
            decoration: InputDecoration(
              //hintText: '메모${_selectedMemoTab + 1} 내용을 입력하세요...',
              hintStyle: TextStyle(color: context.colors.textSecondary),
              contentPadding: const EdgeInsets.all(12),
              filled: true,
              fillColor: !isEditMode
                  ? context.colors.gray10
                  : context.colors.textEnable,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                borderSide: BorderSide(color: context.colors.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                borderSide: BorderSide(color: context.colors.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                borderSide: BorderSide(
                  color: isEditMode
                      ? context.colors.selectedColor
                      : context.colors.dividerColor,
                  width: isEditMode ? 2 : 1,
                ),
              ),
            ),
            readOnly: !isEditMode,
          ),
        ],
      ),
    );
  }

  Widget _buildMemoTab(String label, int index) {
    final isSelected = _selectedMemoTab == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMemoTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? context.colors.textSecondary
                : context.colors.gray10,
            border: Border.all(color: context.colors.dividerColor, width: 1),
            borderRadius: BorderRadius.only(
              topLeft: index == 0 ? const Radius.circular(8) : Radius.zero,
              topRight: index == 1 ? const Radius.circular(8) : Radius.zero,
              bottomLeft: Radius.zero,
              bottomRight: Radius.zero,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? context.colors.gray10
                    : context.colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    final controller = TextEditingController(text: value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              filled: true,
              fillColor: context.colors.gray10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.colors.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.colors.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: context.colors.selectedColor,
                  width: 1,
                ),
              ),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  // 관제고객상태에 따른 색상 반환
  Color _getStatusColor(String status) {
    if (status.contains('정상') || status.contains('관제중')) {
      return Colors.green;
    } else if (status.contains('보류') ||
        status.contains('대기') ||
        status.contains('미개시')) {
      return Colors.orange;
    } else if (status.contains('해지') || status.contains('중지')) {
      return Colors.red;
    }
    return context.colors.textSecondary;
  }

  // Widget _buildStatusButton(String label, bool isSelected, Color color) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
  //     decoration: BoxDecoration(
  //       color: isSelected ? color : Colors.transparent,
  //       borderRadius: BorderRadius.circular(6),
  //       border: Border.all(color: isSelected ? color : context.colors.dividerColor),
  //     ),
  //     child: Text(
  //       label,
  //       style: TextStyle(
  //         color: isSelected ? Colors.white : context.colors.textSecondary,
  //         fontWeight: FontWeight.w600,
  //       ),
  //     ),
  //   );
  // }

  /// 관제고객상태 드롭다운 (색상 변경 기능 포함)
  Widget _buildStatusDropdownField(
    String label,
    String? value,
    List<CodeData> items,
  ) {
    // 데이터가 로드되지 않았으면 로딩 표시
    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: context.colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: context.colors.gray10,
              border: Border.all(color: context.colors.dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '로딩 중...',
              style: TextStyle(
                fontSize: 14,
                color: context.colors.textSecondary,
              ),
            ),
          ),
        ],
      );
    }

    // value(코드)가 items에 없으면 null로 설정 (에러 방지)
    String? selectedValue = value;
    if (value != null && !items.any((item) => item.code == value)) {
      selectedValue = null;
    }

    // 선택된 코드에 해당하는 이름을 찾아서 색상 결정
    String selectedName = '';
    if (selectedValue != null) {
      final selectedItem = items.firstWhere(
        (item) => item.code == selectedValue,
        orElse: () => CodeData(code: '', name: '정상'),
      );
      selectedName = selectedItem.name;
    }

    // 현재 선택된 상태의 색상
    Color currentColor = _getStatusColor(selectedName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: selectedValue,
          style: TextStyle(
            fontSize: 14,
            color: currentColor, // 선택된 상태에 따라 텍스트 색상 변경
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.only(
              left: 12,
              top: 6,
              right: 6,
              bottom: 6,
            ),
            filled: true,
            fillColor: currentColor.withOpacity(0.1), // 선택된 상태에 따라 배경색 변경
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: currentColor,
              ), // 선택된 상태에 따라 테두리 색상 변경
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: currentColor,
              ), // 선택된 상태에 따라 테두리 색상 변경
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: currentColor, // 선택된 상태에 따라 포커스 테두리 색상 변경
                width: 2,
              ),
            ),
          ),
          icon: Icon(Icons.arrow_drop_down, size: 24, color: currentColor),
          isExpanded: true,
          selectedItemBuilder: (BuildContext context) {
            return items.map((CodeData item) {
              return HighlightedText(
                text: item.name,
                query: _pageSearchQuery,
                style: TextStyle(
                  color: currentColor, // 선택된 항목 색상
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              );
            }).toList();
          },
          items: items.map((CodeData item) {
            Color itemColor = _getStatusColor(item.name);
            return DropdownMenuItem<String>(
              value: item.code, // 코드값을 value로 사용
              child: HighlightedText(
                text: item.name, // 이름을 표시
                query: _pageSearchQuery,
                style: TextStyle(
                  color: itemColor, // 각 항목의 색상
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedCustomerStatus = newValue;
            });
          },
        ),
      ],
    );
  }

  Widget _buildNumberField(String label, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 32, // 고정 높이 설정
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: context.colors.gray10,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.colors.dividerColor),
          ),
          alignment: Alignment.centerLeft,
          child: Text(value.toString(), style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}
