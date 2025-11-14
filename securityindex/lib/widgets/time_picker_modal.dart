import 'package:flutter/material.dart';
import '../theme.dart';

class TimePickerModal extends StatefulWidget {
  final int initialHour;
  final int initialMinute;
  final Function(int hour, int minute) onTimeSelected;

  const TimePickerModal({
    Key? key,
    required this.initialHour,
    required this.initialMinute,
    required this.onTimeSelected,
  }) : super(key: key);

  @override
  State<TimePickerModal> createState() => _TimePickerModalState();
}

class _TimePickerModalState extends State<TimePickerModal> {
  late int _selectedHour;
  late int _selectedMinute;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialHour;
    _selectedMinute = widget.initialMinute;
    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController =
        FixedExtentScrollController(initialItem: _selectedMinute ~/ 5);
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
                              _selectedHour = index;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              if (index < 0 || index >= 24) return null;
                              return Center(
                                child: Text(
                                  index.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: index == _selectedHour
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: index == _selectedHour
                                        ? AppTheme.selectedColor
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                              );
                            },
                            childCount: 24,
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
                              _selectedMinute = index * 5;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              if (index < 0 || index >= 12) return null;
                              final minute = index * 5;
                              return Center(
                                child: Text(
                                  minute.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: minute == _selectedMinute
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: minute == _selectedMinute
                                        ? AppTheme.selectedColor
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                              );
                            },
                            childCount: 12,
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
  final int hour;
  final int minute;
  final Function(int hour, int minute) onTimeChanged;

  const TimePickerButton({
    Key? key,
    required this.label,
    required this.hour,
    required this.minute,
    required this.onTimeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF252525),
            fontSize: 15,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => TimePickerModal(
                initialHour: hour,
                initialMinute: minute,
                onTimeSelected: onTimeChanged,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: Text(
              '${hour.toString().padLeft(2, '0')}시',
              style: const TextStyle(
                color: Color(0xFF252525),
                fontSize: 15,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => TimePickerModal(
                initialHour: hour,
                initialMinute: minute,
                onTimeSelected: onTimeChanged,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: Text(
              '${minute.toString().padLeft(2, '0')}분',
              style: const TextStyle(
                color: Color(0xFF252525),
                fontSize: 15,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
