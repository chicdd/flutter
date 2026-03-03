import 'package:flutter/material.dart';
import '../models/search_panel.dart';
import '../widgets/customer_search_panel.dart';
import '../widgets/navigation_sidebar.dart';
import '../widgets/content_area.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  SearchPanel? selectedCustomer;
  String? selectedMenu;
  String? selectedSubMenu;
  bool _isPanelExpanded = true;
  final GlobalKey<ContentAreaState> _contentAreaKey = GlobalKey();

  void _onCustomerSelected(SearchPanel? customer) {
    setState(() {
      selectedCustomer = customer;
      // 고객을 처음 선택하면 자동으로 "관제고객정보" > "기본고객정보" 선택
      if (customer != null && selectedMenu == null && selectedSubMenu == null) {
        selectedMenu = '관제고객정보';
        selectedSubMenu = '기본고객정보';
      }
    });
  }

  Future<void> _onNavigate(String menu, String? subMenu) async {
    // 편집 중인지 확인
    final contentAreaState = _contentAreaKey.currentState;
    if (contentAreaState != null && contentAreaState.isEditing()) {
      // 확인 모달 표시
      final shouldNavigate = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('경고'),
          content: const Text('변경사항이 저장되지 않습니다.\n그래도 나가시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('아니오'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('예'),
            ),
          ],
        ),
      );

      if (shouldNavigate == true) {
        // 편집 중인 프로세스 종료
        await contentAreaState.closeEditingProcesses();
        // 화면 전환
        if (mounted) {
          setState(() {
            selectedMenu = menu;
            selectedSubMenu = subMenu;
          });
        }
      }
    } else {
      // 편집 중이 아니면 바로 화면 전환
      setState(() {
        selectedMenu = menu;
        selectedSubMenu = subMenu;
      });
    }
  }

  void _onPanelExpandedChanged(bool isExpanded) {
    setState(() {
      _isPanelExpanded = isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 상단: 네비게이션바
          NavigationSidebar(
            onNavigate: _onNavigate,
            initialSelectedMenu: selectedMenu,
            initialSelectedSubMenu: selectedSubMenu,
          ),
          // 아래: 고객검색패널 + 컨텐츠영역
          Expanded(
            child: Stack(
              children: [
                Row(
                  children: [
                    // 왼쪽: 고객 검색 패널
                    CustomerSearchPanel(
                      onCustomerSelected: _onCustomerSelected,
                      onExpandedChanged: _onPanelExpandedChanged,
                      isExpanded: _isPanelExpanded,
                    ),
                    // 오른쪽: 컨텐츠 영역
                    Expanded(
                      child: ContentArea(
                        key: _contentAreaKey,
                        selectedCustomer: selectedCustomer,
                        selectedMenu: selectedMenu,
                        selectedSubMenu: selectedSubMenu,
                      ),
                    ),
                  ],
                ),
                // 패널이 접혀있을 때만 펼치기 버튼 표시
                if (!_isPanelExpanded)
                  Positioned(
                    left: 0,
                    top: 64,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _isPanelExpanded = true;
                        });
                      },
                      child: Container(
                        width: 32,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
