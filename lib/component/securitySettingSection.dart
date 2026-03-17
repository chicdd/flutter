// ============================================================
// 관제 세부 정보 섹션
// ============================================================
import 'package:flutter/material.dart';

import '../models/customer_form_data.dart';
import '../style.dart';
import '../theme.dart';
import '../component/timeSettingCard.dart';

class SecuritySettingsSection extends StatelessWidget {
  final CustomerFormData data;
  final void Function(VoidCallback) rebuildParent;
  final bool isEditMode;
  final String searchQuery;
  final VoidCallback? onChanged;

  const SecuritySettingsSection({
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
          buildSectionTitle('경계약정 및 무단해제 설정'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TimeSettingCard(
                  title: '평일',
                  guardStartHour: data.weekdayGuardStartHour,
                  guardStartMinute: data.weekdayGuardStartMinute,
                  guardEndHour: data.weekdayGuardEndHour,
                  guardEndMinute: data.weekdayGuardEndMinute,
                  unauthStartHour: data.weekdayUnauthorizedStartHour,
                  unauthStartMinute: data.weekdayUnauthorizedStartMinute,
                  unauthEndHour: data.weekdayUnauthorizedEndHour,
                  unauthEndMinute: data.weekdayUnauthorizedEndMinute,
                  isUsed: data.isWeekdayUsed,
                  isEditMode: isEditMode,
                  onGuardStartChanged: (hour, minute) {
                    rebuildParent(() {
                      data.weekdayGuardStartHour = hour;
                      data.weekdayGuardStartMinute = minute;
                    });
                    onChanged?.call();
                  },
                  onGuardEndChanged: (hour, minute) {
                    rebuildParent(() {
                      data.weekdayGuardEndHour = hour;
                      data.weekdayGuardEndMinute = minute;
                    });
                    onChanged?.call();
                  },
                  onUnauthStartChanged: (hour, minute) {
                    rebuildParent(() {
                      data.weekdayUnauthorizedStartHour = hour;
                      data.weekdayUnauthorizedStartMinute = minute;
                    });
                    onChanged?.call();
                  },
                  onUnauthEndChanged: (hour, minute) {
                    rebuildParent(() {
                      data.weekdayUnauthorizedEndHour = hour;
                      data.weekdayUnauthorizedEndMinute = minute;
                    });
                    onChanged?.call();
                  },
                  onUsedChanged: (val) {
                    rebuildParent(() {
                      data.isWeekdayUsed = val;
                    });
                    onChanged?.call();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TimeSettingCard(
                  title: '주말',
                  guardStartHour: data.weekendGuardStartHour,
                  guardStartMinute: data.weekendGuardStartMinute,
                  guardEndHour: data.weekendGuardEndHour,
                  guardEndMinute: data.weekendGuardEndMinute,
                  unauthStartHour: data.weekendUnauthorizedStartHour,
                  unauthStartMinute: data.weekendUnauthorizedStartMinute,
                  unauthEndHour: data.weekendUnauthorizedEndHour,
                  unauthEndMinute: data.weekendUnauthorizedEndMinute,
                  isUsed: data.isWeekendUsed,
                  isEditMode: isEditMode,
                  onGuardStartChanged: (hour, minute) {
                    rebuildParent(() {
                      data.weekendGuardStartHour = hour;
                      data.weekendGuardStartMinute = minute;
                    });
                    onChanged?.call();
                  },
                  onGuardEndChanged: (hour, minute) {
                    rebuildParent(() {
                      data.weekendGuardEndHour = hour;
                      data.weekendGuardEndMinute = minute;
                    });
                    onChanged?.call();
                  },
                  onUnauthStartChanged: (hour, minute) {
                    rebuildParent(() {
                      data.weekendUnauthorizedStartHour = hour;
                      data.weekendUnauthorizedStartMinute = minute;
                    });
                    onChanged?.call();
                  },
                  onUnauthEndChanged: (hour, minute) {
                    rebuildParent(() {
                      data.weekendUnauthorizedEndHour = hour;
                      data.weekendUnauthorizedEndMinute = minute;
                    });
                    onChanged?.call();
                  },
                  onUsedChanged: (val) {
                    rebuildParent(() {
                      data.isWeekendUsed = val;
                    });
                    onChanged?.call();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TimeSettingCard(
                  title: '휴일',
                  guardStartHour: data.holidayGuardStartHour,
                  guardStartMinute: data.holidayGuardStartMinute,
                  guardEndHour: data.holidayGuardEndHour,
                  guardEndMinute: data.holidayGuardEndMinute,
                  unauthStartHour: data.holidayUnauthorizedStartHour,
                  unauthStartMinute: data.holidayUnauthorizedStartMinute,
                  unauthEndHour: data.holidayUnauthorizedEndHour,
                  unauthEndMinute: data.holidayUnauthorizedEndMinute,
                  isUsed: data.isHolidayUsed,
                  isEditMode: isEditMode,
                  onGuardStartChanged: (hour, minute) {
                    rebuildParent(() {
                      data.holidayGuardStartHour = hour;
                      data.holidayGuardStartMinute = minute;
                    });
                    onChanged?.call();
                  },
                  onGuardEndChanged: (hour, minute) {
                    rebuildParent(() {
                      data.holidayGuardEndHour = hour;
                      data.holidayGuardEndMinute = minute;
                    });
                    onChanged?.call();
                  },
                  onUnauthStartChanged: (hour, minute) {
                    rebuildParent(() {
                      data.holidayUnauthorizedStartHour = hour;
                      data.holidayUnauthorizedStartMinute = minute;
                    });
                    onChanged?.call();
                  },
                  onUnauthEndChanged: (hour, minute) {
                    rebuildParent(() {
                      data.holidayUnauthorizedEndHour = hour;
                      data.holidayUnauthorizedEndMinute = minute;
                    });
                    onChanged?.call();
                  },
                  onUsedChanged: (val) {
                    rebuildParent(() {
                      data.isHolidayUsed = val;
                    });
                    onChanged?.call();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
