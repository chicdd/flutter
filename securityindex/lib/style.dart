import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:securityindex/services/api_service.dart';
import 'theme.dart';

/// ========================================
/// 공통 텍스트 필드 위젯
/// ========================================

/// 기본 텍스트 필드 (라벨이 위에 있음)
class CommonTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final IconData? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final int? maxLines;
  final String? searchQuery;

  const CommonTextField({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
    this.keyboardType,
    this.maxLines = 1,
    this.searchQuery,
  });

  bool _containsQuery() {
    if (searchQuery == null || searchQuery!.isEmpty) return false;
    if (controller == null) return false;
    final text = controller!.text.toLowerCase();
    final query = searchQuery!.toLowerCase();
    return text.contains(query) || label.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final hasMatch = _containsQuery();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
            backgroundColor:
                hasMatch &&
                    searchQuery != null &&
                    label.toLowerCase().contains(searchQuery!.toLowerCase())
                ? Colors.yellow.shade300
                : Colors.transparent,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Color(0xFF999999),
                fontSize: 14,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              filled: true,
              fillColor: hasMatch
                  ? Colors.yellow.shade100
                  : AppTheme.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: hasMatch
                      ? Colors.yellow.shade700
                      : AppTheme.dividerColor,
                  width: hasMatch ? 2 : 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: hasMatch
                      ? Colors.yellow.shade700
                      : AppTheme.dividerColor,
                  width: hasMatch ? 2 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: hasMatch
                      ? Colors.yellow.shade700
                      : AppTheme.selectedColor,
                  width: 2,
                ),
              ),
              suffixIcon: suffixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        suffixIcon,
                        size: 20,
                        color: const Color(0xFF9DC579),
                      ),
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

/// 라벨이 왼쪽에 있는 인라인 텍스트 필드 (확장 고객정보용)
class InlineTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final double labelWidth;
  final bool readOnly;
  final VoidCallback? onTap;
  final double? maxWidth;

  const InlineTextField({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.labelWidth = 120,
    this.readOnly = false,
    this.onTap,
    this.maxWidth = 350,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF2A2A2A),
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth ?? 350),
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              onTap: onTap,
              decoration: InputDecoration(
                hintText: hintText,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                filled: true,
                fillColor: AppTheme.backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppTheme.selectedColor,
                    width: 1,
                  ),
                ),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}

/// 읽기 전용 텍스트 필드
class ReadOnlyTextField extends StatelessWidget {
  final String label;
  final String value;

  const ReadOnlyTextField({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: TextField(
            controller: controller,
            readOnly: true,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              filled: true,
              fillColor: AppTheme.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppTheme.selectedColor,
                  width: 1,
                ),
              ),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

/// ========================================
/// 드롭다운 필드
/// ========================================

class CommonDropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<CodeData> items;
  final Function(String?) onChanged;

  const CommonDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // value가 items에 없으면 null로 설정 (에러 방지)
    String? selectedValue = value;
    if (value != null && !items.any((item) => item.code == value)) {
      selectedValue = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: selectedValue,
          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.only(
              left: 12,
              top: 10,
              right: 6,
              bottom: 10,
            ),
            filled: true,
            fillColor: AppTheme.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppTheme.selectedColor,
                width: 1,
              ),
            ),
          ),
          icon: const Icon(Icons.arrow_drop_down, size: 24),
          isExpanded: true,
          selectedItemBuilder: (BuildContext context) {
            return items.map((CodeData item) {
              return Text('[${item.code}] ${item.name}');
            }).toList();
          },
          items: items.map((CodeData item) {
            return DropdownMenuItem<String>(
              value: item.code,
              child: Text('[${item.code}] ${item.name}'),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// ========================================
/// 버튼 및 상태 위젯
/// ========================================

/// 상태 버튼 (선택/미선택)
class StatusButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback? onTap;

  const StatusButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? color : AppTheme.dividerColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

Widget buildSectionTitle(String title) {
  return Text(
    title,
    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  );
}

Widget buildStatusChip(String label, Color color, {VoidCallback? onTap}) {
  return Container(
    width: 90, // 모든 버튼 동일한 길이
    height: 30,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Center(
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}

/// 관제고객상태에 따른 색상 반환
Color getStatusColor(String status) {
  if (status.contains('정상') || status.contains('관제중')) {
    return Colors.green;
  } else if (status.contains('보류') ||
      status.contains('대기') ||
      status.contains('미개시')) {
    return Colors.orange;
  } else if (status.contains('해지') || status.contains('중지')) {
    return Colors.red;
  }
  return AppTheme.textSecondary;
}

/// ========================================
/// 라디오 및 체크박스 옵션
/// ========================================

/// 라디오 옵션
class RadioOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool?) onChanged;

  const RadioOption({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<bool>(
          value: true,
          groupValue: isSelected,
          onChanged: onChanged,
          activeColor: AppTheme.selectedColor,
        ),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

/// ========================================
/// 숫자 필드
/// ========================================

class NumberDisplayField extends StatelessWidget {
  final String label;
  final int value;

  const NumberDisplayField({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          alignment: Alignment.centerLeft,
          child: Text(value.toString(), style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}

/// ========================================
/// 메모 탭
/// ========================================

class MemoTab extends StatelessWidget {
  final String label;
  final int index;
  final int selectedIndex;
  final VoidCallback onTap;

  const MemoTab({
    super.key,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : AppTheme.backgroundColor,
            border: Border.all(color: AppTheme.dividerColor, width: 1),
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
                color: isSelected
                    ? const Color(0xFF007AFF)
                    : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 유효한 코드 값인지 확인 (null 또는 빈 문자열/공백 체크)
bool isValidCode(String? code) {
  if (code == null) return false;
  final trimmed = code.trim();
  return trimmed.isNotEmpty;
}

//string을 bool로 변환
bool stringToBool(String text) {
  bool result;
  if (text == '1') {
    result = true;
  } else {
    result = false;
  }
  return result;
}

//datetime 형식을 String으로 가져 와
String dateParsing(String? date) {
  // null 또는 빈 문자열 체크
  if (date == null || date.isEmpty) return '';

  try {
    // ISO 8601 형식 (2015-03-21T00:00:00) 처리
    if (date.contains('T')) {
      final dateTime = DateTime.parse(date);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
    // 이미 YYYY-MM-DD 형식이면 그대로 반환
    return date;
  } catch (e) {
    print('날짜 파싱 오류: $e');
    return date;
  }
}

// datetime 형식을 상세한 String으로 변환 (yyyy-MM-dd 오후 h:mm 형식)
String detailDateParsing(String? date) {
  // null 또는 빈 문자열 체크
  if (date == null || date.isEmpty) return '';

  try {
    // ISO 8601 형식 (2015-03-21T14:38:00) 처리
    DateTime dateTime;
    if (date.contains('T')) {
      dateTime = DateTime.parse(date);
    } else {
      // 다른 형식도 시도
      dateTime = DateTime.parse(date);
    }

    // 년-월-일 형식
    final dateStr =
        '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';

    // 오전/오후 판단
    final period = dateTime.hour >= 12 ? '오후' : '오전';

    // 12시간 형식으로 시간 변환
    int hour = dateTime.hour;
    if (hour > 12) {
      hour = hour - 12;
    } else if (hour == 0) {
      hour = 12;
    }

    // 분 형식
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$dateStr $period $hour:$minute';
  } catch (e) {
    print('날짜 파싱 오류: $e');
    return date;
  }
}

/// ========================================
/// 날짜 관련 유틸리티 함수
/// ========================================

/// 다양한 날짜 포맷을 YYYY-MM-DD 형식으로 변환
/// 지원 포맷:
/// - 20240809 → 2024-08-09
/// - 2024.08.09 → 2024-08-09
/// - 240809 → 2024-08-09
/// - 2024-08-09 → 2024-08-09 (그대로 반환)
String? parseDateString(String input) {
  if (input.isEmpty) return null;

  // 구분자 제거 (-, ., /, 공백 등)
  final cleanInput = input.replaceAll(RegExp(r'[-./\s]'), '');

  try {
    // 숫자만 남은 문자열의 길이로 형식 판단
    if (cleanInput.length == 8) {
      // 20240809 형식
      final year = cleanInput.substring(0, 4);
      final month = cleanInput.substring(4, 6);
      final day = cleanInput.substring(6, 8);

      // 유효성 검증
      final date = DateTime(int.parse(year), int.parse(month), int.parse(day));

      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } else if (cleanInput.length == 6) {
      // 240809 형식 (연도 2자리)
      final year = '20${cleanInput.substring(0, 2)}';
      final month = cleanInput.substring(2, 4);
      final day = cleanInput.substring(4, 6);

      // 유효성 검증
      final date = DateTime(int.parse(year), int.parse(month), int.parse(day));

      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } else {
      // 그 외의 경우 원본 반환
      return input;
    }
  } catch (e) {
    print('날짜 파싱 오류: $e, 입력값: $input');
    return null;
  }
}

/// ========================================
/// 날짜 다이얼로그 및 검증 헬퍼 함수
/// ========================================

/// 날짜 선택 다이얼로그를 띄우고 선택된 날짜를 반환
/// [initialDate] 초기 선택 날짜 (기본값: 오늘)
/// [firstDate] 선택 가능한 최소 날짜 (기본값: 2008-08-01)
/// [lastDate] 선택 가능한 최대 날짜 (기본값: 오늘)
Future<DateTime?> showDatePickerDialog(
  BuildContext context, {
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  return await showDatePicker(
    context: context,
    initialDate: initialDate ?? DateTime.now(),
    firstDate: firstDate ?? DateTime(2008, 8),
    lastDate: lastDate ?? DateTime.now(),
    locale: const Locale('ko', 'KR'),
  );
}

/// 날짜 텍스트를 검증하고 파싱하여 DateTime 반환
/// 성공 시 DateTime, 실패 시 null 반환
/// [parseDateString] 함수를 사용하여 다양한 포맷 지원
DateTime? validateAndParseDateText(String text) {
  final parsedDate = parseDateString(text);
  if (parsedDate != null) {
    try {
      return DateFormat('yyyy-MM-dd').parseStrict(parsedDate);
    } catch (e) {
      return null;
    }
  }
  return null;
}

// 날짜 형식 변환 (yyyy-MM-dd)
String recordDateFormatted(DateTime date) {
  if (date == null) return '';
  return '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}';
}

/// ========================================
/// 날짜 입력 필드 위젯
/// ========================================

/// 날짜 선택 TextField (캘린더 아이콘 포함)
class DateTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Function(BuildContext, bool) onCalendarPressed;
  final Function()? onSubmitted;

  const DateTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.onCalendarPressed,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF252525),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'yyyy-MM-dd',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF4318FF),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today, size: 20),
                onPressed: () {
                  // label로 시작/종료 판단
                  final isStartDate = label.contains('시작');
                  onCalendarPressed(context, isStartDate);
                },
              ),
            ),
            style: const TextStyle(fontSize: 14),
            onSubmitted: (_) {
              if (onSubmitted != null) {
                onSubmitted!();
              }
            },
          ),
        ],
      ),
    );
  }
}

/// ========================================
/// 시간 입력 필드 위젯
/// ========================================

/// 시간 선택 TextField (시계 아이콘 포함)
class TimePickerField extends StatelessWidget {
  final String label;
  final TextEditingController hourController;
  final TextEditingController minuteController;
  final VoidCallback? onTimePickerPressed;

  const TimePickerField({
    super.key,
    required this.label,
    required this.hourController,
    required this.minuteController,
    this.onTimePickerPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF252525),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // 시 입력
              Expanded(
                child: TextField(
                  controller: hourController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '00',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF4318FF),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  ':',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              // 분 입력
              Expanded(
                child: TextField(
                  controller: minuteController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '00',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF4318FF),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              // 시계 아이콘
              if (onTimePickerPressed != null)
                IconButton(
                  icon: const Icon(Icons.access_time, size: 20),
                  onPressed: onTimePickerPressed,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
