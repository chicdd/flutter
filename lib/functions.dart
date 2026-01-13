import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/selected_customer_service.dart';
import 'models/customer_detail.dart';
import 'models/search_panel.dart';
import 'style.dart';

/// 공통 함수 모음
///
/// 여러 화면에서 공통으로 사용되는 함수들을 정의합니다.
/// - 고객 서비스 리스너 관리
/// - 데이터 로딩 패턴
/// - UI 업데이트 로직

/// 고객 서비스 변경 핸들러 Mixin
///
/// StatefulWidget에서 SelectedCustomerService의 변경사항을 처리하는 공통 로직을 제공합니다.
///
/// 사용 방법:
/// ```dart
/// class MyScreenState extends State<MyScreen> with CustomerServiceHandler {
///   @override
///   void onCustomerChanged(SearchPanel? customer, CustomerDetail? detail) {
///     // 고객이 변경되었을 때 처리할 로직
///     if (detail != null) {
///       _updateUIFromDetail(detail);
///     }
///   }
/// }
/// ```
mixin CustomerServiceHandler<T extends StatefulWidget> on State<T> {
  late final SelectedCustomerService _customerService;

  /// 서비스 초기화 여부
  bool _isServiceInitialized = false;

  /// 고객 서비스 인스턴스 반환
  SelectedCustomerService get customerService => _customerService;

  /// 리스너 초기화
  /// initState에서 호출해야 합니다.
  @mustCallSuper
  void initCustomerServiceListener() {
    if (!_isServiceInitialized) {
      _customerService = SelectedCustomerService();
      _customerService.addListener(_handleCustomerServiceChange);
      _isServiceInitialized = true;
    }
  }

  /// 리스너 해제
  /// dispose에서 호출해야 합니다.
  @mustCallSuper
  void disposeCustomerServiceListener() {
    if (_isServiceInitialized) {
      _customerService.removeListener(_handleCustomerServiceChange);
    }
  }

  /// 내부 핸들러
  void _handleCustomerServiceChange() {
    if (mounted && !_customerService.isLoadingDetail) {
      final customer = _customerService.selectedCustomer;
      final detail = _customerService.customerDetail;
      onCustomerChanged(customer, detail);
    }
  }

  /// 고객 변경 시 호출될 콜백
  /// 서브클래스에서 구현해야 합니다.
  void onCustomerChanged(SearchPanel? customer, CustomerDetail? detail);
}

/// 데이터 로딩 헬퍼
class DataLoadingHelper {
  /// 안전한 데이터 로딩
  ///
  /// mounted 체크와 에러 처리를 포함한 데이터 로딩을 수행합니다.
  ///
  /// [context]: BuildContext
  /// [loadFunction]: 데이터를 로드하는 비동기 함수
  /// [onSuccess]: 로딩 성공 시 호출될 콜백
  /// [onError]: 에러 발생 시 호출될 콜백 (선택사항)
  /// [showLoadingIndicator]: 로딩 인디케이터 표시 여부 (기본값: false)
  static Future<void> safeLoad<T>({
    required BuildContext context,
    required Future<T> Function() loadFunction,
    required void Function(T data) onSuccess,
    void Function(dynamic error)? onError,
    bool showLoadingIndicator = false,
  }) async {
    try {
      if (showLoadingIndicator && context.mounted) {
        // 로딩 인디케이터 표시
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      final data = await loadFunction();

      if (showLoadingIndicator && context.mounted) {
        Navigator.of(context).pop(); // 로딩 인디케이터 제거
      }

      if (context.mounted) {
        onSuccess(data);
      }
    } catch (e) {
      if (showLoadingIndicator && context.mounted) {
        Navigator.of(context).pop(); // 로딩 인디케이터 제거
      }

      print('데이터 로딩 오류: $e');

      if (onError != null) {
        onError(e);
      } else if (context.mounted) {
        // 기본 에러 처리
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('데이터 로딩 중 오류가 발생했습니다: $e')));
      }
    }
  }

  /// 여러 데이터를 동시에 로드
  ///
  /// [loadFunctions]: 실행할 비동기 함수 리스트
  /// [onAllComplete]: 모든 로딩이 완료되면 호출될 콜백
  static Future<void> loadMultiple({
    required List<Future<void> Function()> loadFunctions,
    VoidCallback? onAllComplete,
  }) async {
    try {
      await Future.wait(loadFunctions.map((fn) => fn()));
      onAllComplete?.call();
    } catch (e) {
      print('다중 데이터 로딩 오류: $e');
      rethrow;
    }
  }
}

/// 초기화 패턴 헬퍼
///
/// 화면 초기화 시 순차적으로 데이터를 로드하는 패턴을 제공합니다.
class InitializationHelper {
  /// 순차적 초기화
  ///
  /// 여러 초기화 단계를 순서대로 실행합니다.
  /// 각 단계는 이전 단계가 완료된 후에 실행됩니다.
  ///
  /// [steps]: 초기화 단계 리스트
  /// [onComplete]: 모든 단계 완료 후 호출될 콜백
  /// [onError]: 에러 발생 시 호출될 콜백
  static Future<void> sequentialInit({
    required List<Future<void> Function()> steps,
    VoidCallback? onComplete,
    void Function(dynamic error, int stepIndex)? onError,
  }) async {
    for (int i = 0; i < steps.length; i++) {
      try {
        await steps[i]();
      } catch (e) {
        print('초기화 단계 $i 에러: $e');
        if (onError != null) {
          onError(e, i);
        } else {
          rethrow;
        }
        return; // 에러 발생 시 중단
      }
    }
    onComplete?.call();
  }
}

/// 필드 초기화 헬퍼
class FieldInitializationHelper {
  /// 여러 TextEditingController를 한 번에 초기화
  static void clearControllers(List<TextEditingController> controllers) {
    for (final controller in controllers) {
      controller.clear();
    }
  }

  /// 여러 TextEditingController를 한 번에 dispose
  static void disposeControllers(List<TextEditingController> controllers) {
    for (final controller in controllers) {
      controller.dispose();
    }
  }
}

class DateParsingHelper {
  /// 여러 화면에서 공통으로 사용할 날짜 선택 실행 함수
  static Future<void> openDatePicker({
    required BuildContext context,
    required bool isStartDate,
    required DateTime startDate,
    required DateTime endDate,
    required TextEditingController startController,
    required TextEditingController endController,
    required Function(DateTime newStartDate, DateTime newEndDate) onConfirm,
  }) async {
    final picked = await showDatePickerDialog(
      context,
      initialDate: isStartDate ? startDate : endDate,
    );

    if (picked != null) {
      DateTime updatedStartDate = startDate;
      DateTime updatedEndDate = endDate;

      if (isStartDate) {
        updatedStartDate = picked;
        startController.text = DateFormat('yyyy-MM-dd').format(picked);
      } else {
        updatedEndDate = picked;
        endController.text = DateFormat('yyyy-MM-dd').format(picked);
      }

      // 화면측에 변경된 날짜들을 전달 (여기서 setState와 데이터 로드 수행)
      await onConfirm(updatedStartDate, updatedEndDate);
    }
  }
}
