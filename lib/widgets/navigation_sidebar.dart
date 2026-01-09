import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';

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
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: AppTheme.sidebarBackground,
        border: Border(
          right: BorderSide(color: AppTheme.dividerColor, width: 1),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.sidebarBackground,
        border: Border(
          bottom: BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.menu, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text(
            '메뉴',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
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
            setState(() {
              if (hasSubItems) {
                expandedItem = isExpanded ? null : item.title;
              } else {
                selectedMainItem = item.title;
                selectedSubItem = null;
                widget.onNavigate(item.title, null);
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.selectedColor.withOpacity(0.1)
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: isSelected
                      ? AppTheme.selectedColor
                      : AppTheme.textSecondary,
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
                          ? AppTheme.selectedColor
                          : AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (hasSubItems)
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: AppTheme.textSecondary,
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
                  color: isSubSelected
                      ? AppTheme.selectedColor.withOpacity(0.1)
                      : null,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 32),
                    Expanded(
                      child: Text(
                        subItem,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSubSelected
                              ? AppTheme.selectedColor
                              : AppTheme.textPrimary,
                          fontWeight: isSubSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
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
        border: Border(top: BorderSide(color: AppTheme.dividerColor, width: 1)),
      ),
      child: InkWell(
        onTap: () {
          // 캐시 초기화
          CodeDataCache.clearCache();
          print('✅ 캐시가 초기화되었습니다.');

          // 사용자에게 피드백 제공
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('캐시가 초기화되었습니다.'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.refresh, size: 20, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '캐시 초기화',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.orange,
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
