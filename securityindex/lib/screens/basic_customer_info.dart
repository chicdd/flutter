import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/search_panel.dart';
import '../models/customer_detail.dart';
import '../services/api_service.dart';
import '../services/selected_customer_service.dart';
import '../style.dart';
import '../widgets/custom_top_bar.dart';
import '../widgets/component.dart';

class BasicCustomerInfo extends StatefulWidget {
  final SearchPanel? searchpanel;

  const BasicCustomerInfo({super.key, this.searchpanel});

  @override
  State<BasicCustomerInfo> createState() => BasicCustomerInfoState();
}

class BasicCustomerInfoState extends State<BasicCustomerInfo> {
  final _customerService = SelectedCustomerService();

  // 상세 정보 로딩 상태
  bool _isLoading = false;
  CustomerDetail? _customerDetail;

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
  final _emergencyContactController = TextEditingController();
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
  final _cardKeyController = TextEditingController();
  String? _selectedMiSettings; // 미경계 설정
  bool _monthlyAggregation = false; // 월간집계 (발행 = true, 미발행 = false)
  bool _hasKeyHolder = false; // 키 인수여부
  final _acquisitionController = TextEditingController(); // 인수수량
  final _keyBoxesController = TextEditingController(); //키BOX
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
    _cardKeyController.dispose();
    _acquisitionController.dispose();
    _keyBoxesController.dispose();
    _emergencyPhoneController.dispose();
    _mainLocationController.dispose();
    _searchController.dispose();
    _memo1Controller.dispose();
    _memo2Controller.dispose();
    _controlActionController.dispose();
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
    _cardKeyController.clear();
    _acquisitionController.clear();
    _keyBoxesController.clear();
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

    // 드롭다운 데이터를 먼저 로드한 후 고객 데이터 로드
    _initializeData();
  }

  /// 고객 서비스 변경 시 호출
  void _onCustomerServiceChanged() {
    if (mounted && !_customerService.isLoadingDetail) {
      // 로딩 중이 아닐 때만 UI 업데이트
      _updateUIFromService();
    }
  }

  /// 서비스에서 UI 업데이트 (무한 루프 방지)
  Future<void> _updateUIFromService() async {
    final detail = _customerService.customerDetail;
    final customer = _customerService.selectedCustomer;

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

    // 2. 고객 데이터 로드 (전역 서비스에서)
    await _updateUIFromService();
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
      backgroundColor: AppTheme.backgroundColor,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
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
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: 'SMS용 상호',
                  controller: _smsNameController,
                  searchQuery: _pageSearchQuery,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: buildSearchableTextField(
                  label: '관제 연락처1',
                  controller: _contact1Controller,
                  suffixIcon: Icons.phone,
                  searchQuery: _pageSearchQuery,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildSearchableTextField(
                  label: '관제 연락처2',
                  controller: _contact2Controller,
                  suffixIcon: Icons.phone,
                  searchQuery: _pageSearchQuery,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          buildSearchableTextField(
            searchQuery: _pageSearchQuery,
            label: '물건지 주소',
            controller: _addressController,
          ),
          const SizedBox(height: 16),
          buildSearchableTextField(
            searchQuery: _pageSearchQuery,
            label: '대지경로',
            controller: _referenceController,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: buildSearchableTextField(
                  searchQuery: _pageSearchQuery,
                  label: '대표자 이름',
                  controller: _representativeNameController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildSearchableTextField(
                  searchQuery: _pageSearchQuery,
                  label: '대표자 H.P',
                  controller: _representativePhoneController,
                  suffixIcon: Icons.phone_android,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('관제 기본 정보'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: buildSearchableTextField(
                  searchQuery: _pageSearchQuery,
                  label: '관제관리번호',
                  controller: _managementNumberController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildSearchableTextField(
                  searchQuery: _pageSearchQuery,
                  label: '영업관리번호',
                  controller: _erpCusNumberController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: buildSearchableTextField(
                  searchQuery: _pageSearchQuery,
                  label: '공중회선',
                  controller: _publicNumberController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildSearchableTextField(
                  searchQuery: _pageSearchQuery,
                  label: '전용회선',
                  controller: _transmissionNumberController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: buildSearchableTextField(
                  searchQuery: _pageSearchQuery,
                  label: '인터넷회선',
                  controller: _publicTransmissionController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildSearchableTextField(
                  searchQuery: _pageSearchQuery,
                  label: '원격포트 구분',
                  controller: _remoteCodeController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: buildDropdownField(
                  label: '관리구역',
                  value: _selectedManagementArea,
                  items: _managementAreaList,
                  searchQuery: _pageSearchQuery,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedManagementArea = newValue!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildDropdownField(
                  label: '출동권역',
                  value: _selectedOperationArea,
                  items: _operationAreaList,
                  searchQuery: _pageSearchQuery,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedOperationArea = newValue!;
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
                child: buildDropdownField(
                  label: '업종코드',
                  value: _selectedBusinessType,
                  items: _businessTypeList,
                  searchQuery: _pageSearchQuery,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedBusinessType = newValue!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildDropdownField(
                  label: '차량코드',
                  value: _selectVehicleCode,
                  items: _vehicleCodeList,
                  searchQuery: _pageSearchQuery,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectVehicleCode = newValue!;
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
                child: buildDropdownField(
                  label: '관할경찰서',
                  value: _selectedCallLocation,
                  items: _policeStationList,
                  searchQuery: _pageSearchQuery,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCallLocation = newValue!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildDropdownField(
                  label: '관할지구대',
                  value: _selectedCallArea,
                  items: _policeDistrictList,
                  searchQuery: _pageSearchQuery,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCallArea = newValue!;
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
                child: buildSearchableTextField(
                  searchQuery: _pageSearchQuery,
                  label: '기관연락처',
                  controller: _emergencyContactController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildSearchableTextField(
                  searchQuery: _pageSearchQuery,
                  label: '경비개시일자',
                  controller: _securityStartDateController,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('관제 세부 정보'),
          const SizedBox(height: 16),
          _buildStatusDropdownField(
            '관제고객상태',
            _selectedCustomerStatus,
            _customerStatusList,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: buildDropdownField(
                  label: '주 사용회선',
                  value: _selectedUsageType,
                  items: _usageLineList,
                  searchQuery: _pageSearchQuery,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedUsageType = newValue!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildDropdownField(
                  label: '서비스종류',
                  value: _selectedServiceType,
                  items: _serviceTypeList,
                  searchQuery: _pageSearchQuery,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedServiceType = newValue!;
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
                child: buildDropdownField(
                  label: '주장치종류',
                  value: _selectedMainSystem,
                  items: _mainSystemList,
                  searchQuery: _pageSearchQuery,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedMainSystem = newValue!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildDropdownField(
                  label: '주장치분류',
                  value: _selectedSubSystem,
                  items: _subSystemList,
                  searchQuery: _pageSearchQuery,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedSubSystem = newValue!;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          buildSearchableTextField(
            searchQuery: _pageSearchQuery,
            label: '주장치위치',
            controller: _mainLocationController,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: buildSearchableTextField(
                  searchQuery: _pageSearchQuery,
                  label: '원격전화',
                  controller: _remotePhoneController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildSearchableTextField(
                  searchQuery: _pageSearchQuery,
                  label: '원격암호',
                  controller: _remotePasswordController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: buildSearchableTextField(
                  searchQuery: _pageSearchQuery,
                  label: 'ARS전화',
                  controller: _arsPhoneController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildSearchableTextField(
                  searchQuery: _pageSearchQuery,
                  label: '키패드/수량',
                  controller: _cardKeyController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: buildDropdownField(
                  label: '미경계설정',
                  value: _selectedMiSettings,
                  items: _miSettingsList,
                  searchQuery: _pageSearchQuery,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedMiSettings = newValue!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: buildSearchableTextField(
                        searchQuery: _pageSearchQuery,
                        label: '인수수량',
                        controller: _acquisitionController,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: buildSearchableTextField(
                        searchQuery: _pageSearchQuery,
                        label: '키BOX',
                        controller: _keyBoxesController,
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
                    const Text(
                      '키 인수여부',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        buildRadioOption('Y', _hasKeyHolder, (val) {
                          setState(() => _hasKeyHolder = true);
                        }),
                        const SizedBox(width: 16),
                        buildRadioOption('N', !_hasKeyHolder, (val) {
                          setState(() => _hasKeyHolder = false);
                        }),
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
                    const Text(
                      '집계',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        buildRadioOption('발행', _monthlyAggregation, (val) {
                          setState(() => _monthlyAggregation = true);
                        }),
                        const SizedBox(width: 16),
                        buildRadioOption('미발행', !_monthlyAggregation, (val) {
                          setState(() => _monthlyAggregation = false);
                        }),
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
                child: buildSearchableTextField(
                  searchQuery: _pageSearchQuery,
                  label: '연동전화번호',
                  controller: _emergencyPhoneController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
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
                        backgroundColor: AppTheme.selectedColor,
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
                    color: AppTheme.backgroundColor,
                    border: Border.all(color: AppTheme.dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.phone,
                        size: 16,
                        color: AppTheme.textSecondary,
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
              buildCheckbox('DVR고객', _isDvrInspection, (val) {
                setState(() => _isDvrInspection = val ?? false);
              }),
              const SizedBox(width: 20),
              buildCheckbox('무선센서 설치고객', _isWirelessSensorInspection, (val) {
                setState(() => _isWirelessSensorInspection = val ?? false);
              }),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('관제 액션 비고'),
          const SizedBox(height: 16),
          // 비고사항 입력 영역
          TextFormField(
            controller: _controlActionController,
            maxLines: 5,
            style: const TextStyle(fontSize: 13, color: Color(0xFF1D1D1F)),
            decoration: InputDecoration(
              hintText: '여기에 비고사항을 입력하세요...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              contentPadding: const EdgeInsets.all(12),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF007AFF),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 메모 탭
          Row(children: [_buildMemoTab('메모1', 0), _buildMemoTab('메모2', 1)]),
          // 메모 내용 영역
          TextFormField(
            controller: _selectedMemoTab == 0
                ? _memo1Controller
                : _memo2Controller,
            maxLines: 8,
            style: const TextStyle(fontSize: 13, color: Color(0xFF1D1D1F)),
            decoration: InputDecoration(
              hintText: '메모${_selectedMemoTab + 1} 내용을 입력하세요...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              contentPadding: const EdgeInsets.all(12),
              filled: true,
              fillColor: Colors.white,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                borderSide: BorderSide(color: Color(0xFFD1D1D6)),
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                borderSide: BorderSide(color: Color(0xFFD1D1D6)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                borderSide: BorderSide(color: Color(0xFF007AFF), width: 2),
              ),
            ),
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
            color: isSelected ? Colors.white : AppTheme.backgroundColor,
            border: Border.all(color: AppTheme.dividerColor, width: 1),
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
                    ? const Color(0xFF007AFF)
                    : AppTheme.textSecondary,
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
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
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
              fillColor: AppTheme.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppTheme.selectedColor,
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
    return AppTheme.textSecondary;
  }

  // Widget _buildStatusButton(String label, bool isSelected, Color color) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
  //     decoration: BoxDecoration(
  //       color: isSelected ? color : Colors.transparent,
  //       borderRadius: BorderRadius.circular(6),
  //       border: Border.all(color: isSelected ? color : AppTheme.dividerColor),
  //     ),
  //     child: Text(
  //       label,
  //       style: TextStyle(
  //         color: isSelected ? Colors.white : AppTheme.textSecondary,
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
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              border: Border.all(color: AppTheme.dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '로딩 중...',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
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
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
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
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 32, // 고정 높이 설정
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          alignment: Alignment.centerLeft,
          child: Text(value.toString(), style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}
