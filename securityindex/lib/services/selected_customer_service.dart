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

  // Getters
  SearchPanel? get selectedCustomer => _selectedCustomer;
  CustomerDetail? get customerDetail => _customerDetail;
  bool get isLoadingDetail => _isLoadingDetail;

  /// 고객 선택
  void selectCustomer(SearchPanel? customer) {
    _selectedCustomer = customer;
    _customerDetail = null; // 새로운 고객 선택 시 이전 상세 정보 초기화
    notifyListeners();

    // 고객이 선택되면 자동으로 상세 정보 로드
    if (customer != null) {
      loadCustomerDetail();
    }
  }

  /// 고객 상세 정보 로드
  Future<void> loadCustomerDetail() async {
    if (_selectedCustomer == null) {
      return;
    }

    // 이미 로드 중이거나 로드된 경우 다시 로드하지 않음
    if (_isLoadingDetail) {
      return;
    }

    if (_customerDetail != null &&
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

  /// 고객 정보 새로고침
  Future<void> refreshCustomerDetail() async {
    if (_selectedCustomer == null) {
      return;
    }

    _customerDetail = null; // 기존 데이터 초기화
    await loadCustomerDetail();
  }

  /// 선택 해제
  void clearSelection() {
    _selectedCustomer = null;
    _customerDetail = null;
    notifyListeners();
  }
}
