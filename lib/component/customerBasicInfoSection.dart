// ============================================================
// 관제 기본 정보 섹션
// ============================================================
import 'package:flutter/cupertino.dart';

import '../models/customer_form_data.dart';
import '../style.dart';
import '../theme.dart';

class CustomerBasicInfoSection extends StatelessWidget {
  final CustomerFormData data;
  final void Function(VoidCallback) rebuildParent;
  final bool isEditMode;
  final String searchQuery;
  final VoidCallback? onChanged;
  final bool showRequiredMarks;
  // 관제관리번호는 기본고객정보 화면에서 항상 readOnly
  final bool managementNumberReadOnly;

  const CustomerBasicInfoSection({
    super.key,
    required this.data,
    required this.rebuildParent,
    this.isEditMode = true,
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
                  label: showRequiredMarks ? '관제관리번호 *' : '관제관리번호',
                  controller: data.managementNumberController,
                  searchQuery: searchQuery,
                  readOnly: managementNumberReadOnly || !isEditMode,
                  onFocusLost: onChanged,
                  hasError: data.errorManagementNumber,
                  onChanged: (_) {
                    if (data.errorManagementNumber) {
                      rebuildParent(() => data.errorManagementNumber = false);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '영업관리번호',
                  controller: data.erpCusNumberController,
                  searchQuery: searchQuery,
                  readOnly: !isEditMode,
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
                  readOnly: !isEditMode,
                  onFocusLost: onChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '전용회선',
                  controller: data.transmissionNumberController,
                  searchQuery: searchQuery,
                  readOnly: !isEditMode,
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
                  readOnly: !isEditMode,
                  onFocusLost: onChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '원격포트 구분',
                  controller: data.remoteCodeController,
                  searchQuery: searchQuery,
                  readOnly: !isEditMode,
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
                  readOnly: !isEditMode,
                  onChanged: (newValue) {
                    rebuildParent(() {
                      data.selectedManagementArea = newValue;
                      data.errorManagementArea = false;
                    });
                    onChanged?.call();
                  },
                  onFocusLost: onChanged,
                  hasError: data.errorManagementArea,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BuildDropdownField(
                  label: '출동권역',
                  value: data.selectedOperationArea,
                  items: data.operationAreaList,
                  searchQuery: searchQuery,
                  readOnly: !isEditMode,
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
                  readOnly: !isEditMode,
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
                  readOnly: !isEditMode,
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
                  readOnly: !isEditMode,
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
                  readOnly: !isEditMode,
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
                  readOnly: !isEditMode,
                  onFocusLost: onChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '경비개시일자',
                  controller: data.securityStartDateController,
                  searchQuery: searchQuery,
                  readOnly: !isEditMode,
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
