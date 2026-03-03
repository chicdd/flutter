import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:securityindex/screens/customerregistration.dart';
import 'package:securityindex/screens/maintenance_inspection_history.dart';
import 'package:securityindex/screens/materialstatus.dart';
import 'package:securityindex/screens/payment_history_table.dart';
import 'package:securityindex/screens/settings.dart';
import 'package:securityindex/screens/visit_as_history_table.dart';
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
import '../services/selected_customer_service.dart';

class ContentArea extends StatefulWidget {
  final SearchPanel? selectedCustomer;
  final String? selectedMenu;
  final String? selectedSubMenu;

  const ContentArea({
    super.key,
    this.selectedCustomer,
    this.selectedMenu,
    this.selectedSubMenu,
  });

  @override
  State<ContentArea> createState() => ContentAreaState();
}

class ContentAreaState extends State<ContentArea> {
  final GlobalKey<CustomerRegistrationState> _customerRegistrationInfoKey =
      GlobalKey();
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
  final GlobalKey<PaymentHistoryTableState> _pamenthistoryKey = GlobalKey();
  final GlobalKey<VisitAsHistoryTableState> _visitashistoryKey = GlobalKey();
  final GlobalKey<CustomTopBarState> _topBarKey = GlobalKey();

  final _customerService = SelectedCustomerService();

  @override
  void initState() {
    super.initState();
    // 하드웨어 키보드 리스너 추가
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    // 고객 서비스 변경 리스너 추가
    _customerService.addListener(_onCustomerServiceChanged);
  }

  @override
  void dispose() {
    // 하드웨어 키보드 리스너 제거
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    // 고객 서비스 리스너 제거
    _customerService.removeListener(_onCustomerServiceChanged);
    super.dispose();
  }

  /// 고객 서비스 변경 시 호출 (에러 메시지 업데이트)
  void _onCustomerServiceChanged() {
    if (mounted) {
      setState(() {
        // errorMessage 등 상태 업데이트를 위해 build 재호출
      });
    }
  }

  /// 현재 약도 또는 도면 편집 중인지 확인
  bool isEditing() {
    final mapDiagramState = _mapDiagramKey.currentState;
    final blueprintState = _blueprintKey.currentState;

    return (mapDiagramState?.isEditMode ?? false) ||
        (blueprintState?.isEditMode ?? false);
  }

  /// 편집 중인 그림판 프로세스 강제 종료
  Future<void> closeEditingProcesses() async {
    await _mapDiagramKey.currentState?.closeEditingProcess();
    await _blueprintKey.currentState?.closeEditingProcess();
  }

  @override
  void didUpdateWidget(ContentArea oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 영업정보 화면으로 전환될 때 에러 메시지 확인을 위해 다시 빌드
    if (widget.selectedSubMenu == '영업정보' &&
        oldWidget.selectedSubMenu != widget.selectedSubMenu) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {});
        }
      });
    }

    // 화면이 변경된 경우 이전 화면의 편집 모드 강제 종료
    // if (oldWidget.selectedSubMenu != widget.selectedSubMenu) {
    //   if (oldWidget.selectedSubMenu == '기본고객정보') {
    //     _basicCustomerInfoKey.currentState?.forceExitEditMode();
    //   } else if (oldWidget.selectedSubMenu == '확장고객정보') {
    //     _extendedCustomerInfoKey.currentState?.forceExitEditMode();
    //   }
    // }
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
    if (widget.selectedSubMenu == '관제고객등록') {
      _customerRegistrationInfoKey.currentState?.updateSearchQuery(query);
    } else if (widget.selectedSubMenu == '기본고객정보') {
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
      _pamenthistoryKey.currentState?.updateSearchQuery(query);
    } else if (widget.selectedSubMenu == '최근 방문 및 A/S 이력') {
      _visitashistoryKey.currentState?.updateSearchQuery(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 화면별로 다른 버튼 구성을 사용하기 위한 로직
    List<TopBarButton> buttons = _getButtonsForScreen(context);
    String title = _getTitleForScreen();

    return Container(
      color: context.colors.background,
      child: Column(
        children: [
          CustomTopBar(
            key: _topBarKey,
            title: title,
            buttons: buttons,
            onPageSearch: (query) {
              setState(() {});
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
      // 버튼 클릭 시점에 GlobalKey에서 currentState를 가져오는 함수 전달
      return TopBarConfig.basicCustomerInfoButtons(
        context,
        getState: () => _basicCustomerInfoKey.currentState,
        onStateChanged: () {
          // 편집 모드 변경 시 UI 업데이트
          setState(() {});
        },
      );
    }
    // 확장고객정보 화면
    else if (widget.selectedSubMenu == '확장고객정보') {
      return TopBarConfig.extendedCustomerInfoButtons(
        context,
        getState: () => _extendedCustomerInfoKey.currentState,
        onStateChanged: () {
          // 편집 모드 변경 시 UI 업데이트
          setState(() {});
        },
      );
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
      return TopBarConfig.mapDiagramButtons(
        context,
        getState: () => _mapDiagramKey.currentState,
        onStateChanged: () {
          // 편집 모드 변경 시 UI 업데이트
          setState(() {});
        },
      );
    } else if (widget.selectedMenu == '도면') {
      return TopBarConfig.blueprintButtons(
        context,
        getState: () => _blueprintKey.currentState,
        onStateChanged: () {
          // 편집 모드 변경 시 UI 업데이트
          setState(() {});
        },
      );
    } else if (widget.selectedSubMenu == '관제신호 개통처리') {
      return TopBarConfig.defaultButtons(context);
    } else if (widget.selectedSubMenu == '보수점검 완료이력') {
      return TopBarConfig.defaultButtons(context);
    } else if (widget.selectedMenu == 'AS 접수') {
      return TopBarConfig.defaultButtons(context);
    } else if (widget.selectedSubMenu == '영업정보') {
      return TopBarConfig.salesInfoButtons(context);
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
    if (widget.selectedMenu == '설정') {
      return Settings();
    }
    if (widget.selectedMenu == '관제고객등록') {
      return _buildCustomerRegistraionContent(context);
    }

    if (widget.selectedCustomer == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: context.colors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              '고객을 선택해주세요',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: context.colors.textSecondary,
              ),
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
        onEditModeChanged: () {
          // 편집 모드 변경 시 UI 업데이트
          if (mounted) {
            setState(() {});
          }
        },
      );
    }

    // 도면 메뉴
    if (widget.selectedMenu == '도면') {
      return Blueprint(
        key: _blueprintKey,
        searchpanel: widget.selectedCustomer!,
        onEditModeChanged: () {
          // 편집 모드 변경 시 UI 업데이트
          if (mounted) {
            setState(() {});
          }
        },
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

  Widget _buildCustomerRegistraionContent(BuildContext context) {
    return CustomerRegistration(
      key: _customerRegistrationInfoKey,
      searchpanel: widget.selectedCustomer!,
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

    // 관제고객등록
    if (widget.selectedSubMenu == '관제고객등록') {
      return CustomerRegistration(
        key: _customerRegistrationInfoKey,
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
          color: context.colors.background,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.construction_outlined,
                size: 64,
                color: context.colors.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                widget.selectedSubMenu ?? '준비 중',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '해당 화면은 준비 중입니다.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
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
    // 영업정보
    if (widget.selectedSubMenu == '영업정보') {
      return SalesInfoScreen(
        key: _salesKey,
        searchpanel: widget.selectedCustomer!,
      );
    }

    // 최근 수금 이력
    if (widget.selectedSubMenu == '최근 수금 이력') {
      return PaymentHistoryTable(
        key: _pamenthistoryKey,
        searchpanel: widget.selectedCustomer!,
      );
    }

    // 최근 방문 및 A/S 이력
    if (widget.selectedSubMenu == '최근 방문 및 A/S 이력') {
      return VisitAsHistoryTable(
        key: _visitashistoryKey,
        searchpanel: widget.selectedCustomer!,
      );
    }
    return SingleChildScrollView();
  }

  Widget _buildMenuContent(BuildContext context) {
    if (widget.selectedMenu == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.background,
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
                color: context.colors.selectedColor,
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
              color: context.colors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${widget.selectedSubMenu ?? widget.selectedMenu} 내용이 여기에 표시됩니다.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
