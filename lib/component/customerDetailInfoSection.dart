// ============================================================
// 관제 세부 정보 섹션
// ============================================================
import 'package:flutter/material.dart';

import '../models/customer_form_data.dart';
import '../style.dart';
import '../theme.dart';

class CustomerDetailInfoSection extends StatelessWidget {
  final CustomerFormData data;
  final void Function(VoidCallback) rebuildParent;
  final bool isEditMode;
  final String searchQuery;
  final VoidCallback? onChanged;

  const CustomerDetailInfoSection({
    super.key,
    required this.data,
    required this.rebuildParent,
    this.isEditMode = true,
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
            value: data.selectedCustomerStatus,
            items: data.customerStatusList,
            searchQuery: '',
            readOnly: !isEditMode,
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
                  readOnly: !isEditMode,
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
                  readOnly: !isEditMode,
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
                  readOnly: !isEditMode,
                  onChanged: (newValue) {
                    rebuildParent(() {
                      data.selectedMainSystem = newValue;
                      data.errorMainSystem = false;
                    });
                    onChanged?.call();
                  },
                  onFocusLost: onChanged,
                  hasError: data.errorMainSystem,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BuildDropdownField(
                  label: '주장치분류',
                  value: data.selectedSubSystem,
                  items: data.subSystemList,
                  searchQuery: searchQuery,
                  readOnly: !isEditMode,
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
            readOnly: !isEditMode,
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
                  readOnly: !isEditMode,
                  onFocusLost: onChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '원격암호',
                  controller: data.remotePasswordController,
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
                  label: 'ARS전화',
                  controller: data.arsPhoneController,
                  searchQuery: searchQuery,
                  readOnly: !isEditMode,
                  onFocusLost: onChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '키패드',
                  controller: data.keypadController,
                  searchQuery: searchQuery,
                  readOnly: !isEditMode,
                  onFocusLost: onChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: '수량',
                  controller: data.keypadQuantityController,
                  searchQuery: searchQuery,
                  readOnly: !isEditMode,
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
                  readOnly: !isEditMode,
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
                  readOnly: !isEditMode,
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
                          readOnly: !isEditMode,
                          onChanged: (_) {
                            rebuildParent(() => data.hasKeyHolder = true);
                            onChanged?.call();
                          },
                        ),
                        const SizedBox(width: 16),
                        BuildRadioOption(
                          label: 'N',
                          value: !data.hasKeyHolder,
                          readOnly: !isEditMode,
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
                          readOnly: !isEditMode,
                          onChanged: (_) {
                            rebuildParent(() => data.monthlyAggregation = true);
                            onChanged?.call();
                          },
                        ),
                        const SizedBox(width: 16),
                        BuildRadioOption(
                          label: '미발행',
                          value: !data.monthlyAggregation,
                          readOnly: !isEditMode,
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
                  readOnly: !isEditMode,
                  onFocusLost: onChanged,
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
                          final phone = data.emergencyPhoneController.text
                              .trim();
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
                readOnly: !isEditMode,
                onChanged: (val) {
                  rebuildParent(() => data.isDvrInspection = val);
                  onChanged?.call();
                },
              ),
              const SizedBox(width: 20),
              BuildCheckbox(
                label: '무선센서 설치고객',
                value: data.isWirelessSensorInspection,
                readOnly: !isEditMode,
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
