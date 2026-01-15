import 'package:flutter/material.dart';
import '../theme.dart';

/// 추가 모달의 공통 기능을 제공하는 추상 클래스
///
/// 사용 방법:
/// ```dart
/// class _AddModal extends BaseAddModal {
///   final String controlManagementNumber;
///
///   const _AddModal({
///     required this.controlManagementNumber,
///     required super.onSaved,
///   });
///
///   @override
///   State<_AddModal> createState() => _AddModalState();
/// }
///
/// class _AddModalState extends BaseAddModalState<_AddModal> {
///   final TextEditingController _titleController = TextEditingController();
///
///   @override
///   String get modalTitle => 'A/S 접수 등록';
///
///   @override
///   String get saveButtonLabel => 'A/S 접수 등록';
///
///   @override
///   Future<bool> validateAndSave() async {
///     if (_titleController.text.isEmpty) {
///       showErrorSnackBar('제목을 입력해주세요.');
///       return false;
///     }
///
///     final data = {
///       '관제관리번호': widget.controlManagementNumber,
///       '제목': _titleController.text,
///     };
///
///     return await DatabaseService.addData(data);
///   }
///
///   @override
///   Widget buildFormFields() {
///     return Column(
///       children: [
///         CommonTextField(label: '제목', controller: _titleController),
///       ],
///     );
///   }
/// }
/// ```
abstract class BaseAddModal extends StatefulWidget {
  final VoidCallback onSaved;

  const BaseAddModal({super.key, required this.onSaved});
}

/// 추가 모달의 공통 State를 제공하는 추상 클래스
///
/// [W]: 위젯 타입 (BaseAddModal을 상속한 위젯)
abstract class BaseAddModalState<W extends BaseAddModal> extends State<W> {
  /// 저장 중 상태
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  // ========================================
  // 추상 메서드 (서브클래스에서 구현 필수)
  // ========================================

  /// 모달 제목
  String get modalTitle;

  /// 저장 버튼 라벨
  String get saveButtonLabel;

  /// 검증 및 저장 로직
  ///
  /// 검증 실패 시 false를 반환하고 스낵바를 표시합니다.
  /// 저장 성공 시 true를 반환합니다.
  Future<bool> validateAndSave();

  /// 입력 필드들을 빌드하는 위젯
  Widget buildFormFields();

  // ========================================
  // 선택적 오버라이드 메서드
  // ========================================

  /// 모달 너비 (기본값: 600)
  double get modalWidth => 600.0;

  /// 저장 성공 메시지 (기본값: '저장되었습니다.')
  String get successMessage => '저장되었습니다.';

  /// 저장 실패 메시지 (기본값: '저장에 실패했습니다.')
  String get failureMessage => '저장에 실패했습니다.';

  /// 저장 전 추가 검증 (선택적)
  ///
  /// 검증 실패 시 false를 반환하면 저장이 중단됩니다.
  Future<bool> onBeforeSave() async => true;

  /// 저장 후 추가 처리 (선택적)
  Future<void> onAfterSave(bool success) async {}

  // ========================================
  // 공통 헬퍼 메서드
  // ========================================

  /// 에러 스낵바 표시
  void showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  /// 성공 스낵바 표시
  void showSuccessSnackBar([String? message]) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message ?? successMessage)));
    }
  }

  // ========================================
  // 공통 저장 로직
  // ========================================

  /// 저장 처리
  Future<void> _handleSave() async {
    // 저장 전 검증
    final canProceed = await onBeforeSave();
    if (!canProceed) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // 검증 및 저장 실행
      final success = await validateAndSave();

      if (mounted) {
        if (success) {
          showSuccessSnackBar();
          await onAfterSave(true);
          Navigator.of(context).pop();
          widget.onSaved();
        } else {
          showErrorSnackBar(failureMessage);
          await onAfterSave(false);
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar('오류 발생: $e');
        await onAfterSave(false);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// 취소 처리
  void _handleCancel() {
    Navigator.of(context).pop();
  }

  // ========================================
  // 공통 빌드 메서드
  // ========================================

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.white,
      child: Container(
        width: modalWidth,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Text(
                modalTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // 입력 필드들
              buildFormFields(),

              const SizedBox(height: 24),

              // 버튼
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  /// 하단 버튼 빌드
  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isSaving ? null : _handleCancel,
          child: const Text('취소'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.selectedColor,
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(saveButtonLabel),
        ),
      ],
    );
  }
}
