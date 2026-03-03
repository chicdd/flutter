import 'package:flutter/material.dart';
import '../models/customer_form_data.dart';
import '../style.dart';
import '../theme.dart';

// ============================================================
// 관제 물건 정보 섹션
// ============================================================
class CustomerPropertyInfoSection extends StatelessWidget {
  final CustomerFormData data;
  final bool isEditable;
  final String searchQuery;
  final VoidCallback? onChanged;
  final bool showRequiredMarks;

  const CustomerPropertyInfoSection({
    super.key,
    required this.data,
    required this.rebuildParent,
    this.isEditable = true,
    this.searchQuery = '',
    this.onChanged,
    this.showRequiredMarks = false,
  });

  final void Function(VoidCallback) rebuildParent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
        border: isEditable
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
                  label: showRequiredMarks ? '관제 상호명 *' : '관제 상호명',
                  controller: data.controlTypeController,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  onFocusLost: onChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: 'SMS용 상호',
                  controller: data.smsNameController,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  onFocusLost: onChanged,
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
                  controller: data.contact1Controller,
                  suffixIcon: Icons.phone,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  onFocusLost: onChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '관제 연락처2',
                  controller: data.contact2Controller,
                  suffixIcon: Icons.phone,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  onFocusLost: onChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CommonTextField(
            label: showRequiredMarks ? '물건지 주소 *' : '물건지 주소',
            controller: data.addressController,
            searchQuery: searchQuery,
            readOnly: !isEditable,
            onChanged: (_) => onChanged?.call(),
          ),
          const SizedBox(height: 16),
          CommonTextField(
            label: '대처경로',
            controller: data.referenceController,
            searchQuery: searchQuery,
            readOnly: !isEditable,
            onChanged: (_) => onChanged?.call(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CommonTextField(
                  label: '대표자 이름',
                  controller: data.representativeNameController,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  onFocusLost: onChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '대표자 H.P',
                  controller: data.representativePhoneController,
                  suffixIcon: Icons.phone_android,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  onFocusLost: onChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 관제 기본 정보 섹션
// ============================================================
class CustomerBasicInfoSection extends StatelessWidget {
  final CustomerFormData data;
  final void Function(VoidCallback) rebuildParent;
  final bool isEditable;
  final String searchQuery;
  final VoidCallback? onChanged;
  final bool showRequiredMarks;
  // 관제관리번호는 기본고객정보 화면에서 항상 readOnly
  final bool managementNumberReadOnly;

  const CustomerBasicInfoSection({
    super.key,
    required this.data,
    required this.rebuildParent,
    this.isEditable = true,
    this.searchQuery = '',
    this.onChanged,
    this.showRequiredMarks = false,
    this.managementNumberReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
        border: isEditable
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
                  label: showRequiredMarks ? '관제관리번호 *' : '관제관리번호',
                  controller: data.managementNumberController,
                  searchQuery: searchQuery,
                  readOnly: managementNumberReadOnly || !isEditable,
                  onFocusLost: onChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '영업관리번호',
                  controller: data.erpCusNumberController,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  onFocusLost: onChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CommonTextField(
                  label: '공중회선',
                  controller: data.publicNumberController,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  onFocusLost: onChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '전용회선',
                  controller: data.transmissionNumberController,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  onFocusLost: onChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CommonTextField(
                  label: '인터넷회선',
                  controller: data.publicTransmissionController,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  onFocusLost: onChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '원격포트 구분',
                  controller: data.remoteCodeController,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  onFocusLost: onChanged,
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
                  value: data.selectedManagementArea,
                  items: data.managementAreaList,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  onChanged: (newValue) {
                    rebuildParent(() => data.selectedManagementArea = newValue);
                    onChanged?.call();
                  },
                  onFocusLost: onChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BuildDropdownField(
                  label: '출동권역',
                  value: data.selectedOperationArea,
                  items: data.operationAreaList,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  onChanged: (newValue) {
                    rebuildParent(() => data.selectedOperationArea = newValue);
                    onChanged?.call();
                  },
                  onFocusLost: onChanged,
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
                  value: data.selectedBusinessType,
                  items: data.businessTypeList,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  onChanged: (newValue) {
                    rebuildParent(() => data.selectedBusinessType = newValue);
                    onChanged?.call();
                  },
                  onFocusLost: onChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BuildDropdownField(
                  label: '차량코드',
                  value: data.selectVehicleCode,
                  items: data.vehicleCodeList,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  onChanged: (newValue) {
                    rebuildParent(() => data.selectVehicleCode = newValue);
                    onChanged?.call();
                  },
                  onFocusLost: onChanged,
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
                  value: data.selectedCallLocation,
                  items: data.policeStationList,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  onChanged: (newValue) {
                    rebuildParent(() => data.selectedCallLocation = newValue);
                    onChanged?.call();
                  },
                  onFocusLost: onChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BuildDropdownField(
                  label: '관할지구대',
                  value: data.selectedCallArea,
                  items: data.policeDistrictList,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  onChanged: (newValue) {
                    rebuildParent(() => data.selectedCallArea = newValue);
                    onChanged?.call();
                  },
                  onFocusLost: onChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CommonTextField(
                  label: '기관연락처',
                  controller: data.emergencyContactController,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  onFocusLost: onChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '경비개시일자',
                  controller: data.securityStartDateController,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  onFocusLost: onChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 관제 세부 정보 섹션
// ============================================================
class CustomerDetailInfoSection extends StatelessWidget {
  final CustomerFormData data;
  final void Function(VoidCallback) rebuildParent;
  final bool isEditable;
  final String searchQuery;
  final VoidCallback? onChanged;

  const CustomerDetailInfoSection({
    super.key,
    required this.data,
    required this.rebuildParent,
    this.isEditable = true,
    this.searchQuery = '',
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
        border: isEditable
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
            value: data.selectedCustomerStatus,
            items: data.customerStatusList,
            searchQuery: '',
            readOnly: !isEditable,
            onChanged: (newValue) {
              rebuildParent(() => data.selectedCustomerStatus = newValue);
              onChanged?.call();
            },
            onFocusLost: onChanged,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: BuildDropdownField(
                  label: '주 사용회선',
                  value: data.selectedUsageType,
                  items: data.usageLineList,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  onChanged: (newValue) {
                    rebuildParent(() => data.selectedUsageType = newValue);
                    onChanged?.call();
                  },
                  onFocusLost: onChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BuildDropdownField(
                  label: '서비스종류',
                  value: data.selectedServiceType,
                  items: data.serviceTypeList,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  onChanged: (newValue) {
                    rebuildParent(() => data.selectedServiceType = newValue);
                    onChanged?.call();
                  },
                  onFocusLost: onChanged,
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
                  value: data.selectedMainSystem,
                  items: data.mainSystemList,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  onChanged: (newValue) {
                    rebuildParent(() => data.selectedMainSystem = newValue);
                    onChanged?.call();
                  },
                  onFocusLost: onChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BuildDropdownField(
                  label: '주장치분류',
                  value: data.selectedSubSystem,
                  items: data.subSystemList,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  onChanged: (newValue) {
                    rebuildParent(() => data.selectedSubSystem = newValue);
                    onChanged?.call();
                  },
                  onFocusLost: onChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CommonTextField(
            label: '주장치위치',
            controller: data.mainLocationController,
            searchQuery: searchQuery,
            readOnly: !isEditable,
            onChanged: (_) => onChanged?.call(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CommonTextField(
                  label: '원격전화',
                  controller: data.remotePhoneController,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  onFocusLost: onChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '원격암호',
                  controller: data.remotePasswordController,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  onFocusLost: onChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CommonTextField(
                  label: 'ARS전화',
                  controller: data.arsPhoneController,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  onFocusLost: onChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '키패드',
                  controller: data.keypadController,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  onFocusLost: onChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '수량',
                  controller: data.keypadQuantityController,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  keyboardType: TextInputType.number,
                  onFocusLost: onChanged,
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
                  value: data.selectedMiSettings,
                  items: data.miSettingsList,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  onChanged: (newValue) {
                    rebuildParent(() => data.selectedMiSettings = newValue);
                    onChanged?.call();
                  },
                  onFocusLost: onChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '인수수량',
                  controller: data.acquisitionController,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  keyboardType: TextInputType.number,
                  onFocusLost: onChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '키BOX',
                  controller: data.keyBoxesController,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  onFocusLost: onChanged,
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
                          value: data.hasKeyHolder,
                          readOnly: !isEditable,
                          onChanged: (_) {
                            rebuildParent(() => data.hasKeyHolder = true);
                            onChanged?.call();
                          },
                        ),
                        const SizedBox(width: 16),
                        BuildRadioOption(
                          label: 'N',
                          value: !data.hasKeyHolder,
                          readOnly: !isEditable,
                          onChanged: (_) {
                            rebuildParent(() => data.hasKeyHolder = false);
                            onChanged?.call();
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
                          value: data.monthlyAggregation,
                          readOnly: !isEditable,
                          onChanged: (_) {
                            rebuildParent(() => data.monthlyAggregation = true);
                            onChanged?.call();
                          },
                        ),
                        const SizedBox(width: 16),
                        BuildRadioOption(
                          label: '미발행',
                          value: !data.monthlyAggregation,
                          readOnly: !isEditable,
                          onChanged: (_) {
                            rebuildParent(
                              () => data.monthlyAggregation = false,
                            );
                            onChanged?.call();
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
                  label: '연동전화번호',
                  controller: data.emergencyPhoneController,
                  searchQuery: searchQuery,
                  readOnly: !isEditable,
                  onFocusLost: onChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    if (isEditable)
                      ElevatedButton(
                        onPressed: () {
                          final phone =
                              data.emergencyPhoneController.text.trim();
                          if (phone.isNotEmpty) {
                            rebuildParent(() {
                              data.linkedPhoneNumbers.add(phone);
                              data.emergencyPhoneController.clear();
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
          if (data.linkedPhoneNumbers.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: List.generate(data.linkedPhoneNumbers.length, (index) {
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
                        data.linkedPhoneNumbers[index],
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          rebuildParent(
                            () => data.linkedPhoneNumbers.removeAt(index),
                          );
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
          ],
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BuildCheckbox(
                label: 'DVR고객',
                value: data.isDvrInspection,
                readOnly: !isEditable,
                onChanged: (val) {
                  rebuildParent(() => data.isDvrInspection = val);
                  onChanged?.call();
                },
              ),
              const SizedBox(width: 20),
              BuildCheckbox(
                label: '무선센서 설치고객',
                value: data.isWirelessSensorInspection,
                readOnly: !isEditable,
                onChanged: (val) {
                  rebuildParent(() => data.isWirelessSensorInspection = val);
                  onChanged?.call();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 관제 액션 비고 + 메모 섹션 (StatefulWidget - 탭 상태 관리)
// ============================================================
class CustomerNotesSection extends StatefulWidget {
  final CustomerFormData data;
  final bool isEditable;
  final VoidCallback? onChanged;
  final FocusNode? controlActionFocusNode;
  final FocusNode? memoFocusNode;

  const CustomerNotesSection({
    super.key,
    required this.data,
    this.isEditable = true,
    this.onChanged,
    this.controlActionFocusNode,
    this.memoFocusNode,
  });

  @override
  State<CustomerNotesSection> createState() => _CustomerNotesSectionState();
}

class _CustomerNotesSectionState extends State<CustomerNotesSection> {
  int _selectedMemoTab = 0;

  @override
  Widget build(BuildContext context) {
    final isEditable = widget.isEditable;
    final data = widget.data;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
        border: isEditable
            ? Border.all(color: context.colors.selectedColor, width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('관제 액션 비고'),
          const SizedBox(height: 16),
          TextFormField(
            controller: data.controlActionController,
            focusNode: widget.controlActionFocusNode,
            maxLines: 5,
            style: const TextStyle(fontSize: 13, color: Color(0xFF1D1D1F)),
            decoration: InputDecoration(
              hintStyle: TextStyle(color: context.colors.textSecondary),
              contentPadding: const EdgeInsets.all(12),
              filled: true,
              fillColor: isEditable
                  ? context.colors.textEnable
                  : context.colors.textReadOnly,
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
                  color: isEditable
                      ? context.colors.selectedColor
                      : context.colors.dividerColor,
                  width: isEditable ? 2 : 1,
                ),
              ),
            ),
            readOnly: !isEditable,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMemoTab(context, '메모1', 0),
              _buildMemoTab(context, '메모2', 1),
            ],
          ),
          TextFormField(
            controller: _selectedMemoTab == 0
                ? data.memo1Controller
                : data.memo2Controller,
            focusNode: widget.memoFocusNode,
            maxLines: 6,
            style: TextStyle(fontSize: 13, color: context.colors.textPrimary),
            decoration: InputDecoration(
              hintStyle: TextStyle(color: context.colors.textSecondary),
              contentPadding: const EdgeInsets.all(12),
              filled: true,
              fillColor: isEditable
                  ? context.colors.textEnable
                  : context.colors.textReadOnly,
              border: OutlineInputBorder(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                borderSide: BorderSide(color: context.colors.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                borderSide: BorderSide(color: context.colors.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                borderSide: BorderSide(
                  color: isEditable
                      ? context.colors.selectedColor
                      : context.colors.dividerColor,
                  width: isEditable ? 2 : 1,
                ),
              ),
            ),
            readOnly: !isEditable,
          ),
        ],
      ),
    );
  }

  Widget _buildMemoTab(BuildContext context, String label, int index) {
    final isSelected = _selectedMemoTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedMemoTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? context.colors.textReadOnly
                : context.colors.cardBackground,
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
                color: context.colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
