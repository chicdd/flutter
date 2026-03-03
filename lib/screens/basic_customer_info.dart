import 'package:flutter/material.dart';
import '../functions.dart';
import '../theme.dart';
import '../models/search_panel.dart';
import '../models/customer_detail.dart';
import '../services/api_service.dart';
import '../services/selected_customer_service.dart';
import '../style.dart';
import '../widgets/content_area.dart';
import '../models/customer_form_data.dart';
import '../widgets/customer_form_sections.dart';

class BasicCustomerInfo extends StatefulWidget {
  final SearchPanel? searchpanel;

  const BasicCustomerInfo({super.key, this.searchpanel});

  @override
  State<BasicCustomerInfo> createState() => BasicCustomerInfoState();
}

class BasicCustomerInfoState extends State<BasicCustomerInfo> {
  final _customerService = SelectedCustomerService();

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

  // 공유 폼 데이터
  final _formData = CustomerFormData();

  // 검색 관련
  final _searchController = TextEditingController();

  // FocusNode for TextFormFields
  final _controlActionFocusNode = FocusNode();
  final _memoFocusNode = FocusNode();

  @override
  void dispose() {
    _customerService.removeListener(_onCustomerServiceChanged);
    _formData.dispose();
    _searchController.dispose();
    _controlActionFocusNode.dispose();
    _memoFocusNode.dispose();
    super.dispose();
  }

  void _clearAllFields() {
    setState(() {
      _formData.clearAll();
    });
  }

  void _updateFieldsFromDetail(CustomerDetail detail) {
    // 관제 물건 정보
    _formData.managementNumberController.text = detail.controlManagementNumber;
    _formData.erpCusNumberController.text = detail.erpCusNumber ?? '';
    _formData.controlTypeController.text = detail.controlBusinessName ?? '';
    _formData.smsNameController.text = detail.customerBusinessName ?? '';
    _formData.contact1Controller.text = detail.controlContact1 ?? '';
    _formData.contact2Controller.text = detail.controlContact2 ?? '';
    _formData.addressController.text = detail.propertyAddress ?? '';
    _formData.referenceController.text = detail.responsePath1 ?? '';
    _formData.representativeNameController.text = detail.representative ?? '';
    _formData.representativePhoneController.text = detail.representativeHP ?? '';
    _formData.emergencyContactController.text = detail.emergencyContact ?? '';
    // 관제 기본 정보
    _formData.securityStartDateController.text = detail.securityStartDateFormatted;
    _formData.publicNumberController.text = detail.publicLine ?? '';
    _formData.transmissionNumberController.text = detail.dedicatedLine ?? '';
    _formData.publicTransmissionController.text = detail.internetLine ?? '';
    _formData.remoteCodeController.text = detail.remotePort ?? '';

    // 관제 세부 정보 - 코드값 사용 (DB 값 그대로 사용, 빈 문자열은 null로 처리)
    _formData.selectedUsageType = isValidCode(detail.usageLineTypeCode)
        ? detail.usageLineTypeCode
        : null;
    _formData.selectedCustomerStatus = isValidCode(detail.customerStatusCode)
        ? detail.customerStatusCode
        : null;
    _formData.selectedManagementArea = isValidCode(detail.managementAreaCode)
        ? detail.managementAreaCode
        : null;
    _formData.selectedOperationArea = isValidCode(detail.dispatchAreaCode)
        ? detail.dispatchAreaCode
        : null;
    _formData.selectedBusinessType = isValidCode(detail.businessTypeLargeCode)
        ? detail.businessTypeLargeCode
        : null;
    _formData.selectVehicleCode = isValidCode(detail.vehicleCode)
        ? detail.vehicleCode
        : null;
    _formData.selectedCallLocation = isValidCode(detail.policeStationCode)
        ? detail.policeStationCode
        : null;
    _formData.selectedCallArea = isValidCode(detail.policeSubstationCode)
        ? detail.policeSubstationCode
        : null;

    _formData.arsPhoneController.text = detail.arsPhoneNumber ?? '';
    _formData.remotePhoneController.text = detail.remotePhoneNumber ?? '';
    _formData.selectedMainSystem = isValidCode(detail.deviceTypeCode)
        ? detail.deviceTypeCode
        : null;
    _formData.selectedMiSettings = isValidCode(detail.unguardedTypeCode)
        ? detail.unguardedTypeCode
        : null;
    _formData.remotePasswordController.text = detail.remotePassword ?? '';
    _formData.acquisitionController.text = detail.acquisition ?? '';
    _formData.keyBoxesController.text = detail.keyBoxes ?? '';
    _formData.keypadController.text = detail.keypad ?? '';
    _formData.keypadQuantityController.text = detail.keypadQuantity ?? '';

    // bool 값 직접 사용
    _formData.monthlyAggregation = detail.monthlyAggregationChecked;
    _formData.hasKeyHolder = detail.keyReceiptStatusChecked;
    _formData.isDvrInspection = detail.dvrChecked;
    _formData.isWirelessSensorInspection = stringToBool(detail.wirelessChecked);

    _formData.mainLocationController.text = detail.unguardedClassificationName ?? '';
    _formData.selectedServiceType = isValidCode(detail.serviceTypeCode)
        ? detail.serviceTypeCode
        : null;

    // 메모
    _formData.controlActionController.text = detail.controlAction ?? ''; // 관제액션비고
    _formData.memo1Controller.text = detail.memo1 ?? '';
    _formData.memo2Controller.text = detail.memo2 ?? '';
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
    _formData.managementAreaList = await loadDropdownData('managementarea');
    _formData.operationAreaList = await loadDropdownData('operationarea');
    _formData.businessTypeList = await loadDropdownData('businesstype');
    _formData.vehicleCodeList = await loadDropdownData('vehiclecode');
    _formData.policeStationList = await loadDropdownData('policestation');
    _formData.policeDistrictList = await loadDropdownData('policedistrict');
    _formData.usageLineList = await loadDropdownData('usageline');
    _formData.serviceTypeList = await loadDropdownData('servicetype');
    _formData.mainSystemList = await loadDropdownData('mainsystem');
    _formData.subSystemList = await loadDropdownData('subsystem');
    _formData.miSettingsList = await loadDropdownData('misettings');
    _formData.customerStatusList = await loadDropdownData('customerstatus');

    // 2. 기본고객정보 화면에서는 고객 상세 정보를 로드
    if (_customerService.selectedCustomer != null) {
      _loadedCustomerManagementNumber =
          _customerService.selectedCustomer!.controlManagementNumber;
      await _customerService.loadCustomerDetail();
    }

    if (mounted) {
      // 3. 고객 데이터 로드 (전역 서비스에서)
      await _updateUIFromService();
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
      '관제상호': _formData.controlTypeController.text,
      'SMS용상호': _formData.smsNameController.text,
      '관제연락처1': _formData.contact1Controller.text,
      '관제연락처2': _formData.contact2Controller.text,
      '물건주소': _formData.addressController.text,
      '대처경로1': _formData.referenceController.text,
      '대표자이름': _formData.representativeNameController.text,
      '대표자HP': _formData.representativePhoneController.text,
      '공중회선': _formData.publicNumberController.text,
      '전용회선': _formData.transmissionNumberController.text,
      '인터넷회선': _formData.publicTransmissionController.text,
      '원격포트': _formData.remoteCodeController.text,
      '기관연락처': _formData.emergencyContactController.text,
      '경비개시일자': _formData.securityStartDateController.text,
      '관제고객상태': _formData.selectedCustomerStatus,
      '관리구역': _formData.selectedManagementArea,
      '출동권역': _formData.selectedOperationArea,
      '업종코드': _formData.selectedBusinessType,
      '차량코드': _formData.selectVehicleCode,
      '관할경찰서': _formData.selectedCallLocation,
      '관할지구대': _formData.selectedCallArea,
      '주사용회선': _formData.selectedUsageType,
      '서비스종류': _formData.selectedServiceType,
      '주장치종류': _formData.selectedMainSystem,
      '주장치분류': _formData.selectedSubSystem,
      '주장치위치': _formData.mainLocationController.text,
      '원격전화': _formData.remotePhoneController.text,
      '원격암호': _formData.remotePasswordController.text,
      'ARS전화': _formData.arsPhoneController.text,
      '미경계설정': _formData.selectedMiSettings,
      '인수수량': _formData.acquisitionController.text,
      '키BOX': _formData.keyBoxesController.text,
      '키패드': _formData.keypadController.text,
      '키패드수량': _formData.keypadQuantityController.text,
      '키인수여부': _formData.hasKeyHolder,
      '월간집계': _formData.monthlyAggregation,
      'DVR여부': _formData.isDvrInspection,
      '무선센서': _formData.isWirelessSensorInspection,
      '관제액션비고': _formData.controlActionController.text,
      '메모1': _formData.memo1Controller.text,
      '메모2': _formData.memo2Controller.text,
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
        managementNumber: _formData.managementNumberController.text,
        data: {
          '사용회선종류': _formData.selectedUsageType,
          '관제고객상태코드': _formData.selectedCustomerStatus,
          '공중회선': _formData.publicNumberController.text,
          '전용회선': _formData.transmissionNumberController.text,
          '인터넷회선': _formData.publicTransmissionController.text,
          '관제상호': _formData.controlTypeController.text,
          '관제연락처1': _formData.contact1Controller.text,
          '관제연락처2': _formData.contact2Controller.text,
          '물건주소': _formData.addressController.text,
          '대처경로1': _formData.referenceController.text,
          '대표자': _formData.representativeNameController.text,
          '대표자HP': _formData.representativePhoneController.text,
          '개통일자': _formData.securityStartDateController.text.isEmpty
              ? null
              : '${_formData.securityStartDateController.text} 00:00:00.000',
          '관리구역코드': _formData.selectedManagementArea,
          '출동권역코드': _formData.selectedOperationArea,
          '차량코드': _formData.selectVehicleCode,
          '경찰서코드': _formData.selectedCallLocation,
          '지구대코드': _formData.selectedCallArea,
          '소방서코드': _formData.emergencyContactController.text, //기관연락처
          '업종대코드': _formData.selectedBusinessType,
          '원격전화번호': _formData.remotePhoneController.text,
          '기기종류코드': _formData.selectedMainSystem,

          '미경계종류코드': _formData.selectedMiSettings,

          '원격암호': _formData.remotePasswordController.text,
          '월간집계': _formData.monthlyAggregation ? 1 : 0,
          '관제액션': _formData.controlActionController.text,
          '키인수여부': _formData.hasKeyHolder ? 1 : 0,
          'ARS전화번호': _formData.arsPhoneController.text,
          '미경계분류코드': _formData.selectedSubSystem,
          '서비스종류코드': _formData.selectedServiceType,
          'DVR여부': _formData.isDvrInspection ? 1 : 0,
          '키박스번호': _formData.keyBoxesController.text,
          '원격포트': _formData.remoteCodeController.text,
          'TMP1': _formData.acquisitionController.text, //인수수량
          'TMP2': _formData.keypadController.text, //키패드
          'TMP3': _formData.keypadQuantityController.text, //키패드수량

          'TMP8': _formData.isWirelessSensorInspection ? 1 : 0, //무선센서설치여부

          '메모': _formData.memo1Controller.text,
          '메모2': _formData.memo2Controller.text,
          '고객용상호': _formData.smsNameController.text,
        },
      );

      if (success && mounted) {
        showToast(context, message: '저장되었습니다.');
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
            _updateFieldsFromDetail(_customerService.customerDetail!);
          });
        }
        // ContentArea의 setState를 호출하여 topbar 버튼 업데이트
        if (mounted) {
          context.findAncestorStateOfType<ContentAreaState>()?.setState(() {});
        }
      } else if (mounted) {
        showToast(context, message: '저장에 실패했습니다.');
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
                  borderRadius: BorderRadius.circular(10),
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
                  borderRadius: BorderRadius.circular(10),
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
    _formData.controlTypeController.text = _originalData['관제상호'] ?? '';
    _formData.smsNameController.text = _originalData['SMS용상호'] ?? '';
    _formData.contact1Controller.text = _originalData['관제연락처1'] ?? '';
    _formData.contact2Controller.text = _originalData['관제연락처2'] ?? '';
    _formData.addressController.text = _originalData['물건주소'] ?? '';
    _formData.referenceController.text = _originalData['대처경로'] ?? '';
    _formData.representativeNameController.text = _originalData['대표자이름'] ?? '';
    _formData.representativePhoneController.text = _originalData['대표자HP'] ?? '';
    _formData.publicNumberController.text = _originalData['공중회선'] ?? '';
    _formData.transmissionNumberController.text = _originalData['전용회선'] ?? '';
    _formData.publicTransmissionController.text = _originalData['인터넷회선'] ?? '';
    _formData.remoteCodeController.text = _originalData['원격포트'] ?? '';
    _formData.emergencyContactController.text = _originalData['기관연락처'] ?? '';
    _formData.securityStartDateController.text = _originalData['경비개시일자'] ?? '';
    _formData.selectedCustomerStatus = _originalData['관제고객상태'];
    _formData.selectedManagementArea = _originalData['관리구역'];
    _formData.selectedOperationArea = _originalData['출동권역'];
    _formData.selectedBusinessType = _originalData['업종코드'];
    _formData.selectVehicleCode = _originalData['차량코드'];
    _formData.selectedCallLocation = _originalData['관할경찰서'];
    _formData.selectedCallArea = _originalData['관할지구대'];
    _formData.selectedUsageType = _originalData['주사용회선'];
    _formData.selectedServiceType = _originalData['서비스종류'];
    _formData.selectedMainSystem = _originalData['주장치종류'];
    _formData.selectedSubSystem = _originalData['주장치분류'];
    _formData.mainLocationController.text = _originalData['주장치위치'] ?? '';
    _formData.remotePhoneController.text = _originalData['원격전화'] ?? '';
    _formData.remotePasswordController.text = _originalData['원격암호'] ?? '';
    _formData.selectedMiSettings = _originalData['미경계설정'];
    _formData.acquisitionController.text = _originalData['인수수량'] ?? '';
    _formData.keyBoxesController.text = _originalData['키BOX'] ?? '';
    _formData.keypadController.text = _originalData['키패드'] ?? '';
    _formData.keypadQuantityController.text = _originalData['키패드수량'] ?? '';
    _formData.hasKeyHolder = _originalData['키인수여부'] ?? false;
    _formData.monthlyAggregation = _originalData['월간집계'] ?? false;
    _formData.isDvrInspection = _originalData['DVR여부'] ?? false;
    _formData.isWirelessSensorInspection = _originalData['무선센서'] ?? false;
    _formData.controlActionController.text = _originalData['관제액션비고'] ?? '';
    _formData.memo1Controller.text = _originalData['메모1'] ?? '';
    _formData.memo2Controller.text = _originalData['메모2'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isExtraWideScreen = constraints.maxWidth >= 1500;
          final isWideScreen = constraints.maxWidth >= 900;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: isExtraWideScreen
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 좌측: 관제 물건 정보
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomerPropertyInfoSection(
                              data: _formData,
                              rebuildParent: setState,
                              isEditable: isEditMode,
                              searchQuery: _pageSearchQuery,
                              onChanged: _trackChanges,
                            ),
                            const SizedBox(height: 24),
                            CustomerNotesSection(
                              data: _formData,
                              isEditable: isEditMode,
                              onChanged: _trackChanges,
                              controlActionFocusNode: _controlActionFocusNode,
                              memoFocusNode: _memoFocusNode,
                            ),
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
                            CustomerDetailInfoSection(
                              data: _formData,
                              rebuildParent: setState,
                              isEditable: isEditMode,
                              searchQuery: _pageSearchQuery,
                              onChanged: _trackChanges,
                            ),
                            const SizedBox(height: 24),
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
                            CustomerBasicInfoSection(
                              data: _formData,
                              rebuildParent: setState,
                              isEditable: isEditMode,
                              searchQuery: _pageSearchQuery,
                              onChanged: _trackChanges,
                              managementNumberReadOnly: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : isWideScreen
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 좌측: 관제 물건 정보
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomerPropertyInfoSection(
                              data: _formData,
                              rebuildParent: setState,
                              isEditable: isEditMode,
                              searchQuery: _pageSearchQuery,
                              onChanged: _trackChanges,
                            ),
                            const SizedBox(height: 24),
                            CustomerDetailInfoSection(
                              data: _formData,
                              rebuildParent: setState,
                              isEditable: isEditMode,
                              searchQuery: _pageSearchQuery,
                              onChanged: _trackChanges,
                            ),
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
                            CustomerBasicInfoSection(
                              data: _formData,
                              rebuildParent: setState,
                              isEditable: isEditMode,
                              searchQuery: _pageSearchQuery,
                              onChanged: _trackChanges,
                              managementNumberReadOnly: true,
                            ),
                            const SizedBox(height: 24),
                            CustomerNotesSection(
                              data: _formData,
                              isEditable: isEditMode,
                              onChanged: _trackChanges,
                              controlActionFocusNode: _controlActionFocusNode,
                              memoFocusNode: _memoFocusNode,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomerPropertyInfoSection(
                        data: _formData,
                        rebuildParent: setState,
                        isEditable: isEditMode,
                        searchQuery: _pageSearchQuery,
                        onChanged: _trackChanges,
                      ),
                      const SizedBox(height: 24),
                      CustomerDetailInfoSection(
                        data: _formData,
                        rebuildParent: setState,
                        isEditable: isEditMode,
                        searchQuery: _pageSearchQuery,
                        onChanged: _trackChanges,
                      ),
                      const SizedBox(height: 24),
                      CustomerBasicInfoSection(
                        data: _formData,
                        rebuildParent: setState,
                        isEditable: isEditMode,
                        searchQuery: _pageSearchQuery,
                        onChanged: _trackChanges,
                        managementNumberReadOnly: true,
                      ),
                      const SizedBox(height: 24),
                      CustomerNotesSection(
                        data: _formData,
                        isEditable: isEditMode,
                        onChanged: _trackChanges,
                        controlActionFocusNode: _controlActionFocusNode,
                        memoFocusNode: _memoFocusNode,
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
