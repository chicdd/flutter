import 'package:flutter/material.dart';
import '../screens/basic_customer_info.dart';

/// 상단바 버튼 정의 클래스
class TopBarButton {
  final String label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const TopBarButton({
    required this.label,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });
}

/// 각 화면별 상단바 버튼 구성 정의
class TopBarConfig {
  /// 기본고객정보 화면 버튼
  static List<TopBarButton> basicCustomerInfoButtons(
    BuildContext context, {
    BasicCustomerInfoState? state,
  }) {
    return [
      TopBarButton(
        label: '원격',
        onPressed: () => TopBarActions.onRemotePressed(context),
      ),
      TopBarButton(
        label: 'NEOERP',
        onPressed: () => TopBarActions.onNeoerpPressed(context),
      ),
      TopBarButton(
        label: '영상조회',
        onPressed: () => TopBarActions.onVideoSearchPressed(context),
      ),
      TopBarButton(
        label: '편집',
        onPressed: () => TopBarActions.onEditPressed(context, state: state),
      ),
      TopBarButton(
        label: '저장',
        onPressed: () => TopBarActions.onSavePressed(context, state: state),
      ),
    ];
  }

  /// 확장고객정보 화면 버튼
  static List<TopBarButton> extendedCustomerInfoButtons(BuildContext context) {
    return [
      TopBarButton(
        label: '원격',
        onPressed: () => TopBarActions.onRemotePressed(context),
      ),
      TopBarButton(
        label: 'NEOERP',
        onPressed: () => TopBarActions.onNeoerpPressed(context),
      ),
      TopBarButton(
        label: '내보내기',
        onPressed: () => TopBarActions.onExportPressed(context),
      ),
      TopBarButton(
        label: '편집',
        onPressed: () => TopBarActions.onEditPressed(context),
      ),
      TopBarButton(
        label: '저장',
        onPressed: () => TopBarActions.onSavePressed(context),
      ),
    ];
  }

  /// 스마트어플인증등록 화면 버튼
  static List<TopBarButton> smartPhoneRegisterButtons(BuildContext context) {
    return [];
  }

  /// 최근신호이력
  static List<TopBarButton> recentSignalListButtons(BuildContext context) {
    return [
      TopBarButton(
        label: '저장',
        onPressed: () => TopBarActions.onSavePressed(context),
      ),
    ];
  }

  /// 약도
  static List<TopBarButton> mapDiagramButtons(BuildContext context) {
    return [
      TopBarButton(
        label: '수정',
        onPressed: () => TopBarActions.onRemotePressed(context),
      ),
      TopBarButton(
        label: '저장',
        onPressed: () => TopBarActions.onNeoerpPressed(context),
      ),
      TopBarButton(
        label: '서한약도',
        onPressed: () => TopBarActions.onExportPressed(context),
      ),
      TopBarButton(
        label: 'NeoDraw도면편집',
        onPressed: () => TopBarActions.onEditPressed(context),
      ),
      TopBarButton(
        label: '저장된 도면 새로고침',
        onPressed: () => TopBarActions.onSavePressed(context),
      ),
      TopBarButton(
        label: 'SDRAW편집',
        onPressed: () => TopBarActions.onEditPressed(context),
      ),
      TopBarButton(
        label: 'GIS 자동약도 작성',
        onPressed: () => TopBarActions.onSavePressed(context),
      ),
      TopBarButton(
        label: '약도출력',
        onPressed: () => TopBarActions.onEditPressed(context),
      ),
    ];
  }

  /// 기타 화면 버튼 (공통)
  static List<TopBarButton> defaultButtons(BuildContext context) {
    return [];
  }
}

/// 상단바 버튼 액션 핸들러
class TopBarActions {
  /// 원격 버튼 클릭
  static void onRemotePressed(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('원격 기능이 실행됩니다.')));
    // TODO: 원격 기능 구현
  }

  /// NEOERP 버튼 클릭
  static void onNeoerpPressed(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('NEOERP 기능이 실행됩니다.')));
    // TODO: NEOERP 기능 구현
  }

  /// 영상조회 버튼 클릭
  static void onVideoSearchPressed(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('영상조회 기능이 실행됩니다.')));
    // TODO: 영상조회 기능 구현
  }

  /// 내보내기 버튼 클릭
  static void onExportPressed(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('내보내기 기능이 실행됩니다.')));
    // TODO: 내보내기 기능 구현
  }

  /// 편집 버튼 클릭
  static void onEditPressed(
    BuildContext context, {
    BasicCustomerInfoState? state,
  }) {
    // BasicCustomerInfo 화면의 State를 찾아서 enterEditMode 호출
    print(context);
    if (state != null) {
      print(state);
      if (state.isEditMode) {
        // 이미 편집 모드인 경우 취소
        state.exitEditMode();
      } else {
        // 편집 모드 진입
        state.enterEditMode();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('편집 모드가 활성화되었습니다.')));
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('State를 찾을 수 없습니다.')));
    }
  }

  /// 저장 버튼 클릭
  static void onSavePressed(
    BuildContext context, {
    BasicCustomerInfoState? state,
  }) {
    // BasicCustomerInfo 화면의 State를 찾아서 saveChanges 호출
    final targetState =
        state ?? context.findAncestorStateOfType<BasicCustomerInfoState>();
    if (targetState != null && targetState.isEditMode) {
      targetState.saveChanges();
    } else if (targetState != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('편집 모드가 아닙니다.')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('State를 찾을 수 없습니다.')));
    }
  }
}
