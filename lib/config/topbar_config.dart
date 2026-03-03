import 'package:flutter/material.dart';
import 'package:securityindex/screens/blueprint_screen.dart';
import 'package:securityindex/screens/extended_customer_info.dart';
import 'package:securityindex/screens/map_diagram.dart';
import '../screens/basic_customer_info.dart';
import '../style.dart';

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
  /// 관제고객등록 화면 버튼
  static List<TopBarButton> customerRegistrationButtons(
    BuildContext context, {
    VoidCallback? onStateChanged,
  }) {
    return [
      // TopBarButton(
      //   label: '원격',
      //   onPressed: () => TopBarActions.onRemotePressed(context),
      // ),
      // TopBarButton(
      //   label: 'NEOERP',
      //   onPressed: () => TopBarActions.onNeoerpPressed(context),
      // ),
      // TopBarButton(
      //   label: '영상조회',
      //   onPressed: () => TopBarActions.onVideoSearchPressed(context),
      // ),
      TopBarButton(
        label: '저장',
        onPressed: () {
          TopBarActions.insertCustomer(context);
          // 저장 후 UI 업데이트 (편집 모드 종료)
          onStateChanged?.call();
        },
      ),
    ];
  }

  /// 기본고객정보 화면 버튼
  static List<TopBarButton> basicCustomerInfoButtons(
    BuildContext context, {
    BasicCustomerInfoState? Function()? getState,
    VoidCallback? onStateChanged,
  }) {
    // 현재 편집 모드 상태 확인
    final currentState = getState?.call();
    final isEditMode = currentState?.isEditMode ?? false;

    return [
      // TopBarButton(
      //   label: '원격',
      //   onPressed: () => TopBarActions.onRemotePressed(context),
      // ),
      // TopBarButton(
      //   label: 'NEOERP',
      //   onPressed: () => TopBarActions.onNeoerpPressed(context),
      // ),
      // TopBarButton(
      //   label: '영상조회',
      //   onPressed: () => TopBarActions.onVideoSearchPressed(context),
      // ),
      TopBarButton(
        label: isEditMode ? '취소' : '편집',
        backgroundColor: isEditMode ? Colors.grey : null,
        textColor: isEditMode ? Colors.white : null,
        onPressed: () {
          final state = getState?.call();
          TopBarActions.onEditPressed(context, state: state);
          // 편집 모드 변경 후 UI 업데이트
          onStateChanged?.call();
        },
      ),
      if (isEditMode)
        TopBarButton(
          label: '저장',
          onPressed: () {
            final state = getState?.call();
            TopBarActions.onSavePressed(context, state: state);
            // 저장 후 UI 업데이트 (편집 모드 종료)
            onStateChanged?.call();
          },
        ),
    ];
  }

  /// 확장고객정보 화면 버튼
  static List<TopBarButton> extendedCustomerInfoButtons(
    BuildContext context, {
    ExtendedCustomerInfoState? Function()? getState,
    VoidCallback? onStateChanged,
  }) {
    // 현재 편집 모드 상태 확인
    final currentState = getState?.call();
    final isEditMode = currentState?.isEditMode ?? false;
    return [
      // TopBarButton(
      //   label: '원격',
      //   onPressed: () => TopBarActions.onRemotePressed(context),
      // ),
      // TopBarButton(
      //   label: 'NEOERP',
      //   onPressed: () => TopBarActions.onNeoerpPressed(context),
      // ),
      // TopBarButton(
      //   label: '내보내기',
      //   onPressed: () => TopBarActions.onExportPressed(context),
      // ),
      TopBarButton(
        label: isEditMode ? '취소' : '편집',
        backgroundColor: isEditMode ? Colors.grey : null,
        textColor: isEditMode ? Colors.white : null,
        onPressed: () {
          final state = getState?.call();
          TopBarActions.onEditPressed(context, state: state);
          // 편집 모드 변경 후 UI 업데이트
          onStateChanged?.call();
        },
      ),
      if (isEditMode)
        TopBarButton(
          label: '저장',
          onPressed: () {
            final state = getState?.call();
            TopBarActions.onSavePressed(context, state: state);
            // 저장 후 UI 업데이트 (편집 모드 종료)
            onStateChanged?.call();
          },
        ),
    ];
  }

  /// 관제고객저장 화면 버튼
  static List<TopBarButton> customerRegisterButtons(BuildContext context) {
    return [];
  }

  /// 스마트어플인증등록 화면 버튼
  static List<TopBarButton> smartPhoneRegisterButtons(BuildContext context) {
    return [];
  }

  /// 약도
  static List<TopBarButton> mapDiagramButtons(
    BuildContext context, {
    MapDiagramState? Function()? getState,
    VoidCallback? onStateChanged,
  }) {
    // 현재 편집 모드 상태 확인
    final currentState = getState?.call();
    final isEditMode = currentState?.isEditMode ?? false;
    return [
      // TopBarButton(
      //   label: '추가',
      //   onPressed: () => TopBarActions.onMapDiagramEdit(
      //     context,
      //     getState: getState,
      //   ), //api에서 Update 된 내용이 없으면 Insert 됨.
      // ),
      TopBarButton(
        label: '수정',
        backgroundColor: isEditMode ? Colors.grey : null,
        textColor: isEditMode ? Colors.white : null,
        onPressed: () {
          if (isEditMode) {
            showToast(context, message: '편집 중 입니다.');
          } else {
            TopBarActions.onMapDiagramEdit(context, getState: getState);
          }
          onStateChanged?.call();
        },
      ),
      TopBarButton(
        label: '저장',
        onPressed: () {
          if (isEditMode) {
            showToast(context, message: '편집 후 저장하세요.');
          } else {
            TopBarActions.onMapDiagramSave(context, getState: getState);
          }
        },
      ),
      // TopBarButton(
      //   label: '서한약도',
      //   onPressed: () => TopBarActions.onExportPressed(context),
      // ),
      // TopBarButton(
      //   label: 'NeoDraw도면편집',
      //   onPressed: () => TopBarActions.onEditPressed(context),
      // ),
      // TopBarButton(
      //   label: '저장된 도면 새로고침',
      //   onPressed: () => TopBarActions.onSavePressed(context),
      // ),
      // TopBarButton(
      //   label: 'SDRAW편집',
      //   onPressed: () => TopBarActions.onEditPressed(context),
      // ),
      // TopBarButton(
      //   label: 'GIS 자동약도 작성',
      //   onPressed: () => TopBarActions.onSavePressed(context),
      // ),
      // TopBarButton(
      //   label: '약도출력',
      //   onPressed: () => TopBarActions.onEditPressed(context),
      // ),
    ];
  }

  /// 도면
  static List<TopBarButton> blueprintButtons(
    BuildContext context, {
    BlueprintState? Function()? getState,
    VoidCallback? onStateChanged,
  }) {
    // 현재 편집 모드 상태 확인
    final currentState = getState?.call();
    final isEditMode = currentState?.isEditMode ?? false;
    return [
      TopBarButton(
        label: '수정',
        backgroundColor: isEditMode ? Colors.grey : null,
        textColor: isEditMode ? Colors.white : null,
        onPressed: () {
          if (isEditMode) {
            showToast(context, message: '편집 중 입니다.');
          } else {
            TopBarActions.onBlueprintEdit(context, getState: getState);
            onStateChanged?.call();
          }
        },
      ),
      TopBarButton(
        label: '저장',
        onPressed: () {
          if (isEditMode) {
            showToast(context, message: '편집 후 저장하세요.');
          } else {
            TopBarActions.onBlueprintSave(context, getState: getState);
          }
        },
      ),
    ];
  }

  /// 영업정보 화면 버튼
  static List<TopBarButton> salesInfoButtons(BuildContext context) {
    return [
      TopBarButton(
        label: '내보내기',
        onPressed: () => TopBarActions.onExportPressed(context),
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
    showToast(context, message: '원격 기능이 실행됩니다.');
    // TODO: 원격 기능 구현
  }

  /// NEOERP 버튼 클릭
  static void onNeoerpPressed(BuildContext context) {
    showToast(context, message: 'NEOERP 기능이 실행됩니다.');
    // TODO: NEOERP 기능 구현
  }

  /// 영상조회 버튼 클릭
  static void onVideoSearchPressed(BuildContext context) {
    showToast(context, message: '영상조회 기능이 실행됩니다.');
    // TODO: 영상조회 기능 구현
  }

  /// 내보내기 버튼 클릭
  static void onExportPressed(BuildContext context) {
    showToast(context, message: '내보내기 기능이 실행됩니다.');
    // TODO: 내보내기 기능 구현
  }

  /// 편집 버튼 클릭
  static void onEditPressed(BuildContext context, {dynamic state}) {
    // BasicCustomerInfo 또는 ExtendedCustomerInfo 화면의 State를 찾아서 enterEditMode 호출
    dynamic targetState = state;

    targetState ??=
        context.findAncestorStateOfType<BasicCustomerInfoState>() ??
        context.findAncestorStateOfType<ExtendedCustomerInfoState>();

    if (targetState != null && targetState.isEditMode != null) {
      if (targetState.isEditMode) {
        // 이미 편집 모드인 경우 취소
        targetState.exitEditMode();
      } else {
        // 편집 모드 진입
        targetState.enterEditMode();
        showToast(context, message: '편집 모드가 활성화되었습니다.');
      }
    } else {
      showToast(context, message: 'State를 찾을 수 없습니다.');
    }
  }

  /// 저장 버튼 클릭
  static void onSavePressed(BuildContext context, {dynamic state}) {
    // BasicCustomerInfo 또는 ExtendedCustomerInfo 화면의 State를 찾아서 saveChanges 호출
    dynamic targetState = state;

    targetState ??=
        context.findAncestorStateOfType<BasicCustomerInfoState>() ??
        context.findAncestorStateOfType<ExtendedCustomerInfoState>();

    if (targetState != null && targetState.isEditMode != null) {
      if (targetState.isEditMode) {
        targetState.saveChanges();
      } else {
        showToast(context, message: '편집 모드가 아닙니다.');
      }
    } else {
      showToast(context, message: 'State를 찾을 수 없습니다.');
    }
  }

  /// 약도 수정 버튼 클릭
  static void onMapDiagramEdit(
    BuildContext context, {
    dynamic Function()? getState,
  }) {
    final state = getState?.call();
    if (state != null) {
      state.editMapDiagram();
    } else {
      showToast(context, message: '약도 화면을 찾을 수 없습니다.');
    }
  }

  /// 약도 저장 버튼 클릭
  static void onMapDiagramSave(
    BuildContext context, {
    dynamic Function()? getState,
  }) {
    final state = getState?.call();
    if (state != null) {
      state.saveMapDiagram();
    } else {
      showToast(context, message: '약도 화면을 찾을 수 없습니다.');
    }
  }

  /// 도면 수정 버튼 클릭
  static void onBlueprintEdit(
    BuildContext context, {
    dynamic Function()? getState,
  }) {
    final state = getState?.call();
    if (state != null) {
      state.editBlueprint();
    } else {
      showToast(context, message: '도면 화면을 찾을 수 없습니다.');
    }
  }

  /// 도면 저장 버튼 클릭
  static void onBlueprintSave(
    BuildContext context, {
    dynamic Function()? getState,
  }) {
    final state = getState?.call();
    if (state != null) {
      state.saveBlueprint();
    } else {
      showToast(context, message: '도면 화면을 찾을 수 없습니다.');
    }
  }

  /// 도면 저장 버튼 클릭
  static void insertCustomer(
    BuildContext context, {
    dynamic Function()? getState,
  }) {
    final state = getState?.call();
    if (state != null) {
      state.saveCustomer();
    } else {
      showToast(context, message: '고객 등록에 실패했습니다.');
    }
  }
}
