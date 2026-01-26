import 'package:flutter/foundation.dart';
import '../models/search_panel.dart';
import '../models/customer_detail.dart';
import 'api_service.dart';

/// 선택된 고객 정보를 전역으로 관리하는 서비스
class SelectedCustomerService extends ChangeNotifier {
  static final SelectedCustomerService _instance =
      SelectedCustomerService._internal();

  factory SelectedCustomerService() {
    return _instance;
  }

  SelectedCustomerService._internal();

  // 선택된 고객 정보
  SearchPanel? _selectedCustomer;
  CustomerDetail? _customerDetail;
  bool _isLoadingDetail = false;

  // 편집 상태 관리
  bool _isEditing = false;
  bool _hasChanges = false;
  Function? _onCancelConfirm; // 취소 확인 다이얼로그 콜백

  // Getters
  SearchPanel? get selectedCustomer => _selectedCustomer;
  CustomerDetail? get customerDetail => _customerDetail;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isEditing => _isEditing;
  bool get hasChanges => _hasChanges;

  /// 고객 선택
  void selectCustomer(SearchPanel? customer) {
    // 같은 고객을 다시 선택한 경우 아무것도 하지 않음
    if (_selectedCustomer?.controlManagementNumber == customer?.controlManagementNumber) {
      return;
    }

    _selectedCustomer = customer;
    _customerDetail = null; // 다른 고객 선택 시에만 이전 상세 정보 초기화
    notifyListeners();

    // 자동으로 상세 정보를 로드하지 않음
    // 각 화면에서 필요한 경우 loadCustomerDetail() 또는 해당 화면의 API를 직접 호출
  }

  /// 고객 상세 정보 로드
  Future<void> loadCustomerDetail({bool force = false}) async {
    if (_selectedCustomer == null) {
      return;
    }

    // 이미 로드 중이거나 로드된 경우 다시 로드하지 않음
    if (_isLoadingDetail) {
      return;
    }

    // force가 true가 아닐 때만 캐시 사용
    if (!force &&
        _customerDetail != null &&
        _customerDetail!.controlManagementNumber ==
            _selectedCustomer!.controlManagementNumber) {
      return;
    }

    _isLoadingDetail = true;
    // 로딩 시작 시에는 notifyListeners 호출하지 않음 (무한 루프 방지)

    try {
      _customerDetail = await DatabaseService.getCustomerDetail(
        _selectedCustomer!.controlManagementNumber,
      );
    } catch (e) {
      print('고객 상세 정보 로드 오류: $e');
      _customerDetail = null;
    } finally {
      _isLoadingDetail = false;
      // 로딩 완료 후에만 notifyListeners 호출
      notifyListeners();
    }
  }

  /// 편집 모드 시작
  void startEditing(Function onCancelConfirm) {
    _isEditing = true;
    _hasChanges = false;
    _onCancelConfirm = onCancelConfirm;
    notifyListeners();
  }

  /// 변경사항 추적
  void markAsChanged() {
    if (_isEditing) {
      _hasChanges = true;
      notifyListeners();
    }
  }

  /// 편집 모드 종료 (저장 또는 정상 취소)
  void endEditing() {
    _isEditing = false;
    _hasChanges = false;
    _onCancelConfirm = null;
    notifyListeners();
  }

  /// 편집 중 이탈 시도 시 확인
  /// 반환값: true면 이탈 가능, false면 이탈 불가 (다이얼로그 표시 중)
  bool canLeave(Function onConfirmed) {
    if (_isEditing && _hasChanges) {
      // 변경사항이 있으면 취소 확인 다이얼로그 표시
      if (_onCancelConfirm != null) {
        _onCancelConfirm!(onConfirmed);
      }
      return false;
    }
    return true;
  }

  // /// 고객 정보 새로고침
  // Future<void> refreshCustomerDetail() async {
  //   if (_selectedCustomer == null) {
  //     return;
  //   }
  //
  //   _customerDetail = null; // 기존 데이터 초기화
  //   await loadCustomerDetail();
  // }
  //
  // /// 선택 해제
  // void clearSelection() {
  //   _selectedCustomer = null;
  //   _customerDetail = null;
  //   notifyListeners();
  // }
}
