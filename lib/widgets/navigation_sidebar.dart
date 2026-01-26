import 'package:flutter/material.dart';
import '../services/selected_customer_service.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../services/theme_service.dart';

class NavigationItem {
  final String title;
  final IconData icon;
  final List<String>? subItems;

  NavigationItem({required this.title, required this.icon, this.subItems});
}

class NavigationSidebar extends StatefulWidget {
  final Function(String, String?) onNavigate;
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
      subItems: ['기본고객정보', '확장고객정보', '스마트어플인증등록', '문서지원', '설치자재현황', 'IOT장비'],
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: context.colors.gray10,
        border: Border(
          right: BorderSide(color: context.colors.dividerColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: navigationItems.length,
              itemBuilder: (context, index) {
                return _buildNavigationItem(navigationItems[index]);
              },
            ),
          ),
          _buildCacheClearButton(), // 캐시 초기화 버튼 추가
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: context.colors.gray10,
        border: Border(
          bottom: BorderSide(color: context.colors.dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.menu, size: 20, color: context.colors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '메뉴',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem(NavigationItem item) {
    final hasSubItems = item.subItems != null && item.subItems!.isNotEmpty;
    final isExpanded = expandedItem == item.title;
    final isSelected = selectedMainItem == item.title && !hasSubItems;

    return Column(
      children: [
        InkWell(
          onTap: () {
            // 서브 메뉴가 있으면 그냥 펼치기/접기만 수행
            if (hasSubItems) {
              setState(() {
                expandedItem = isExpanded ? null : item.title;
              });
              return;
            }

            // 서브 메뉴가 없는 메뉴 선택 시 편집 상태 확인
            if (!_customerService.canLeave(() {
              // 확인 후 실행할 로직
              setState(() {
                selectedMainItem = item.title;
                selectedSubItem = null;
              });
              widget.onNavigate(item.title, null);
            })) {
              // 편집 중이므로 여기서는 아무것도 하지 않음
              return;
            }

            // 편집 중이 아니면 바로 실행
            setState(() {
              selectedMainItem = item.title;
              selectedSubItem = null;
            });
            widget.onNavigate(item.title, null);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? context.colors.selectedColor : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: isSelected
                      ? context.colors.white
                      : context.colors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? context.colors.white
                          : context.colors.textPrimary,
                    ),
                  ),
                ),
                if (hasSubItems)
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: context.colors.textSecondary,
                  ),
              ],
            ),
          ),
        ),
        if (hasSubItems && isExpanded)
          ...item.subItems!.map((subItem) {
            final isSubSelected =
                selectedMainItem == item.title && selectedSubItem == subItem;
            return InkWell(
              onTap: () {
                // 편집 중인지 확인
                if (!_customerService.canLeave(() {
                  // 확인 후 실행할 로직
                  setState(() {
                    selectedMainItem = item.title;
                    selectedSubItem = subItem;
                  });
                  widget.onNavigate(item.title, subItem);
                })) {
                  // 편집 중이므로 여기서는 아무것도 하지 않음
                  return;
                }

                // 편집 중이 아니면 바로 실행
                setState(() {
                  selectedMainItem = item.title;
                  selectedSubItem = subItem;
                });
                widget.onNavigate(item.title, subItem);
              },
              child: Container(
                margin: const EdgeInsets.only(
                  left: 16,
                  right: 8,
                  top: 2,
                  bottom: 2,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSubSelected ? context.colors.selectedColor : null,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 32),
                    Expanded(
                      child: Text(
                        subItem,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: isSubSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSubSelected
                              ? context.colors.white
                              : context.colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  /// 캐시 초기화 버튼
  Widget _buildCacheClearButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: context.colors.dividerColor, width: 1),
        ),
      ),
      child: InkWell(
        onTap: () {
          // 캐시 초기화
          CodeDataCache.clearCache();
          print('✅ 캐시가 초기화되었습니다.');

          // 사용자에게 피드백 제공
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('캐시가 초기화되었습니다.'),
              duration: const Duration(seconds: 2),
              backgroundColor: context.colors.green,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: context.colors.orange,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.colors.orange, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.refresh, size: 20, color: context.colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '캐시 초기화',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
