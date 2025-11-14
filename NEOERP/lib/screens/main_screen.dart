import 'package:flutter/material.dart';
import 'package:docking/docking.dart';
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

  late DockingLayout _dockingLayout;
  int _tabIdCounter = 0;

  // 간단한 탭 그룹 관리 (DockingTabs 직접 추적)
  DockingTabs? _focusedTabGroup; // 현재 포커스된 탭 그룹
  final Map<String, DockingTabs> _itemToTabGroupMap = {}; // 탭 이름 -> DockingTabs 매핑

  @override
  void initState() {
    super.initState();
    _dockingLayout = DockingLayout(root: null);
    _dockingLayout.addListener(() {
      setState(() {
        _updateTabGroupMapping();
      });
    });
  }

  @override
  void dispose() {
    _dockingLayout.dispose();
    super.dispose();
  }

  // 레이아웃의 모든 DockingTabs를 찾아서 탭-그룹 매핑 업데이트
  void _updateTabGroupMapping() {
    _itemToTabGroupMap.clear();

    final areas = _dockingLayout.layoutAreas();
    debugPrint('═══════════════════════════════════════');
    debugPrint('🔄 Updating tab-group mapping...');

    int tabGroupCount = 0;
    for (var area in areas) {
      if (area is DockingTabs && area.childrenCount > 0) {
        tabGroupCount++;
        // 이 DockingTabs의 모든 탭을 매핑
        for (int i = 0; i < area.childrenCount; i++) {
          final item = area.childAt(i);
          if (item.name != null) {
            _itemToTabGroupMap[item.name!] = area;
          }
        }

        // 디버그: 이 그룹의 탭 출력
        final tabNames = <String>[];
        for (int i = 0; i < area.childrenCount; i++) {
          if (area.childAt(i).name != null) {
            tabNames.add(area.childAt(i).name!);
          }
        }
        debugPrint('   TabGroup ${area.hashCode}: ${tabNames.join(", ")}');
      }
    }

    debugPrint('   Total tab groups: $tabGroupCount');
    debugPrint('   Focused group: ${_focusedTabGroup?.hashCode ?? "none"}');
    debugPrint('═══════════════════════════════════════\n');
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
                color: Colors.black.withValues(alpha: 0.2),
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
    debugPrint('\n🖱️  USER ACTION: Menu clicked - Opening tab "$title"');

    // 1. 포커스된 그룹에서 이미 존재하는 탭인지 확인
    if (_focusedTabGroup != null) {
      for (int i = 0; i < _focusedTabGroup!.childrenCount; i++) {
        final item = _focusedTabGroup!.childAt(i);
        if (item.name == title) {
          // 이미 있으면 해당 탭으로 포커스
          setState(() {
            _focusedTabGroup!.selectedIndex = i;
            _dockingLayout.rebuild();
          });
          debugPrint('✅ Tab already exists in focused group! Switched to it.');
          return;
        }
      }
    }

    // 2. 새 DockingItem 생성
    final newItem = DockingItem(
      name: title,
      id: 'tab_${_tabIdCounter++}_$title',
      closable: true,
      maximizable: false,
      keepAlive: true,
      widget: _getScreenForTitle(title),
    );

    // 3. 첫 번째 탭 그룹 생성 (root가 null인 경우)
    if (_dockingLayout.root == null) {
      debugPrint('   Creating first tab group...');
      setState(() {
        final newTabs = DockingTabs([newItem], maximizable: false);
        newTabs.selectedIndex = 0;
        _dockingLayout.root = newTabs;
        _focusedTabGroup = newTabs;
      });
      debugPrint('✅ Created first tab group with tab: "$title"');
      return;
    }

    // 4. 포커스된 그룹에 탭 추가
    if (_focusedTabGroup != null) {
      final targetIndex = _focusedTabGroup!.childrenCount;
      debugPrint('   Adding to focused group (${_focusedTabGroup!.hashCode}) at index $targetIndex');

      _dockingLayout.addItemOn(
        newItem: newItem,
        targetArea: _focusedTabGroup!,
        dropIndex: targetIndex,
      );

      // 다음 프레임에서 탭 선택
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 레이아웃이 변경되었으므로 _focusedTabGroup 참조가 유효한지 확인
        final tabGroup = _itemToTabGroupMap[title];
        if (tabGroup != null) {
          setState(() {
            tabGroup.selectedIndex = targetIndex;
            _dockingLayout.rebuild();
          });
        }
      });

      debugPrint('✅ Added tab "$title" to focused group');
    } else {
      // 5. 포커스된 그룹이 없으면 첫 번째 그룹에 추가
      debugPrint('   No focused group, finding first available group...');
      final areas = _dockingLayout.layoutAreas();
      for (var area in areas) {
        if (area is DockingTabs && area.childrenCount > 0) {
          _focusedTabGroup = area;
          final targetIndex = area.childrenCount;
          debugPrint('   Found group (${area.hashCode}), adding tab at index $targetIndex');

          _dockingLayout.addItemOn(
            newItem: newItem,
            targetArea: area,
            dropIndex: targetIndex,
          );

          // 다음 프레임에서 탭 선택
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final tabGroup = _itemToTabGroupMap[title];
            if (tabGroup != null) {
              setState(() {
                tabGroup.selectedIndex = targetIndex;
                _dockingLayout.rebuild();
              });
            }
          });

          debugPrint('✅ Added tab "$title" to group ${area.hashCode}');
          break;
        }
      }
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

  // 디버그 정보 패널 빌드
  Widget _buildDebugPanel() {
    // 모든 탭 그룹 정보 수집
    final allTabGroups = <int, List<String>>{};
    _itemToTabGroupMap.forEach((tabName, tabGroup) {
      final groupHash = tabGroup.hashCode;
      if (!allTabGroups.containsKey(groupHash)) {
        allTabGroups[groupHash] = [];
      }
      allTabGroups[groupHash]!.add(tabName);
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(color: Colors.orange.shade700, width: 2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.bug_report, color: Colors.orange, size: 16),
          const SizedBox(width: 8),
          Text(
            'DEBUG MODE',
            style: TextStyle(
              color: Colors.orange.shade300,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'TabGroups: ${allTabGroups.length}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade900,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Focused: ${_focusedTabGroup?.hashCode ?? "none"}',
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: allTabGroups.entries.map((entry) {
                  final isFocused = entry.key == _focusedTabGroup?.hashCode;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isFocused
                          ? Colors.blue.shade900
                          : Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(4),
                      border: isFocused
                          ? Border.all(color: Colors.blueAccent, width: 1)
                          : null,
                    ),
                    child: Text(
                      'Group${entry.key}: [${entry.value.join(", ")}]',
                      style: TextStyle(
                        color: isFocused ? Colors.lightBlueAccent : Colors.white60,
                        fontSize: 10,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // kDebugMode를 사용하여 디버그 모드인지 확인
    const bool showDebugPanel = true; // 필요시 false로 변경

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Column(
        children: [
          if (showDebugPanel) _buildDebugPanel(),
          _buildMacOSTitleBar(),
          Expanded(
            child: Row(
              children: [
                _buildSidebar(),
                Expanded(
                  child: _dockingLayout.root == null
                      ? _buildWelcomeScreen()
                      : TabbedViewTheme(
                          data: _buildTabTheme(),
                          child: Docking(
                            layout: _dockingLayout,
                            onItemSelection: (DockingItem item) {
                              // 탭 선택 시 해당 탭이 속한 그룹으로 포커스 변경
                              debugPrint('\n🖱️  USER ACTION: Tab clicked');
                              debugPrint('   Tab: ${item.name}');

                              if (item.name != null) {
                                final tabGroup = _itemToTabGroupMap[item.name!];
                                if (tabGroup != null) {
                                  setState(() {
                                    _focusedTabGroup = tabGroup;
                                  });
                                  debugPrint('   ✅ Focused group changed to: ${tabGroup.hashCode}');
                                } else {
                                  debugPrint('   ⚠️  Item not mapped to any group!');
                                }
                              }
                            },
                            onItemClose: (DockingItem item) {
                              // 탭 닫기 시 정보만 출력
                              debugPrint('❌ Tab closed: ${item.name}');
                              // 레이아웃 리스너가 자동으로 _updateTabGroupMapping() 호출
                            },
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
        middleGap: 4, // 탭 간 간격
      ),
      tab: TabThemeData(
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF86868B),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFE5E5EA),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        buttonsOffset: 8,
        normalButtonColor: const Color(0xFF86868B),
        hoverButtonColor: const Color(0xFF1D1D1F),
        selectedStatus: TabStatusThemeData(
          fontColor: const Color(0xFF1D1D1F),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          normalButtonColor: const Color(0xFF86868B),
          hoverButtonColor: const Color(0xFF1D1D1F),
        ),
        highlightedStatus: TabStatusThemeData(
          decoration: BoxDecoration(
            color: const Color(0xFFD1D1D6),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
        ),
      ),
      contentArea: ContentAreaThemeData(
        decoration: const BoxDecoration(
          color: Colors.white,
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
