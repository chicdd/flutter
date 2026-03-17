// ============================================================
// 시간 설정 카드 컴포넌트 (경계약정 및 무단해제 설정)
// ============================================================
import 'package:flutter/material.dart';

import '../style.dart';
import '../theme.dart';
import '../widgets/time_picker_modal.dart';

class TimeSettingCard extends StatelessWidget {
  final String title;
  final int? guardStartHour;
  final int? guardStartMinute;
  final int? guardEndHour;
  final int? guardEndMinute;
  final int? unauthStartHour;
  final int? unauthStartMinute;
  final int? unauthEndHour;
  final int? unauthEndMinute;
  final bool isUsed;
  final bool isEditMode;
  final void Function(int? hour, int? minute) onGuardStartChanged;
  final void Function(int? hour, int? minute) onGuardEndChanged;
  final void Function(int? hour, int? minute) onUnauthStartChanged;
  final void Function(int? hour, int? minute) onUnauthEndChanged;
  final void Function(bool val) onUsedChanged;

  const TimeSettingCard({
    super.key,
    required this.title,
    required this.guardStartHour,
    required this.guardStartMinute,
    required this.guardEndHour,
    required this.guardEndMinute,
    required this.unauthStartHour,
    required this.unauthStartMinute,
    required this.unauthEndHour,
    required this.unauthEndMinute,
    required this.isUsed,
    required this.isEditMode,
    required this.onGuardStartChanged,
    required this.onGuardEndChanged,
    required this.onUnauthStartChanged,
    required this.onUnauthEndChanged,
    required this.onUsedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.cardBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 17,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(color: context.colors.dividerColor),
                const SizedBox(height: 12),
                TimePickerButton(
                  label: '경계',
                  hour: guardStartHour,
                  minute: guardStartMinute,
                  allowNull: true,
                  enabled: isEditMode,
                  onTimeChanged: onGuardStartChanged,
                ),
                const SizedBox(height: 12),
                Divider(color: context.colors.dividerColor),
                const SizedBox(height: 12),
                TimePickerButton(
                  label: '해제',
                  hour: guardEndHour,
                  minute: guardEndMinute,
                  allowNull: true,
                  enabled: isEditMode,
                  onTimeChanged: onGuardEndChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.cardBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      '무단',
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    BuildCheckbox(
                      label: '사용',
                      value: isUsed,
                      readOnly: !isEditMode,
                      onChanged: onUsedChanged,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: context.colors.dividerColor),
                const SizedBox(height: 12),
                TimePickerButton(
                  label: '경계',
                  hour: unauthStartHour,
                  minute: unauthStartMinute,
                  enabled: isUsed && isEditMode,
                  showXXForZero: true,
                  allowNull: true,
                  onTimeChanged: onUnauthStartChanged,
                ),
                const SizedBox(height: 12),
                Divider(color: context.colors.dividerColor),
                const SizedBox(height: 12),
                TimePickerButton(
                  label: '해제',
                  hour: unauthEndHour,
                  minute: unauthEndMinute,
                  enabled: isUsed && isEditMode,
                  showXXForZero: true,
                  allowNull: true,
                  onTimeChanged: onUnauthEndChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
