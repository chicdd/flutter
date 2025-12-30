import 'package:flutter/material.dart';
import '../models/search_panel.dart';
import '../models/customer_detail.dart';
import '../models/map_diagram.dart';
import '../services/api_service.dart';
import '../functions.dart';

/// 약도 화면
class MapDiagram extends StatefulWidget {
  final SearchPanel? searchpanel;
  const MapDiagram({super.key, this.searchpanel});

  @override
  State<MapDiagram> createState() => MapDiagramState();
}

class MapDiagramState extends State<MapDiagram>
    with AutomaticKeepAliveClientMixin, CustomerServiceHandler {
  @override
  bool get wantKeepAlive => true;

  // 약도 데이터
  MapDiagramData? _mapDiagram;

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
      _loadMapDiagram(customer.controlManagementNumber);
    }
  }

  @override
  void onCustomerChanged(SearchPanel? customer, CustomerDetail? detail) {
    if (customer != null) {
      _loadMapDiagram(customer.controlManagementNumber);
    }
  }

  /// 약도 데이터 로딩
  Future<void> _loadMapDiagram(String managementNumber) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final mapDiagram = await DatabaseService.getMapDiagram(
        managementNumber: managementNumber,
      );

      if (!mounted) return;

      setState(() {
        _mapDiagram = mapDiagram;
        _isLoading = false;
        if (mapDiagram == null) {
          _errorMessage = '약도 데이터가 없습니다.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = '약도 데이터를 불러오는 중 오류가 발생했습니다.';
      });
      print('약도 데이터 로딩 오류: $e');
    }
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
            // 약도 이미지 영역
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
            Icon(Icons.map_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_mapDiagram == null || !_mapDiagram!.hasMapDiagram) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              '약도 데이터가 없습니다.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // 약도 이미지 표시
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Stack(
        children: [
          // 이미지
          Center(
            child: Image.memory(
              _mapDiagram!.mapDiagramImage!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
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
          if (_mapDiagram!.registrationDate != null)
            Positioned(
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '등록일자: ${_formatDate(_mapDiagram!.registrationDate!)}',
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
