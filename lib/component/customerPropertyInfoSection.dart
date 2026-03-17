// ============================================================
// 관제 물건 정보 섹션
// ============================================================
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/customer_form_data.dart';
import '../style.dart';
import '../theme.dart';

class CustomerPropertyInfoSection extends StatelessWidget {
  final CustomerFormData data;
  final bool isEditMode;
  final String searchQuery;
  final VoidCallback? onChanged;
  final bool showRequiredMarks;

  const CustomerPropertyInfoSection({
    super.key,
    required this.data,
    required this.rebuildParent,
    this.isEditMode = true,
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
                  label: showRequiredMarks ? '관제 상호명 *' : '관제 상호명',
                  controller: data.controlTypeController,
                  searchQuery: searchQuery,
                  readOnly: !isEditMode,
                  onFocusLost: onChanged,
                  hasError: data.errorControlType,
                  onChanged: (_) {
                    if (data.errorControlType) {
                      rebuildParent(() => data.errorControlType = false);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextField(
                  label: 'SMS용 상호',
                  controller: data.smsNameController,
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
                  label: '관제 연락처1',
                  controller: data.contact1Controller,
                  suffixIcon: Icons.phone,
                  searchQuery: searchQuery,
                  readOnly: !isEditMode,
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
                  readOnly: !isEditMode,
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
            readOnly: !isEditMode,
            onChanged: (_) => onChanged?.call(),
          ),
          const SizedBox(height: 16),
          CommonTextField(
            label: '대처경로',
            controller: data.referenceController,
            searchQuery: searchQuery,
            readOnly: !isEditMode,
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
                  readOnly: !isEditMode,
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
