import 'package:flutter/material.dart';
import 'package:tabbed_view/tabbed_view.dart';
import 'package:neoerp/screens/login_screen.dart';
import 'package:neoerp/screens/file/login_company_change_screen.dart';
import 'package:neoerp/screens/file/code_setting_screen.dart';
import 'package:neoerp/screens/file/password_change_screen.dart';
import 'package:neoerp/screens/file/user_management_screen.dart';
import 'package:neoerp/screens/file/group_permission_screen.dart';
import 'package:neoerp/screens/customer/customer_ledger_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  int _selectedSubMenuIndex = -1;

  late TabbedViewController _tabbedViewController;

  @override
  void initState() {
    super.initState();
    _tabbedViewController = TabbedViewController([]);
  }

  void _handleTabClose(int index, TabData tabData) {
    setState(() {
      final newTabs = List<TabData>.from(_tabbedViewController.tabs);
      newTabs.removeAt(index);
      _tabbedViewController = TabbedViewController(newTabs);
      if (newTabs.isNotEmpty) {
        // 닫은 탭 이전 탭 선택
        _tabbedViewController.selectedIndex = index > 0 ? index - 1 : 0;
      }
    });
  }

  List<TabbedViewMenuItem> _buildTabMenu(TabData tabData, int index) {
    return [
      TabbedViewMenuItem(
        text: '다른 탭 삭제',
        onSelection: () => _closeOtherTabs(index),
      ),
      TabbedViewMenuItem(
        text: '오른쪽 탭 삭제',
        onSelection: () => _closeTabsToRight(index),
      ),
      TabbedViewMenuItem(
        text: '모두 닫기',
        onSelection: () => _closeAllTabs(),
      ),
    ];
  }

  void _closeOtherTabs(int keepIndex) {
    setState(() {
      final currentTab = _tabbedViewController.tabs[keepIndex];
      _tabbedViewController = TabbedViewController([currentTab]);
      _tabbedViewController.selectedIndex = 0;
    });
  }

  void _closeTabsToRight(int fromIndex) {
    setState(() {
      final newTabs = _tabbedViewController.tabs.sublist(0, fromIndex + 1);
      _tabbedViewController = TabbedViewController(newTabs);
      _tabbedViewController.selectedIndex = fromIndex;
    });
  }

  void _closeAllTabs() {
    setState(() {
      _tabbedViewController = TabbedViewController([]);
    });
  }

  @override
  void dispose() {
    _tabbedViewController.dispose();
    super.dispose();
  }

  final List<MenuItem> _menuItems = [
    MenuItem(
      title: '파일',
      icon: Icons.folder_outlined,
      children: [
        SubMenuItem(
          title: '로그인회사변경',
          icon: Icons.business_outlined,
          subMenus: [],
        ),
        SubMenuItem(title: '코드설정', icon: Icons.code, subMenus: []),
        SubMenuItem(
          title: '문서코드설정',
          icon: Icons.description_outlined,
          subMenus: [],
        ),
        SubMenuItem(title: '암호변경', icon: Icons.lock_outline, subMenus: []),
        SubMenuItem(title: '사용자관리', icon: Icons.person_outline, subMenus: []),
        SubMenuItem(title: '그룹권한설정', icon: Icons.group_outlined, subMenus: []),
        SubMenuItem(
          title: '기관코드설정',
          icon: Icons.apartment_outlined,
          subMenus: [],
        ),
        SubMenuItem(title: '프린터설정', icon: Icons.print_outlined, subMenus: []),
        SubMenuItem(title: '업무기록', icon: Icons.history, subMenus: []),
        SubMenuItem(title: '종료', icon: Icons.exit_to_app, subMenus: []),
      ],
    ),
    MenuItem(
      title: '계약관리',
      icon: Icons.assignment_outlined,
      children: [
        SubMenuItem(
          title: '견적관리',
          icon: Icons.receipt_long_outlined,
          subMenus: [],
        ),
        SubMenuItem(
          title: '신규계약등록',
          icon: Icons.note_add_outlined,
          subMenus: [],
        ),
        SubMenuItem(
          title: '계약관리보고서',
          icon: Icons.assessment_outlined,
          subMenus: ['월별 계약현황', '개인별 계약현황', '권역별 계약현황', '재계약 현황'],
        ),
      ],
    ),
    MenuItem(
      title: '고객관리',
      icon: Icons.people_outline,
      children: [
        SubMenuItem(
          title: '고객원장관리',
          icon: Icons.account_box_outlined,
          subMenus: [],
        ),
        SubMenuItem(
          title: '고객원장등록',
          icon: Icons.person_add_outlined,
          subMenus: [],
        ),
        SubMenuItem(title: '신규계약승인', icon: Icons.approval, subMenus: []),
        SubMenuItem(title: '계약변경/승인', icon: Icons.edit_note, subMenus: []),
        SubMenuItem(title: '고객검색', icon: Icons.search, subMenus: []),
        SubMenuItem(title: '관제고객조회', icon: Icons.monitor, subMenus: []),
        SubMenuItem(
          title: '고객관리 보고서',
          icon: Icons.summarize_outlined,
          subMenus: [
            '고객관리리스트',
            '조건별고객현황',
            '권역별 해지현황',
            '직권정지대상현황',
            '중지/정지 및 미 재개시현황',
            '만기도래 고객현황',
            '계산서발행 고객현황',
            '계산서발행 내역현황',
            '고객정보변경이력',
            '기간별상담이력',
            '업무처리이력',
            '보험 / 부가서비스 조회',
            '월정료 품목별 조회',
            '월정료 변경내역',
            '보증금현황',
          ],
        ),
      ],
    ),
    MenuItem(
      title: 'CMS관리',
      icon: Icons.payment_outlined,
      children: [
        SubMenuItem(
          title: 'EB13파일생성',
          icon: Icons.create_new_folder_outlined,
          subMenus: [],
        ),
        SubMenuItem(
          title: 'EB14파일반영',
          icon: Icons.file_upload_outlined,
          subMenus: [],
        ),
        SubMenuItem(
          title: 'EB21 파일생성',
          icon: Icons.create_new_folder_outlined,
          subMenus: [],
        ),
        SubMenuItem(
          title: 'CMS입금관리(EB22)',
          icon: Icons.account_balance_outlined,
          subMenus: [],
        ),
        SubMenuItem(
          title: 'EC21 파일생성',
          icon: Icons.create_new_folder_outlined,
          subMenus: [],
        ),
        SubMenuItem(
          title: 'CMS입금관리EC22',
          icon: Icons.account_balance_wallet_outlined,
          subMenus: [],
        ),
        SubMenuItem(
          title: 'EB11파일반영',
          icon: Icons.file_upload_outlined,
          subMenus: [],
        ),
        SubMenuItem(title: 'EB13엑셀변환', icon: Icons.transform, subMenus: []),
        SubMenuItem(
          title: 'EB14영',
          icon: Icons.document_scanner_outlined,
          subMenus: [],
        ),
        SubMenuItem(
          title: '현금영수증발행내역',
          icon: Icons.receipt_outlined,
          subMenus: [],
        ),
        SubMenuItem(
          title: '전자계산서 발행',
          icon: Icons.description_outlined,
          subMenus: [],
        ),
        SubMenuItem(
          title: '전자계산서 조회',
          icon: Icons.find_in_page_outlined,
          subMenus: [],
        ),
        SubMenuItem(
          title: '전자계산서에러내역',
          icon: Icons.error_outline,
          subMenus: [],
        ),
        SubMenuItem(title: '전자계산서처리내역', icon: Icons.checklist, subMenus: []),
        SubMenuItem(title: '전자계산서 웹조회', icon: Icons.web, subMenus: []),
      ],
    ),
    MenuItem(
      title: '인사관리',
      icon: Icons.badge_outlined,
      children: [
        SubMenuItem(
          title: '인사정보관리',
          icon: Icons.manage_accounts_outlined,
          subMenus: [],
        ),
        SubMenuItem(
          title: '증명서발급',
          icon: Icons.card_membership_outlined,
          subMenus: [],
        ),
        SubMenuItem(
          title: '보고서조회',
          icon: Icons.analytics_outlined,
          subMenus: [],
        ),
        SubMenuItem(title: '인사코드 관리', icon: Icons.qr_code, subMenus: []),
      ],
    ),
    MenuItem(
      title: '총무관리',
      icon: Icons.admin_panel_settings_outlined,
      children: [
        SubMenuItem(
          title: '차량관리',
          icon: Icons.directions_car_outlined,
          subMenus: [],
        ),
        SubMenuItem(
          title: '주유카드관리',
          icon: Icons.local_gas_station_outlined,
          subMenus: [],
        ),
        SubMenuItem(title: '무전기관리', icon: Icons.radio, subMenus: []),
      ],
    ),
    MenuItem(
      title: '경영관리',
      icon: Icons.business_center_outlined,
      children: [
        SubMenuItem(title: '계약증감현황', icon: Icons.trending_up, subMenus: []),
        SubMenuItem(
          title: '매출분포현황',
          icon: Icons.pie_chart_outline,
          subMenus: [],
        ),
        SubMenuItem(title: '수금달성현황', icon: Icons.attach_money, subMenus: []),
        SubMenuItem(title: '고객현황 리스트', icon: Icons.list_alt, subMenus: []),
        SubMenuItem(
          title: '납입방법 별 월별매출현황',
          icon: Icons.calendar_view_month_outlined,
          subMenus: [],
        ),
        SubMenuItem(
          title: '납입분류 별 월별매출현황',
          icon: Icons.category_outlined,
          subMenus: [],
        ),
        SubMenuItem(
          title: '기간별 수금방법별 매출현황',
          icon: Icons.date_range_outlined,
          subMenus: [],
        ),
        SubMenuItem(
          title: '기간별 수금 할인/면제 매출현황',
          icon: Icons.discount_outlined,
          subMenus: [],
        ),
      ],
    ),
    MenuItem(
      title: '업무관리',
      icon: Icons.work_outline,
      children: [
        SubMenuItem(title: 'A/S접수', icon: Icons.support_agent, subMenus: []),
        SubMenuItem(title: 'A/S접수현황', icon: Icons.list_alt, subMenus: []),
        SubMenuItem(title: 'A/S처리내역조회', icon: Icons.search, subMenus: []),
        SubMenuItem(
          title: 'A/S처리보고서',
          icon: Icons.assignment_turned_in_outlined,
          subMenus: [],
        ),
        SubMenuItem(title: '메시지보내기', icon: Icons.send_outlined, subMenus: []),
        SubMenuItem(title: '메시지읽기', icon: Icons.mail_outline, subMenus: []),
        SubMenuItem(
          title: '고객방문이력관리',
          icon: Icons.person_pin_circle_outlined,
          subMenus: [],
        ),
        SubMenuItem(
          title: '고객방문이력보고서',
          icon: Icons.location_history,
          subMenus: [],
        ),
        SubMenuItem(title: '문자발송', icon: Icons.message_outlined, subMenus: []),
        SubMenuItem(title: '문자설정관리', icon: Icons.settings_cell, subMenus: []),
        SubMenuItem(title: '문자발송이력', icon: Icons.history, subMenus: []),
        SubMenuItem(
          title: '스마트폰조회관리',
          icon: Icons.smartphone_outlined,
          subMenus: [],
        ),
        SubMenuItem(title: '일정관리', icon: Icons.event_outlined, subMenus: []),
      ],
    ),
    MenuItem(
      title: '도움말',
      icon: Icons.help_outline,
      children: [
        SubMenuItem(title: '도움말', icon: Icons.help_outline, subMenus: []),
        SubMenuItem(
          title: '업데이트정보',
          icon: Icons.system_update_outlined,
          subMenus: [],
        ),
        SubMenuItem(
          title: '공지사항',
          icon: Icons.announcement_outlined,
          subMenus: [],
        ),
        SubMenuItem(title: '정보', icon: Icons.info_outline, subMenus: []),
        SubMenuItem(title: '원격지원요청', icon: Icons.support, subMenus: []),
      ],
    ),
  ];

  void _onMenuItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
      _selectedSubMenuIndex = -1;
    });
  }

  void _onSubMenuItemSelected(int index) {
    setState(() {
      _selectedSubMenuIndex = index;
    });

    final menuTitle = _menuItems[_selectedIndex].children[index].title;

    // 파일 메뉴(index 0)는 별도 창으로, 나머지는 탭으로 열기
    if (_selectedIndex == 0) {
      _openDialog(menuTitle);
    } else {
      _openTab(menuTitle);
    }
  }

  void _openDialog(String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildDialogTitleBar(title, context),
              Expanded(child: _getScreenForTitle(title)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogTitleBar(String title, BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFFED6A5E),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
        ],
      ),
    );
  }

  void _openTab(String title) {
    // 이미 열려있는 탭인지 확인
    int existingIndex = -1;
    final currentTabs = _tabbedViewController.tabs;
    for (int i = 0; i < currentTabs.length; i++) {
      if (currentTabs[i].text == title) {
        existingIndex = i;
        break;
      }
    }

    if (existingIndex >= 0) {
      // 이미 열려있으면 해당 탭 선택
      setState(() {
        _tabbedViewController.selectedIndex = existingIndex;
      });
    } else {
      // 새 탭 생성
      final newTab = TabData(
        text: title,
        closable: true,
        keepAlive: true,
        content: _getScreenForTitle(title),
      );

      setState(() {
        // 현재 선택된 탭 바로 다음에 추가
        int insertIndex = _tabbedViewController.selectedIndex != null
            ? _tabbedViewController.selectedIndex! + 1
            : currentTabs.length;

        // 새 리스트 생성
        final newTabs = List<TabData>.from(currentTabs);
        newTabs.insert(insertIndex, newTab);

        // 새 컨트롤러 생성
        _tabbedViewController = TabbedViewController(newTabs);
        _tabbedViewController.selectedIndex = insertIndex;
      });
    }
  }

  Widget _getScreenForTitle(String title) {
    switch (title) {
      case '로그인회사변경':
        return const LoginCompanyChangeScreen();
      case '코드설정':
        return const CodeSettingScreen();
      case '암호변경':
        return const PasswordChangeScreen();
      case '사용자관리':
        return const UserManagementScreen();
      case '그룹권한설정':
        return const GroupPermissionScreen();
      case '고객원장관리':
        return const CustomerLedgerScreen();
      default:
        return _buildPlaceholder(title);
    }
  }

  Widget _buildPlaceholder(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '준비 중입니다',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Column(
        children: [
          _buildMacOSTitleBar(),
          Expanded(
            child: Row(
              children: [
                _buildSidebar(),
                Expanded(
                  child: _tabbedViewController.tabs.isEmpty
                      ? _buildWelcomeScreen()
                      : TabbedViewTheme(
                          data: _buildTabTheme(),
                          child: TabbedView(controller: _tabbedViewController),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacOSTitleBar() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFFED6A5E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFFF4BF4F),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFF61C554),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          const Icon(
            Icons.business_outlined,
            size: 20,
            color: Color(0xFF007AFF),
          ),
          const SizedBox(width: 8),
          const Text(
            'NEO ERP',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_none, size: 20),
            onPressed: () {},
            color: const Color(0xFF1D1D1F),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, size: 20),
            onPressed: () {},
            color: const Color(0xFF1D1D1F),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined, size: 20),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            color: const Color(0xFF1D1D1F),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border(
          right: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _menuItems.length,
        itemBuilder: (context, index) {
          final item = _menuItems[index];
          final isSelected = _selectedIndex == index;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => _onMenuItemSelected(index),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE5E5EA)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        size: 18,
                        color: isSelected
                            ? const Color(0xFF007AFF)
                            : const Color(0xFF86868B),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? const Color(0xFF1D1D1F)
                              : const Color(0xFF86868B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isSelected && item.children.isNotEmpty)
                ...item.children.asMap().entries.map((entry) {
                  final subIndex = entry.key;
                  final subItem = entry.value;
                  final isSubSelected = _selectedSubMenuIndex == subIndex;

                  return InkWell(
                    onTap: () => _onSubMenuItemSelected(subIndex),
                    child: Container(
                      margin: const EdgeInsets.only(
                        left: 32,
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
                            ? const Color(0xFFD1D1D6)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            subItem.icon,
                            size: 16,
                            color: isSubSelected
                                ? const Color(0xFF007AFF)
                                : const Color(0xFF86868B),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              subItem.title,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSubSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSubSelected
                                    ? const Color(0xFF1D1D1F)
                                    : const Color(0xFF86868B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  TabbedViewThemeData _buildTabTheme() {
    return TabbedViewThemeData(
      tabsArea: TabsAreaThemeData(
        color: const Color(0xFFF5F5F7),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      tab: TabThemeData(
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Color(0xFF86868B),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFE5E5EA),
          border: Border(
            right: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        buttonsOffset: 8,
        normalButtonColor: const Color(0xFF86868B),
        hoverButtonColor: const Color(0xFF1D1D1F),
        selectedStatus: TabStatusThemeData(
          fontColor: const Color(0xFF1D1D1F),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              right: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          normalButtonColor: const Color(0xFF86868B),
          hoverButtonColor: const Color(0xFF1D1D1F),
        ),
        highlightedStatus: TabStatusThemeData(
          decoration: BoxDecoration(
            color: const Color(0xFFD1D1D6),
            border: Border(
              right: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined, size: 100, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          const Text(
            'NEO ERP 영업관리 시스템',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '좌측 메뉴에서 기능을 선택하세요',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class MenuItem {
  final String title;
  final IconData icon;
  final List<SubMenuItem> children;

  MenuItem({required this.title, required this.icon, required this.children});
}

class SubMenuItem {
  final String title;
  final IconData icon;
  final List<String> subMenus;

  SubMenuItem({
    required this.title,
    required this.icon,
    required this.subMenus,
  });
}
