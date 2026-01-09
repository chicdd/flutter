import 'package:flutter/material.dart';
import '../theme.dart';

class TimePickerModal extends StatefulWidget {
  final int? initialHour;
  final int? initialMinute;
  final Function(int? hour, int? minute) onTimeSelected;
  final bool allowNull;

  const TimePickerModal({
    Key? key,
    this.initialHour,
    this.initialMinute,
    required this.onTimeSelected,
    this.allowNull = false,
  }) : super(key: key);

  @override
  State<TimePickerModal> createState() => _TimePickerModalState();
}

class _TimePickerModalState extends State<TimePickerModal> {
  late int? _selectedHour;
  late int? _selectedMinute;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialHour;
    _selectedMinute = widget.initialMinute;
    // allowNull이 true면 빈칸이 첫 번째 항목 (index 0)
    // 빈칸이 있으면 실제 시간은 index + 1
    int hourIndex = widget.allowNull
        ? (widget.initialHour == null ? 0 : widget.initialHour! + 1)
        : (widget.initialHour ?? 0);
    int minuteIndex = widget.allowNull
        ? (widget.initialMinute == null ? 0 : (widget.initialMinute! ~/ 5) + 1)
        : ((widget.initialMinute ?? 0) ~/ 5);

    _hourController = FixedExtentScrollController(initialItem: hourIndex);
    _minuteController = FixedExtentScrollController(initialItem: minuteIndex);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '시간 선택',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 시간 선택기
                Expanded(
                  child: Column(
                    children: [
                      const Text('시', style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 8),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListWheelScrollView.useDelegate(
                          controller: _hourController,
                          itemExtent: 40,
                          physics: const FixedExtentScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          onSelectedItemChanged: (index) {
                            setState(() {
                              if (widget.allowNull) {
                                _selectedHour = index == 0 ? null : index - 1;
                              } else {
                                _selectedHour = index;
                              }
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              int totalCount = widget.allowNull ? 25 : 24;
                              if (index < 0 || index >= totalCount) return null;

                              // allowNull이 true이고 index가 0이면 빈칸 표시
                              if (widget.allowNull && index == 0) {
                                bool isSelected = _selectedHour == null;
                                return Center(
                                  child: Text(
                                    '--',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? AppTheme.selectedColor
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                );
                              }

                              int actualHour =
                                  widget.allowNull ? index - 1 : index;
                              bool isSelected = _selectedHour == actualHour;

                              return Center(
                                child: Text(
                                  actualHour.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? AppTheme.selectedColor
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                              );
                            },
                            childCount: widget.allowNull ? 25 : 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // 분 선택기 (5분 단위)
                Expanded(
                  child: Column(
                    children: [
                      const Text('분', style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 8),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListWheelScrollView.useDelegate(
                          controller: _minuteController,
                          itemExtent: 40,
                          physics: const FixedExtentScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          onSelectedItemChanged: (index) {
                            setState(() {
                              if (widget.allowNull) {
                                _selectedMinute =
                                    index == 0 ? null : (index - 1) * 5;
                              } else {
                                _selectedMinute = index * 5;
                              }
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              int totalCount = widget.allowNull ? 13 : 12;
                              if (index < 0 || index >= totalCount) return null;

                              // allowNull이 true이고 index가 0이면 빈칸 표시
                              if (widget.allowNull && index == 0) {
                                bool isSelected = _selectedMinute == null;
                                return Center(
                                  child: Text(
                                    '--',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? AppTheme.selectedColor
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                );
                              }

                              int actualMinute =
                                  widget.allowNull ? (index - 1) * 5 : index * 5;
                              bool isSelected = _selectedMinute == actualMinute;

                              return Center(
                                child: Text(
                                  actualMinute.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? AppTheme.selectedColor
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                              );
                            },
                            childCount: widget.allowNull ? 13 : 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppTheme.dividerColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onTimeSelected(_selectedHour, _selectedMinute);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppTheme.selectedColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 시간 선택 버튼 위젯
class TimePickerButton extends StatelessWidget {
  final String label;
  final int? hour;
  final int? minute;
  final Function(int? hour, int? minute) onTimeChanged;
  final bool enabled;
  final bool showXXForZero;
  final bool allowNull;

  const TimePickerButton({
    Key? key,
    required this.label,
    this.hour,
    this.minute,
    required this.onTimeChanged,
    this.enabled = true,
    this.showXXForZero = false,
    this.allowNull = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.3,
      child: Row(
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF252525),
                fontSize: 15,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: enabled
                ? () {
                    showDialog(
                      context: context,
                      builder: (context) => TimePickerModal(
                        initialHour: hour,
                        initialMinute: minute,
                        onTimeSelected: onTimeChanged,
                        allowNull: allowNull,
                      ),
                    );
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE5E5E5)),
              ),
              child: Text(
                hour == null
                    ? '--시'
                    : (showXXForZero && hour == 0
                        ? 'XX시'
                        : '${hour.toString().padLeft(2, '0')}시'),
                style: const TextStyle(
                  color: Color(0xFF252525),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: enabled
                ? () {
                    showDialog(
                      context: context,
                      builder: (context) => TimePickerModal(
                        initialHour: hour,
                        initialMinute: minute,
                        onTimeSelected: onTimeChanged,
                        allowNull: allowNull,
                      ),
                    );
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE5E5E5)),
              ),
              child: Text(
                minute == null
                    ? '--분'
                    : '${minute.toString().padLeft(2, '0')}분',
                style: const TextStyle(
                  color: Color(0xFF252525),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
