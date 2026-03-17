import 'package:flutter/material.dart';
import '../theme.dart';

/// 드래그만 가능한 시간/분 선택기 위젯
class DragOnlyPicker extends StatefulWidget {
  final FixedExtentScrollController controller;
  final int itemCount;
  final Function(int) onSelectedItemChanged;
  final Widget Function(BuildContext, int) itemBuilder;

  const DragOnlyPicker({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.onSelectedItemChanged,
    required this.itemBuilder,
  });

  @override
  State<DragOnlyPicker> createState() => _DragOnlyPickerState();
}

class _DragOnlyPickerState extends State<DragOnlyPicker> {
  final double _accumulatedDelta = 0.0;

  @override
  void initState() {
    super.initState();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!widget.controller.hasClients) return;

    // 현재 스크롤 위치 계산
    final currentPosition = widget.controller.position.pixels;
    final newPosition = currentPosition - details.delta.dy;

    // 스크롤 범위 제한
    final minScroll = 0.0;
    final maxScroll = widget.controller.position.maxScrollExtent;
    final clampedPosition = newPosition.clamp(minScroll, maxScroll);

    // 부드럽게 스크롤 위치 이동
    widget.controller.jumpTo(clampedPosition);

    // 현재 선택된 아이템 계산
    final itemExtent = 40.0;
    final selectedIndex = (clampedPosition / itemExtent).round().clamp(
      0,
      widget.itemCount - 1,
    );
    widget.onSelectedItemChanged(selectedIndex);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!widget.controller.hasClients) return;

    // 가장 가까운 아이템으로 스냅
    final itemExtent = 40.0;
    final currentPosition = widget.controller.position.pixels;
    final nearestItemIndex = (currentPosition / itemExtent).round().clamp(
      0,
      widget.itemCount - 1,
    );

    // 관성 스크롤 처리
    final velocity = details.primaryVelocity ?? 0.0;
    int targetIndex = nearestItemIndex;

    if (velocity.abs() > 500) {
      final itemsToMove = -(velocity / 2000).round();
      targetIndex = (nearestItemIndex + itemsToMove).clamp(
        0,
        widget.itemCount - 1,
      );
    }

    // 부드럽게 타겟 아이템으로 애니메이션
    widget.controller.animateToItem(
      targetIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
    widget.onSelectedItemChanged(targetIndex);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      child: ListWheelScrollView.useDelegate(
        controller: widget.controller,
        itemExtent: 40,
        physics: const NeverScrollableScrollPhysics(),
        childDelegate: ListWheelChildBuilderDelegate(
          builder: widget.itemBuilder,
          childCount: widget.itemCount,
        ),
      ),
    );
  }
}

class TimePickerModal extends StatefulWidget {
  final int? initialHour;
  final int? initialMinute;
  final Function(int? hour, int? minute) onTimeSelected;
  final bool allowNull;

  const TimePickerModal({
    super.key,
    this.initialHour,
    this.initialMinute,
    required this.onTimeSelected,
    this.allowNull = false,
  });

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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
                          color: context.colors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DragOnlyPicker(
                          controller: _hourController,
                          itemCount: widget.allowNull ? 25 : 24,
                          onSelectedItemChanged: (index) {
                            setState(() {
                              if (widget.allowNull) {
                                _selectedHour = index == 0 ? null : index - 1;
                              } else {
                                _selectedHour = index;
                              }
                            });
                          },
                          itemBuilder: (context, index) {
                            int totalCount = widget.allowNull ? 25 : 24;
                            if (index < 0 || index >= totalCount) return null!;

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
                                        ? context.colors.selectedColor
                                        : context.colors.textPrimary,
                                  ),
                                ),
                              );
                            }

                            int actualHour = widget.allowNull
                                ? index - 1
                                : index;
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
                                      ? context.colors.selectedColor
                                      : context.colors.textPrimary,
                                ),
                              ),
                            );
                          },
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
                          color: context.colors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DragOnlyPicker(
                          controller: _minuteController,
                          itemCount: widget.allowNull ? 13 : 12,
                          onSelectedItemChanged: (index) {
                            setState(() {
                              if (widget.allowNull) {
                                _selectedMinute = index == 0
                                    ? null
                                    : (index - 1) * 5;
                              } else {
                                _selectedMinute = index * 5;
                              }
                            });
                          },
                          itemBuilder: (context, index) {
                            int totalCount = widget.allowNull ? 13 : 12;
                            if (index < 0 || index >= totalCount) return null!;

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
                                        ? context.colors.selectedColor
                                        : context.colors.textPrimary,
                                  ),
                                ),
                              );
                            }

                            int actualMinute = widget.allowNull
                                ? (index - 1) * 5
                                : index * 5;
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
                                      ? context.colors.selectedColor
                                      : context.colors.textPrimary,
                                ),
                              ),
                            );
                          },
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
                      side: BorderSide(color: context.colors.dividerColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '취소',
                      style: TextStyle(
                        color: context.colors.textSecondary,
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
                      backgroundColor: context.colors.selectedColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(color: Colors.white, fontSize: 15),
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
    super.key,
    required this.label,
    this.hour,
    this.minute,
    required this.onTimeChanged,
    this.enabled = true,
    this.showXXForZero = false,
    this.allowNull = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 1.0,
      child: Row(
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: context.colors.textPrimary,
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
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                color: context.colors.textEnable,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: context.colors.dividerColor),
              ),
              child: Text(
                hour == null
                    ? '--시'
                    : (showXXForZero && hour == 0
                          ? 'XX시'
                          : '${hour.toString().padLeft(2, '0')}시'),
                style: TextStyle(
                  color: context.colors.textPrimary,
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
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                color: context.colors.textEnable,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: context.colors.dividerColor),
              ),
              child: Text(
                minute == null
                    ? '--분'
                    : '${minute.toString().padLeft(2, '0')}분',
                style: TextStyle(
                  color: context.colors.textPrimary,
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
