import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../style.dart';
import '../config/topbar_config.dart';

/// 재사용 가능한 상단바 위젯
class CustomTopBar extends StatefulWidget {
  final String title;
  final List<TopBarButton> buttons;
  final bool showSearch;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onPageSearch; // 페이지 내 검색 콜백
  final VoidCallback? onSearchClosed; // 검색바 닫힐 때 콜백

  const CustomTopBar({
    Key? key,
    required this.title,
    this.buttons = const [],
    this.showSearch = true,
    this.searchController,
    this.onSearchChanged,
    this.onPageSearch,
    this.onSearchClosed,
  }) : super(key: key);

  @override
  State<CustomTopBar> createState() => CustomTopBarState();
}

// 페이지 검색 상태를 관리하는 InheritedWidget
class PageSearchState extends InheritedWidget {
  final String searchQuery;
  final VoidCallback clearSearch;

  const PageSearchState({
    super.key,
    required this.searchQuery,
    required this.clearSearch,
    required super.child,
  });

  static PageSearchState? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PageSearchState>();
  }

  @override
  bool updateShouldNotify(PageSearchState oldWidget) {
    return searchQuery != oldWidget.searchQuery;
  }
}

class CustomTopBarState extends State<CustomTopBar>
    with SingleTickerProviderStateMixin {
  bool _isSearchExpanded = false;
  late TextEditingController _internalSearchController;
  late AnimationController _searchAnimationController;
  late Animation<double> _searchAnimation;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _internalSearchController =
        widget.searchController ?? TextEditingController();
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    if (widget.searchController == null) {
      _internalSearchController.dispose();
    }
    _searchAnimationController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // 외부에서 호출 가능한 검색바 열기 메서드
  void openSearch() {
    if (!_isSearchExpanded) {
      setState(() {
        _isSearchExpanded = true;
        _searchAnimationController.forward();
      });
      // 검색바가 펼쳐지면 포커스
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    }
  }

  // 검색 초기화 및 포커스 (Ctrl+F 연속 사용을 위한 메서드)
  void resetAndFocusSearch() {
    if (!_isSearchExpanded) {
      // 검색바가 닫혀있으면 열기
      setState(() {
        _isSearchExpanded = true;
        _searchAnimationController.forward();
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _searchFocusNode.requestFocus();
          _internalSearchController.clear();
          if (widget.onPageSearch != null) {
            widget.onPageSearch!('');
          }
        }
      });
    } else {
      // 검색바가 이미 열려있으면 내용 초기화하고 포커스만 다시 주기
      setState(() {
        _internalSearchController.clear();
      });
      if (widget.onPageSearch != null) {
        widget.onPageSearch!('');
      }
      _searchFocusNode.requestFocus();
      // 텍스트 전체 선택
      _internalSearchController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _internalSearchController.text.length,
      );
    }
  }

  // 외부에서 호출 가능한 검색바 닫기 메서드
  void closeSearch() {
    if (_isSearchExpanded) {
      setState(() {
        _isSearchExpanded = false;
        _searchAnimationController.reverse();
        _internalSearchController.clear();
      });
      // 검색 초기화
      if (widget.onPageSearch != null) {
        widget.onPageSearch!('');
      }
      // 검색바 닫힘 콜백 호출
      if (widget.onSearchClosed != null) {
        widget.onSearchClosed!();
      }
    }
  }

  void _toggleSearch() {
    if (_isSearchExpanded) {
      closeSearch();
    } else {
      openSearch();
    }
  }

  void _handleKeyEvent(RawKeyEvent event) {
    // Ctrl+F: 검색바 열기
    if (event is RawKeyDownEvent) {
      if (event.isControlPressed &&
          event.logicalKey == LogicalKeyboardKey.keyF) {
        openSearch();
      }
      // ESC: 검색바 닫기
      else if (event.logicalKey == LogicalKeyboardKey.escape) {
        closeSearch();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: 16),
          // 버튼들
          ...widget.buttons.map(
            (button) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: buildStatusChip(
                button.label,
                button.backgroundColor ?? AppTheme.selectedColor,
                onTap: button.onPressed,
              ),
            ),
          ),
          const Spacer(),
          // 검색 영역
          if (widget.showSearch) _buildSearchArea(),
        ],
      ),
    );
  }

  Widget _buildSearchArea() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: _isSearchExpanded ? 300 : 0,
          height: 40,
          margin: EdgeInsets.only(right: _isSearchExpanded ? 8 : 0),
          child: _isSearchExpanded
              ? TextFormField(
                  controller: _internalSearchController,
                  focusNode: _searchFocusNode,
                  style: const TextStyle(fontSize: 13),
                  onChanged: (value) {
                    setState(() {}); // suffixIcon 업데이트를 위해
                    if (widget.onSearchChanged != null) {
                      widget.onSearchChanged!(value);
                    }
                    if (widget.onPageSearch != null) {
                      widget.onPageSearch!(value);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: '페이지 내 검색 (Ctrl+F)',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF007AFF),
                        width: 2,
                      ),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: Color(0xFF86868B),
                    ),
                    suffixIcon: _internalSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _internalSearchController.clear();
                              });
                              if (widget.onPageSearch != null) {
                                widget.onPageSearch!('');
                              }
                            },
                          )
                        : null,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        InkWell(
          onTap: _toggleSearch,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.selectedColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.search,
              color: AppTheme.selectedColor,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

// 텍스트 하이라이트 위젯
class HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool? softWrap;
  final TextAlign? textAlign;

  const HighlightedText({
    Key? key,
    required this.text,
    required this.query,
    this.style,
    this.highlightStyle,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.textAlign,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty || text.isEmpty) {
      return Text(
        text,
        style: style,
        overflow: overflow,
        maxLines: maxLines,
        softWrap: softWrap,
        textAlign: textAlign,
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    if (!lowerText.contains(lowerQuery)) {
      return Text(
        text,
        style: style,
        overflow: overflow,
        maxLines: maxLines,
        softWrap: softWrap,
        textAlign: textAlign,
      );
    }

    List<TextSpan> spans = [];
    int start = 0;

    while (start < text.length) {
      final index = lowerText.indexOf(lowerQuery, start);

      if (index == -1) {
        // 남은 텍스트 추가
        spans.add(TextSpan(text: text.substring(start), style: style));
        break;
      }

      // 매칭 전 텍스트
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: style));
      }

      // 하이라이트된 텍스트
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style:
              highlightStyle ??
              TextStyle(
                backgroundColor: Colors.yellow.shade300,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
        ),
      );

      start = index + query.length;
    }

    return RichText(
      text: TextSpan(children: spans, style: style),
      overflow: overflow ?? TextOverflow.visible,
      maxLines: maxLines,
      softWrap: softWrap ?? true,
      textAlign: textAlign ?? TextAlign.start,
    );
  }
}
