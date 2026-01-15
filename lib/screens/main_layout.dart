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

  void _onNavigate(String menu, String? subMenu) {
    setState(() {
      selectedMenu = menu;
      selectedSubMenu = subMenu;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 왼쪽: 고객 검색 패널
          CustomerSearchPanel(onCustomerSelected: _onCustomerSelected),
          // 가운데: 네비게이션 사이드바
          NavigationSidebar(
            onNavigate: _onNavigate,
            initialSelectedMenu: selectedMenu,
            initialSelectedSubMenu: selectedSubMenu,
          ),
          // 오른쪽: 컨텐츠 영역
          Expanded(
            child: ContentArea(
              selectedCustomer: selectedCustomer,
              selectedMenu: selectedMenu,
              selectedSubMenu: selectedSubMenu,
            ),
          ),
        ],
      ),
    );
  }
}
