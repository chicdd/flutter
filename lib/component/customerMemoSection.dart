// ============================================================
// 관제 액션 비고 + 메모 섹션 (StatefulWidget - 탭 상태 관리)
// ============================================================
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/customer_form_data.dart';
import '../style.dart';
import '../theme.dart';

class CustomerMemoSection extends StatefulWidget {
  final CustomerFormData data;
  final bool isEditMode;
  final VoidCallback? onChanged;
  final FocusNode? controlActionFocusNode;
  final FocusNode? memoFocusNode;

  const CustomerMemoSection({
    super.key,
    required this.data,
    this.isEditMode = true,
    this.onChanged,
    this.controlActionFocusNode,
    this.memoFocusNode,
  });

  @override
  State<CustomerMemoSection> createState() => _CustomerMemoSectionState();
}

class _CustomerMemoSectionState extends State<CustomerMemoSection> {
  int _selectedMemoTab = 0;

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.isEditMode;
    final data = widget.data;

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
          TextFormField(
            controller: data.controlActionController,
            focusNode: widget.controlActionFocusNode,
            maxLines: 3,
            style: const TextStyle(fontSize: 13, color: Color(0xFF1D1D1F)),
            decoration: InputDecoration(
              hintStyle: TextStyle(color: context.colors.textSecondary),
              contentPadding: const EdgeInsets.all(12),
              filled: true,
              fillColor: isEditMode
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
          Row(
            children: [
              _buildMemoTab(context, '메모1', 0),
              _buildMemoTab(context, '메모2', 1),
            ],
          ),
          Expanded(
            child: TextFormField(
              controller: _selectedMemoTab == 0
                  ? data.memo1Controller
                  : data.memo2Controller,
              focusNode: widget.memoFocusNode,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(fontSize: 13, color: context.colors.textPrimary),
              decoration: InputDecoration(
                hintStyle: TextStyle(color: context.colors.textSecondary),
                contentPadding: const EdgeInsets.all(12),
                filled: true,
                fillColor: isEditMode
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
                    color: isEditMode
                        ? context.colors.selectedColor
                        : context.colors.dividerColor,
                    width: isEditMode ? 2 : 1,
                  ),
                ),
              ),
              readOnly: !isEditMode,
            ),
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
