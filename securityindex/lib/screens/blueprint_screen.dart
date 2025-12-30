import 'package:flutter/material.dart';
import '../models/search_panel.dart';
import '../models/customer_detail.dart';
import '../models/blueprint.dart';
import '../services/api_service.dart';
import '../functions.dart';

/// 도면 화면
class Blueprint extends StatefulWidget {
  final SearchPanel? searchpanel;
  const Blueprint({super.key, this.searchpanel});

  @override
  State<Blueprint> createState() => BlueprintState();
}

class BlueprintState extends State<Blueprint>
    with AutomaticKeepAliveClientMixin, CustomerServiceHandler {
  @override
  bool get wantKeepAlive => true;

  // 도면 데이터 리스트
  List<BlueprintData> _blueprints = [];

  // 현재 선택된 도면 인덱스 (0 = 도면마스터, 1 = 도면마스터2)
  int _currentIndex = 0;

  // 로딩 상태
  bool _isLoading = false;

  // 에러 메시지
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    initCustomerServiceListener();
    _initializeData();
  }

  @override
  void dispose() {
    disposeCustomerServiceListener();
    super.dispose();
  }

  /// 초기 데이터 로딩
  void _initializeData() {
    final customer = customerService.selectedCustomer;
    if (customer != null) {
      _loadBlueprints(customer.controlManagementNumber);
    }
  }

  @override
  void onCustomerChanged(SearchPanel? customer, CustomerDetail? detail) {
    if (customer != null) {
      _loadBlueprints(customer.controlManagementNumber);
    }
  }

  /// 도면 데이터 로딩
  Future<void> _loadBlueprints(String managementNumber) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentIndex = 0; // 초기화
    });

    try {
      final blueprints = await DatabaseService.getBlueprints(
        managementNumber: managementNumber,
      );

      if (!mounted) return;

      setState(() {
        _blueprints = blueprints;
        _isLoading = false;
        if (blueprints.isEmpty) {
          _errorMessage = '도면 데이터가 없습니다.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = '도면 데이터를 불러오는 중 오류가 발생했습니다.';
      });
      print('도면 데이터 로딩 오류: $e');
    }
  }

  /// 도면 전환
  void _switchBlueprint(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 필수
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // 도면 전환 버튼 (도면마스터2가 있을 때만 표시)
                    if (_blueprints.length > 1)
                      ...List.generate(_blueprints.length, (index) {
                        final isActive = _currentIndex == index;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ElevatedButton(
                            onPressed: () => _switchBlueprint(index),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isActive
                                  ? const Color(0xFF007AFF)
                                  : Colors.white,
                              foregroundColor: isActive
                                  ? Colors.white
                                  : const Color(0xFF252525),
                              elevation: isActive ? 2 : 0,
                              side: BorderSide(
                                color: isActive
                                    ? const Color(0xFF007AFF)
                                    : const Color(0xFFE0E0E0),
                                width: 1,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              index == 0 ? '도면' : '도면2',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    if (_blueprints.length < 1 || _blueprints.length == 1)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: SizedBox(width: 20, height: 32),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 도면 이미지 영역
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 콘텐츠 빌드
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.architecture_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_blueprints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.architecture_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              '도면 데이터가 없습니다.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final currentBlueprint = _blueprints[_currentIndex];

    if (!currentBlueprint.hasBlueprint) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.architecture_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              '도면 데이터가 없습니다.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // 도면 이미지 표시
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Stack(
        children: [
          // 이미지
          Center(
            child: Image.memory(
              currentBlueprint.blueprintImage!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '이미지를 표시할 수 없습니다.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 등록일자 오버레이 (오른쪽 밑)
          if (currentBlueprint.registrationDate != null)
            Positioned(
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '등록일자: ${_formatDate(currentBlueprint.registrationDate!)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 날짜 포맷팅
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
