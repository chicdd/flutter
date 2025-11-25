import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/smartphone_app_auth_registration.dart';
import '../screens/document_support.dart';
import '../style.dart';
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

  Widget _buildMenuContent(BuildContext context) {
    if (widget.selectedMenu == null) {
      return const SizedBox.shrink();
    }

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
