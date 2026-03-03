import 'package:flutter/material.dart';
import '../screens/customerregistration.dart';
import '../services/selected_customer_service.dart';
import '../theme.dart';
import '../services/theme_service.dart';

class NavigationItem {
  final String title;
  final IconData icon;
  final List<String>? subItems;

  NavigationItem({required this.title, required this.icon, this.subItems});
}

class NavigationSidebar extends StatefulWidget {
  final Future<void> Function(String, String?) onNavigate;
  final String? initialSelectedMenu;
  final String? initialSelectedSubMenu;

  const NavigationSidebar({
    super.key,
    required this.onNavigate,
    this.initialSelectedMenu,
    this.initialSelectedSubMenu,
  });

  @override
  State<NavigationSidebar> createState() => _NavigationSidebarState();
}

class _NavigationSidebarState extends State<NavigationSidebar> {
  String? selectedMainItem;
  String? selectedSubItem;
  String? expandedItem;
  final _customerService = SelectedCustomerService(); // 서비스 추가
  final _themeService = ThemeService(); // 테마 서비스 추가

  @override
  void initState() {
    super.initState();
    // 초기 선택 상태 설정
    selectedMainItem = widget.initialSelectedMenu;
    selectedSubItem = widget.initialSelectedSubMenu;
    // 서브 메뉴가 있으면 해당 메인 메뉴를 펼친 상태로
    if (widget.initialSelectedSubMenu != null &&
        widget.initialSelectedMenu != null) {
      expandedItem = widget.initialSelectedMenu;
    }
    // 테마 변경 리스너 등록
    _themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  void didUpdateWidget(NavigationSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 외부에서 선택이 변경되면 업데이트
    if (widget.initialSelectedMenu != oldWidget.initialSelectedMenu ||
        widget.initialSelectedSubMenu != oldWidget.initialSelectedSubMenu) {
      setState(() {
        selectedMainItem = widget.initialSelectedMenu;
        selectedSubItem = widget.initialSelectedSubMenu;
        // 서브 메뉴가 있으면 해당 메인 메뉴를 펼친 상태로
        if (widget.initialSelectedSubMenu != null &&
            widget.initialSelectedMenu != null) {
          expandedItem = widget.initialSelectedMenu;
        }
      });
    }
  }

  final List<NavigationItem> navigationItems = [
    NavigationItem(
      title: '관제고객정보',
      icon: Icons.business,
      subItems: [
        '관제고객등록',
        '기본고객정보',
        '확장고객정보',
        '스마트어플인증등록',
        '문서지원',
        '설치자재현황',
        'IOT장비',
      ],
    ),
    NavigationItem(title: '사용자 / 존정보', icon: Icons.person_outline),
    NavigationItem(title: '최근신호이력', icon: Icons.history),
    NavigationItem(
      title: '관제 / 고객로그',
      icon: Icons.article_outlined,
      subItems: ['검색로그 내역조회', '고객정보 변동이력'],
    ),
    NavigationItem(title: '약도', icon: Icons.map_outlined),
    NavigationItem(title: '도면', icon: Icons.architecture_outlined),
    NavigationItem(
      title: '관제개통 / 루프',
      icon: Icons.settings_input_antenna,
      subItems: ['관제신호 개통처리', '보수점검 완료이력'],
    ),
    NavigationItem(title: 'AS 접수', icon: Icons.build_outlined),
    NavigationItem(title: '녹취조회', icon: Icons.mic_outlined),
    NavigationItem(
      title: '영업정보',
      icon: Icons.business_center_outlined,
      subItems: ['영업정보', '최근 수금 이력', '최근 방문 및 A/S 이력'],
    ),
    NavigationItem(title: '설정', icon: Icons.settings),
  ];

  /// 관제고객등록 창을 Overlay로 표시
  void _showCustomerRegistrationWindow(BuildContext context) {
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (_) => _FloatingWindow(
        title: '관제고객등록',
        onClose: () => overlayEntry.remove(),
        child: const CustomerRegistration(),
      ),
    );
    Overlay.of(context).insert(overlayEntry);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: context.colors.gray10,
          border: Border(
            bottom: BorderSide(color: context.colors.dividerColor, width: 1),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              for (int i = 0; i < navigationItems.length; i++)
                _buildNavigationItem(navigationItems[i]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem(NavigationItem item) {
    final hasSubItems = item.subItems != null && item.subItems!.isNotEmpty;
    final isSelected = selectedMainItem == item.title;

    if (hasSubItems) {
      return PopupMenuButton<String>(
        offset: const Offset(0, 8),
        onSelected: (String subItem) async {
          // 관제고객등록은 최소화 가능한 플로팅 창으로 열기
          if (subItem == '관제고객등록') {
            _showCustomerRegistrationWindow(context);
            return;
          }

          // 편집 중인지 확인
          if (!_customerService.canLeave(() {
            // 확인 후 실행할 로직
            setState(() {
              selectedMainItem = item.title;
              selectedSubItem = subItem;
            });
            widget.onNavigate(item.title, subItem);
          })) {
            return;
          }

          // 편집 중이 아니면 바로 실행
          setState(() {
            selectedMainItem = item.title;
            selectedSubItem = subItem;
          });
          await widget.onNavigate(item.title, subItem);
        },
        itemBuilder: (BuildContext context) {
          return item.subItems!.map((String subItem) {
            final isSubSelected =
                selectedMainItem == item.title && selectedSubItem == subItem;
            return PopupMenuItem<String>(
              value: subItem,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      subItem,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: isSubSelected
                            ? FontWeight.w700
                            : FontWeight.normal,
                        color: isSubSelected
                            ? context.colors.selectedColor
                            : context.colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList();
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? context.colors.selectedColor : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: 18,
                color: isSelected
                    ? context.colors.white
                    : context.colors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                item.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? context.colors.white
                      : context.colors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 18,
                color: isSelected
                    ? context.colors.white
                    : context.colors.textSecondary,
              ),
            ],
          ),
        ),
      );
    }

    // 서브메뉴가 없는 경우
    return InkWell(
      onTap: () async {
        // 서브 메뉴가 없는 메뉴 선택 시 편집 상태 확인
        if (!_customerService.canLeave(() {
          // 확인 후 실행할 로직
          setState(() {
            selectedMainItem = item.title;
            selectedSubItem = null;
          });
          widget.onNavigate(item.title, null);
        })) {
          return;
        }

        // 편집 중이 아니면 바로 실행
        setState(() {
          selectedMainItem = item.title;
          selectedSubItem = null;
        });
        await widget.onNavigate(item.title, null);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.colors.selectedColor : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 18,
              color: isSelected
                  ? context.colors.white
                  : context.colors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              item.title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? context.colors.white
                    : context.colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 최소화 가능한 플로팅 창 위젯
// ============================================================

class _FloatingWindow extends StatefulWidget {
  final String title;
  final VoidCallback onClose;
  final Widget child;

  const _FloatingWindow({
    required this.title,
    required this.onClose,
    required this.child,
  });

  @override
  State<_FloatingWindow> createState() => _FloatingWindowState();
}

class _FloatingWindowState extends State<_FloatingWindow>
    with SingleTickerProviderStateMixin {
  bool _isMinimized = false;

  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    // 스케일: 0.88 → 1.0, easeOutBack으로 살짝 튀는 느낌
    _scaleAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    // 페이드: 0 → 1, easeOut
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    // 최초 열릴 때도 애니메이션
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _restore() {
    setState(() => _isMinimized = false);
    _controller.forward(from: 0);
  }

  void _minimize() {
    setState(() => _isMinimized = true);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 창이 열려있을 때만 반투명 배경 표시 (페이드 적용)
        if (!_isMinimized)
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: GestureDetector(
                onTap: () {}, // 배경 터치 차단
                child: Container(color: Colors.black.withOpacity(0.4)),
              ),
            ),
          ),

        // 창이 열려있을 때 전체 창 표시 (스케일 + 페이드 적용)
        if (!_isMinimized)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Material(
                    elevation: 16,
                    borderRadius: BorderRadius.circular(8),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _buildTitleBar(context),
                        Expanded(child: widget.child),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        // 최소화 상태일 때 우측 하단에 작은 탭 표시
        if (_isMinimized)
          Positioned(
            bottom: 0,
            right: 16,
            child: Material(
              elevation: 8,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              color: context.colors.selectedColor,
              child: InkWell(
                onTap: _restore,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 14,
                    right: 6,
                    top: 8,
                    bottom: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.assignment_outlined,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: widget.onClose,
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTitleBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 8, top: 4, bottom: 4),
      color: context.colors.gray10,
      child: Row(
        children: [
          const Icon(Icons.assignment_outlined, size: 16),
          const SizedBox(width: 8),
          Text(
            widget.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            tooltip: '최소화',
            icon: const Icon(Icons.remove, size: 18),
            onPressed: _minimize,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            tooltip: '닫기',
            icon: const Icon(Icons.close, size: 18),
            onPressed: widget.onClose,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
