import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:securityindex/screens/maintenance_inspection_history.dart';
import 'package:securityindex/screens/materialstatus.dart';
import '../screens/as_log.dart';
import '../screens/control_signal_activation.dart';
import '../screens/recentsignallist.dart';
import '../screens/sales_info.dart';
import '../screens/smartphone_app_auth_registration.dart';
import '../screens/document_support.dart';
import '../screens/userzoneInfo.dart';
import '../screens/search_log_inquiry.dart';
import '../screens/customer_info_history.dart';
import '../screens/map_diagram.dart';
import '../screens/blueprint_screen.dart';
import '../theme.dart';
import '../models/search_panel.dart';
import '../screens/basic_customer_info.dart';
import '../screens/extended_customer_info.dart';
import 'custom_top_bar.dart';
import '../config/topbar_config.dart';

class ContentArea extends StatefulWidget {
  final SearchPanel? selectedCustomer;
  final String? selectedMenu;
  final String? selectedSubMenu;

  const ContentArea({
    Key? key,
    this.selectedCustomer,
    this.selectedMenu,
    this.selectedSubMenu,
  }) : super(key: key);

  @override
  State<ContentArea> createState() => _ContentAreaState();
}

class _ContentAreaState extends State<ContentArea> {
  String _pageSearchQuery = '';
  final GlobalKey<BasicCustomerInfoState> _basicCustomerInfoKey = GlobalKey();
  final GlobalKey<ExtendedCustomerInfoState> _extendedCustomerInfoKey =
      GlobalKey();
  final GlobalKey<SmartphoneAppAuthRegistrationState> _smartphoneAuthKey =
      GlobalKey();
  final GlobalKey<DocumentSupportState> _documentSupportKey = GlobalKey();
  final GlobalKey<MaterialStatusState> _materialstatusKey = GlobalKey();
  final GlobalKey<UserZoneInfoState> _userZoneInfoKey = GlobalKey();
  final GlobalKey<RecentSignalListState> _recentSignalListKey = GlobalKey();
  final GlobalKey<SearchLogInquiryState> _searchLogInquiryKey = GlobalKey();
  final GlobalKey<CustomerInfoHistoryState> _customerInfoHistoryKey =
      GlobalKey();
  final GlobalKey<MapDiagramState> _mapDiagramKey = GlobalKey();
  final GlobalKey<BlueprintState> _blueprintKey = GlobalKey();
  final GlobalKey<ControlSignalActivationState> _controlSignalActivationtKey =
      GlobalKey();
  final GlobalKey<MaintenanceInspectionHistoryState>
  _maintenanceInspectionHistoryKey = GlobalKey();
  final GlobalKey<AsLogState> _asLogKey = GlobalKey();
  final GlobalKey<SalesInfoScreenState> _salesKey = GlobalKey();
  final GlobalKey<CustomTopBarState> _topBarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // 하드웨어 키보드 리스너 추가
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    // 하드웨어 키보드 리스너 제거
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isControlPressed = HardwareKeyboard.instance.isControlPressed;

      // Ctrl+F: 검색바 열고 검색 필드 초기화 후 포커스
      if (isControlPressed && event.logicalKey == LogicalKeyboardKey.keyF) {
        _topBarKey.currentState?.resetAndFocusSearch();
        return true; // 이벤트 처리됨
      }

      // ESC: 검색 초기화 및 검색바 닫기
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _topBarKey.currentState?.closeSearch();
        return true; // 이벤트 처리됨
      }
    }
    return false; // 이벤트 처리 안 됨
  }

  /// 현재 화면의 검색 쿼리 업데이트
  void _updateSearchForCurrentScreen(String query) {
    if (widget.selectedSubMenu == '기본고객정보') {
      _basicCustomerInfoKey.currentState?.updateSearchQuery(query);
    } else if (widget.selectedSubMenu == '확장고객정보') {
      _extendedCustomerInfoKey.currentState?.updateSearchQuery(query);
    } else if (widget.selectedSubMenu == '스마트어플인증등록') {
      _smartphoneAuthKey.currentState?.updateSearchQuery(query);
    } else if (widget.selectedSubMenu == '문서지원') {
      _documentSupportKey.currentState?.updateSearchQuery(query);
    } else if (widget.selectedSubMenu == '설치자재현황') {
      _materialstatusKey.currentState?.updateSearchQuery(query);
    } else if (widget.selectedSubMenu == '검색로그 내역조회') {
      _searchLogInquiryKey.currentState?.updateSearchQuery(query);
    } else if (widget.selectedSubMenu == '고객정보 변동이력') {
      _customerInfoHistoryKey.currentState?.updateSearchQuery(query);
    } else if (widget.selectedMenu == '사용자 / 존정보') {
      _userZoneInfoKey.currentState?.updateSearchQuery(query);
    } else if (widget.selectedMenu == '최근신호이력') {
      _recentSignalListKey.currentState?.updateSearchQuery(query);
    } else if (widget.selectedSubMenu == '관제신호 개통처리') {
      _controlSignalActivationtKey.currentState?.updateSearchQuery(query);
    } else if (widget.selectedSubMenu == '보수점검 완료이력') {
      _maintenanceInspectionHistoryKey.currentState?.updateSearchQuery(query);
    } else if (widget.selectedMenu == 'AS 접수') {
      _asLogKey.currentState?.updateSearchQuery(query);
    } else if (widget.selectedSubMenu == '영업정보') {
      _salesKey.currentState?.updateSearchQuery(query);
    } else if (widget.selectedSubMenu == '최근 수금 이력') {
      _controlSignalActivationtKey.currentState?.updateSearchQuery(query);
    } else if (widget.selectedSubMenu == '최근 방문 및 A/S 이력') {
      _maintenanceInspectionHistoryKey.currentState?.updateSearchQuery(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 화면별로 다른 버튼 구성을 사용하기 위한 로직
    List<TopBarButton> buttons = _getButtonsForScreen(context);
    String title = _getTitleForScreen();

    return Container(
      color: AppTheme.backgroundColor,
      child: Column(
        children: [
          CustomTopBar(
            key: _topBarKey,
            title: title,
            buttons: buttons,
            onPageSearch: (query) {
              setState(() {
                _pageSearchQuery = query;
              });
              // 현재 화면에 따라 해당 화면의 검색 쿼리 업데이트
              _updateSearchForCurrentScreen(query);
            },
          ),
          Expanded(child: _buildContent(context)),
        ],
      ),
    );
  }

  /// 현재 화면에 맞는 타이틀 반환
  String _getTitleForScreen() {
    if (widget.selectedMenu != null) {
      return widget.selectedSubMenu ?? widget.selectedMenu!;
    }
    return '보안관제 시스템';
  }

  /// 현재 화면에 맞는 버튼 구성 반환
  List<TopBarButton> _getButtonsForScreen(BuildContext context) {
    // 기본고객정보 화면
    if (widget.selectedSubMenu == '기본고객정보') {
      return TopBarConfig.basicCustomerInfoButtons(context);
    }
    // 확장고객정보 화면
    else if (widget.selectedSubMenu == '확장고객정보') {
      return TopBarConfig.extendedCustomerInfoButtons(context);
    }
    // 스마트어플인증등록 화면
    else if (widget.selectedSubMenu == '스마트어플인증등록') {
      return TopBarConfig.smartPhoneRegisterButtons(context);
    }
    // 문서지원 화면
    else if (widget.selectedSubMenu == '문서지원') {
      return TopBarConfig.defaultButtons(context);
    } else if (widget.selectedSubMenu == '설치자재현황') {
      return TopBarConfig.defaultButtons(context);
    } else if (widget.selectedMenu == '사용자 / 존정보') {
      return TopBarConfig.defaultButtons(context);
    } else if (widget.selectedMenu == '최근신호이력') {
      return TopBarConfig.defaultButtons(context);
    } else if (widget.selectedSubMenu == '검색로그 내역조회') {
      return TopBarConfig.defaultButtons(context);
    } else if (widget.selectedSubMenu == '고객정보 변동이력') {
      return TopBarConfig.defaultButtons(context);
    } else if (widget.selectedMenu == '약도') {
      return TopBarConfig.mapDiagramButtons(context);
    } else if (widget.selectedMenu == '도면') {
      return TopBarConfig.mapDiagramButtons(context);
    } else if (widget.selectedSubMenu == '관제신호 개통처리') {
      return TopBarConfig.defaultButtons(context);
    } else if (widget.selectedSubMenu == '보수점검 완료이력') {
      return TopBarConfig.defaultButtons(context);
    } else if (widget.selectedMenu == 'AS 접수') {
      return TopBarConfig.defaultButtons(context);
    } else if (widget.selectedSubMenu == '영업정보') {
      return TopBarConfig.defaultButtons(context);
    } else if (widget.selectedSubMenu == '최근 수금 이력') {
      return TopBarConfig.defaultButtons(context);
    } else if (widget.selectedSubMenu == '최근 방문 및 A/S 이력') {
      return TopBarConfig.defaultButtons(context);
    }
    // 기타 화면
    else {
      return TopBarConfig.defaultButtons(context);
    }
  }

  Widget _buildContent(BuildContext context) {
    if (widget.selectedCustomer == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppTheme.textTertiary),
            const SizedBox(height: 16),
            Text(
              '고객을 선택해주세요',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    // 고객이 선택되었고 메뉴가 선택되지 않았거나, 관제고객정보 메뉴일 때
    if (widget.selectedMenu == null || widget.selectedMenu == '관제고객정보') {
      return _buildCustomerInfoContent(context);
    }

    // 사용자 / 존정보 메뉴
    if (widget.selectedMenu == '사용자 / 존정보') {
      return UserZoneInfoScreen(
        key: _userZoneInfoKey,
        searchpanel: widget.selectedCustomer!,
      );
    }

    // 최근신호이력 메뉴
    if (widget.selectedMenu == '최근신호이력') {
      return RecentSignalList(
        key: _recentSignalListKey,
        searchpanel: widget.selectedCustomer!,
      );
    }

    // 관제 / 고객로그 메뉴
    if (widget.selectedMenu == '관제 / 고객로그') {
      return _buildCustomerLogContent(context);
    }

    // 약도 메뉴
    if (widget.selectedMenu == '약도') {
      return MapDiagram(
        key: _mapDiagramKey,
        searchpanel: widget.selectedCustomer!,
      );
    }

    // 도면 메뉴
    if (widget.selectedMenu == '도면') {
      return Blueprint(
        key: _blueprintKey,
        searchpanel: widget.selectedCustomer!,
      );
    }

    // 관제 / 고객로그 메뉴
    if (widget.selectedMenu == '관제개통 / 루프') {
      return _buildCustomerOpenContent(context);
    }

    // A/S 접수 메뉴
    if (widget.selectedMenu == 'AS 접수') {
      return AsLogScreen(key: _asLogKey, searchpanel: widget.selectedCustomer!);
    }

    // 영업정보 메뉴
    if (widget.selectedMenu == '영업정보') {
      return _buildERPContent(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildMenuContent(context)],
      ),
    );
  }

  Widget _buildCustomerInfoContent(BuildContext context) {
    // 서브메뉴가 없거나 기본고객정보인 경우
    if (widget.selectedSubMenu == null || widget.selectedSubMenu == '기본고객정보') {
      return BasicCustomerInfo(
        key: _basicCustomerInfoKey,
        searchpanel: widget.selectedCustomer!,
      );
    }

    // 확장고객정보
    if (widget.selectedSubMenu == '확장고객정보') {
      return ExtendedCustomerInfo(
        key: _extendedCustomerInfoKey,
        searchpanel: widget.selectedCustomer!,
      );
    }

    // 스마트어플인증등록
    if (widget.selectedSubMenu == '스마트어플인증등록') {
      return SmartphoneAppAuthRegistration(
        key: _smartphoneAuthKey,
        searchpanel: widget.selectedCustomer!,
      );
    }

    // 문서지원
    if (widget.selectedSubMenu == '문서지원') {
      return DocumentSupport(
        key: _documentSupportKey,
        searchpanel: widget.selectedCustomer!,
      );
    }

    // 설치자재현황
    if (widget.selectedSubMenu == '설치자재현황') {
      return MaterialStatus(
        key: _materialstatusKey,
        searchpanel: widget.selectedCustomer!,
      );
    }

    // 다른 서브메뉴들은 일단 플레이스홀더로 표시
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.construction_outlined,
                size: 64,
                color: AppTheme.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                widget.selectedSubMenu ?? '준비 중',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '해당 화면은 준비 중입니다.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerLogContent(BuildContext context) {
    // 검색로그 내역조회
    if (widget.selectedSubMenu == '검색로그 내역조회') {
      return SearchLogInquiry(
        key: _searchLogInquiryKey,
        searchpanel: widget.selectedCustomer!,
      );
    }

    // 고객정보 변동이력
    if (widget.selectedSubMenu == '고객정보 변동이력') {
      return CustomerInfoHistory(
        key: _customerInfoHistoryKey,
        searchpanel: widget.selectedCustomer!,
      );
    }

    return SingleChildScrollView();
  }

  Widget _buildCustomerOpenContent(BuildContext context) {
    // 관제신호 개통처리
    if (widget.selectedSubMenu == '관제신호 개통처리') {
      return ControlSignalActivation(
        key: _controlSignalActivationtKey,
        searchpanel: widget.selectedCustomer!,
      );
    }

    // 보수점검 완료이력
    if (widget.selectedSubMenu == '보수점검 완료이력') {
      return MaintenanceInspectionHistory(
        key: _maintenanceInspectionHistoryKey,
        searchpanel: widget.selectedCustomer!,
      );
    }

    return SingleChildScrollView();
  }

  Widget _buildERPContent(BuildContext context) {
    // 검색로그 내역조회
    if (widget.selectedSubMenu == '최근 수금 이력') {
      return SearchLogInquiry(
        key: _searchLogInquiryKey,
        searchpanel: widget.selectedCustomer!,
      );
    }

    // 고객정보 변동이력
    if (widget.selectedSubMenu == '최근 방문 및 A/S 이력') {
      return CustomerInfoHistory(
        key: _customerInfoHistoryKey,
        searchpanel: widget.selectedCustomer!,
      );
    }

    return SingleChildScrollView();
  }

  Widget _buildMenuContent(BuildContext context) {
    if (widget.selectedMenu == null) {
      return const SizedBox.shrink();
    }
    print(widget.selectedCustomer);
    print(widget.selectedMenu);
    print(widget.selectedSubMenu);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 20,
                color: AppTheme.selectedColor,
              ),
              const SizedBox(width: 8),
              Text(
                widget.selectedSubMenu ?? widget.selectedMenu!,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${widget.selectedSubMenu ?? widget.selectedMenu} 내용이 여기에 표시됩니다.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
