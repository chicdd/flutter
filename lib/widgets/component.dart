import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'custom_top_bar.dart'; // HighlightedText import

/// ========================================
/// 공통 검색 가능 텍스트 필드 빌더
/// ========================================
List<CodeData> dropdownList = [];

/// 검색 쿼리를 포함한 CommonTextField 빌더 함수
Widget buildSearchableTextField({
  required String label,
  TextEditingController? controller,
  String? hintText,
  IconData? suffixIcon,
  bool readOnly = false,
  VoidCallback? onTap,
  TextInputType? keyboardType,
  int? maxLines,
  String searchQuery = '',
}) {
  bool containsQuery() {
    if (searchQuery.isEmpty) return false;
    if (controller == null) return false;
    final text = controller.text.toLowerCase();
    final query = searchQuery.toLowerCase();
    return text.contains(query) || label.toLowerCase().contains(query);
  }

  final hasMatch = containsQuery();

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
                  label.toLowerCase().contains(searchQuery.toLowerCase())
              ? Colors.yellow.shade300
              : Colors.transparent,
        ),
      ),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        maxLines: maxLines ?? 1,
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
              color: hasMatch ? Colors.yellow.shade700 : AppTheme.dividerColor,
              width: hasMatch ? 2 : 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: hasMatch ? Colors.yellow.shade700 : AppTheme.dividerColor,
              width: hasMatch ? 2 : 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: hasMatch ? Colors.yellow.shade700 : AppTheme.selectedColor,
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
    ],
  );
}

/// 드롭다운 데이터 로드
Future<List<CodeData>> loadDropdownData(String dropdownName) async {
  try {
    // 캐시를 통해 드롭다운 데이터 로드
    List<CodeData> data = await CodeDataCache.getCodeData(dropdownName);
    return data;
  } catch (e) {
    print('드롭다운 데이터 로드 오류: $e');
    return [];
  }
}

/// ========================================
/// 공통 드롭다운 필드 빌더
/// ========================================

/// 드롭다운 필드 빌더 함수 (onChanged 콜백 포함)
Widget buildDropdownField({
  required String label,
  required String? value,
  required List<CodeData> items,
  required Function(String?) onChanged,
  String searchQuery = '',
}) {
  // 검색 쿼리 매칭 확인 함수
  bool containsQuery() {
    if (searchQuery.isEmpty) return false;
    final query = searchQuery.toLowerCase();
    // 라벨이 검색어를 포함하는지 확인
    if (label.toLowerCase().contains(query)) return true;
    // 선택된 값이 검색어를 포함하는지 확인
    if (value != null) {
      final selectedItem = items.firstWhere(
        (item) => item.code == value,
        orElse: () => CodeData(code: '', name: ''),
      );
      final selectedText = '[${selectedItem.code}] ${selectedItem.name}';
      if (selectedText.toLowerCase().contains(query)) return true;
    }
    return false;
  }

  final hasMatch = containsQuery();

  // 데이터가 로드되지 않았으면 빈 드롭다운 표시
  if (items.isEmpty) {
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
                    label.toLowerCase().contains(searchQuery.toLowerCase())
                ? Colors.yellow.shade300
                : Colors.transparent,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            border: Border.all(color: AppTheme.dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '로딩 중...',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  // value가 items에 없으면 null로 설정 (에러 방지)
  String? selectedValue = value;
  if (value != null && !items.any((item) => item.code == value)) {
    print('$label - 선택된 값($value)이 items에 없음, null로 설정');
    selectedValue = null;
  }

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
                  label.toLowerCase().contains(searchQuery.toLowerCase())
              ? Colors.yellow.shade300
              : Colors.transparent,
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
            top: 9,
            right: 6,
            bottom: 9,
          ),
          filled: true,
          fillColor: hasMatch
              ? Colors.yellow.shade100
              : AppTheme.backgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: hasMatch ? Colors.yellow.shade700 : AppTheme.dividerColor,
              width: hasMatch ? 2 : 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: hasMatch ? Colors.yellow.shade700 : AppTheme.dividerColor,
              width: hasMatch ? 2 : 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: hasMatch ? Colors.yellow.shade700 : AppTheme.selectedColor,
              width: 2,
            ),
          ),
        ),
        icon: const Icon(Icons.arrow_drop_down, size: 24),
        isExpanded: true,
        selectedItemBuilder: (BuildContext context) {
          return items.map((CodeData item) {
            // 선택된 항목일 때만 강조 표시
            final isSelected = item.code == selectedValue;
            return Container(
              alignment: Alignment.centerLeft,
              child: HighlightedText(
                text: '[${item.code}] ${item.name}',
                query: searchQuery,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            );
          }).toList();
        },
        items: items.map((CodeData item) {
          return DropdownMenuItem<String>(
            value: item.code,
            child: HighlightedText(
              text: '[${item.code}] ${item.name}',
              query: searchQuery,
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    ],
  );
}

/// ========================================
/// 공통 드롭다운 위젯 (기존 CommonDropdown)
/// ========================================

/// 공통 드롭다운 위젯
/// CodeData 타입의 리스트를 받아서 드롭다운을 표시합니다.
class CommonDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<CodeData> items;
  final Function(String?) onChanged;
  final String searchQuery;

  const CommonDropdown({
    Key? key,
    required this.label,
    this.value,
    required this.items,
    required this.onChanged,
    this.searchQuery = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return buildDropdownField(
      label: label,
      value: value,
      items: items,
      onChanged: onChanged,
      searchQuery: searchQuery,
    );
  }
}

/// ========================================
/// 공통 체크박스 위젯 (텍스트 클릭 가능)
/// ========================================

Widget buildCheckboxOption(
  String label,
  bool value,
  Function(bool?) onChanged,
) {
  return InkWell(
    onTap: () => onChanged(!value),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.selectedColor,
        ),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    ),
  );
}

/// ========================================
/// 공통 라디오버튼 위젯 (텍스트 클릭 가능)
/// ========================================
Widget buildRadioOption(
  String label,
  bool isSelected,
  Function(bool?) onChanged,
) {
  return InkWell(
    onTap: () => onChanged(true),
    child: Row(
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
    ),
  );
}

/// 체크박스 빌더 (텍스트 클릭 가능)
Widget buildCheckbox(String label, bool value, Function(bool?) onChanged) {
  return InkWell(
    onTap: () => onChanged(!value),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF007AFF),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF252525),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    ),
  );
}
