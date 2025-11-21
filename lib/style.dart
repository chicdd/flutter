import 'package:flutter/material.dart';
import 'package:securityindex/services/api_service.dart';
import 'theme.dart';
import 'models/customer_detail.dart';

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
    Key? key,
    required this.label,
    this.controller,
    this.hintText,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
    this.keyboardType,
    this.maxLines = 1,
    this.searchQuery,
  }) : super(key: key);

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
    Key? key,
    required this.label,
    this.controller,
    this.hintText,
    this.labelWidth = 120,
    this.readOnly = false,
    this.onTap,
    this.maxWidth = 350,
  }) : super(key: key);

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

  const ReadOnlyTextField({Key? key, required this.label, required this.value})
    : super(key: key);

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
    Key? key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  }) : super(key: key);

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
    Key? key,
    required this.label,
    required this.isSelected,
    required this.color,
    this.onTap,
  }) : super(key: key);

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
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onChanged,
  }) : super(key: key);

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

/// 체크박스 옵션
class CheckboxOption extends StatelessWidget {
  final String label;
  final bool value;
  final Function(bool?) onChanged;

  const CheckboxOption({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: value,
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

  const NumberDisplayField({Key? key, required this.label, required this.value})
    : super(key: key);

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
    Key? key,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  }) : super(key: key);

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
