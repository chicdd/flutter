import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/search_panel.dart';
import '../models/customer_detail.dart';
import '../models/map_diagram.dart';
import '../services/api_service.dart';
import '../functions.dart';
import '../style.dart';
import '../theme.dart';

/// 약도 화면
class MapDiagram extends StatefulWidget {
  final SearchPanel? searchpanel;
  final VoidCallback? onEditModeChanged;

  const MapDiagram({
    super.key,
    this.searchpanel,
    this.onEditModeChanged,
  });

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

  // 편집 중 플래그
  bool isEditMode = false;

  // 편집 중인 그림판 프로세스
  Process? _editingProcess;

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

  /// 약도 이미지 수정 (그림판으로 열기)
  Future<void> editMapDiagram() async {
    // 이미 편집 중인지 확인
    if (isEditMode) {
      showToast(context, message: '이미 편집중입니다.');
      return;
    }

    try {
      // 편집 중 플래그 설정
      setState(() {
        isEditMode = true;
      });

      // 임시 디렉토리 가져오기
      final tempDir = await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}\\map_diagram_temp.png';

      // 임시 파일 생성
      final tempFile = File(tempFilePath);

      // 약도 이미지가 있으면 파일로 저장, 없으면 빈 PNG 파일 생성
      if (_mapDiagram != null && _mapDiagram!.hasMapDiagram) {
        await tempFile.writeAsBytes(_mapDiagram!.mapDiagramImage!);
        print('기존 약도 이미지 저장: $tempFilePath');
      } else {
        // 빈 PNG 파일 생성 (1x1 투명 픽셀)
        final emptyPng = [
          0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG 시그니처
          0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR 청크
          0x00, 0x00, 0x03, 0x20, 0x00, 0x00, 0x02, 0x58, // 800x600 크기
          0x08, 0x06, 0x00, 0x00, 0x00, 0x7E, 0x8B, 0xD1,
          0x95, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, // IDAT 청크
          0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
          0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
          0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, // IEND 청크
          0x42, 0x60, 0x82,
        ];
        await tempFile.writeAsBytes(emptyPng);
        print('빈 PNG 파일 생성: $tempFilePath');
      }

      // 파일이 제대로 생성되었는지 확인
      if (!await tempFile.exists()) {
        throw Exception('임시 파일 생성 실패: $tempFilePath');
      }

      print('임시 파일 경로: $tempFilePath');
      print('파일 크기: ${await tempFile.length()} bytes');

      showToast(context, message: '그림판으로 이미지를 여는 중입니다...');

      // 그림판(mspaint.exe) 실행 및 종료 대기
      _editingProcess = await Process.start('mspaint.exe', [
        tempFilePath,
      ], runInShell: true);

      print('그림판 프로세스 시작됨 (PID: ${_editingProcess!.pid})');

      // 프로세스 종료 대기
      final exitCode = await _editingProcess!.exitCode;
      print('그림판 프로세스 종료됨 (종료 코드: $exitCode)');
      _editingProcess = null;

      // 수정된 이미지 읽기
      if (await tempFile.exists()) {
        final modifiedImageBytes = await tempFile.readAsBytes();
        print('수정된 이미지 크기: ${modifiedImageBytes.length} bytes');

        // 이미지가 비어있지 않은지 확인
        if (modifiedImageBytes.length > 100) {
          final customer = customerService.selectedCustomer;

          setState(() {
            // 수정된 이미지로 업데이트
            _mapDiagram = MapDiagramData(
              controlManagementNumber:
                  customer?.controlManagementNumber ??
                  _mapDiagram?.controlManagementNumber,
              registrationDate: DateTime.now(),
              sequenceNumber: _mapDiagram?.sequenceNumber ?? '1',
              dataTypeCode: _mapDiagram?.dataTypeCode ?? '1',
              mapDiagramImage: modifiedImageBytes,
              visioImage: _mapDiagram?.visioImage,
              wmfImage: _mapDiagram?.wmfImage,
            );
          });

          showToast(context, message: '이미지가 업데이트되었습니다. 저장 버튼을 눌러주세요.');
        } else {
          print('이미지가 너무 작음. 변경사항이 없을 수 있습니다.');
          showToast(context, message: '변경사항이 없습니다.');
        }

        // 임시 파일 삭제
        try {
          await tempFile.delete();
          print('임시 파일 삭제됨');
        } catch (e) {
          print('임시 파일 삭제 실패: $e');
        }
      } else {
        print('임시 파일이 존재하지 않음: $tempFilePath');
        showToast(context, message: '임시 파일을 찾을 수 없습니다.');
      }
    } catch (e) {
      print('약도 이미지 수정 오류: $e');
      showToast(context, message: '이미지 수정 중 오류가 발생했습니다: $e');
    } finally {
      // 편집 중 플래그 해제
      if (mounted) {
        setState(() {
          isEditMode = false;
        });
        // 편집 모드 변경 알림
        widget.onEditModeChanged?.call();
      }
    }
  }

  /// 약도 이미지 저장
  Future<void> saveMapDiagram() async {
    if (_mapDiagram == null || !_mapDiagram!.hasMapDiagram) {
      showToast(context, message: '저장할 약도 이미지가 없습니다.');
      return;
    }

    final customer = customerService.selectedCustomer;
    if (customer == null) {
      showToast(context, message: '선택된 고객이 없습니다.');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // API 호출하여 약도 이미지 저장
      await DatabaseService.updateMapDiagram(
        managementNumber: customer.controlManagementNumber,
        mapDiagramImage: _mapDiagram!.mapDiagramImage!,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      showToast(context, message: '약도 이미지가 저장되었습니다.');
    } catch (e) {
      print('약도 이미지 저장 오류: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      showToast(context, message: '저장 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 필수
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 약도 이미지 영역
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: context.colors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
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
            Icon(Icons.map_outlined, size: 64, color: context.colors.gray30),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: context.colors.textPrimary, fontSize: 16),
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
            Icon(Icons.map_outlined, size: 64, color: context.colors.gray30),
            const SizedBox(height: 16),
            Text(
              '약도 데이터가 없습니다.',
              style: TextStyle(color: context.colors.textPrimary, fontSize: 16),
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
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: context.colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '이미지를 표시할 수 없습니다.',
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 16,
                        ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: context.colors.gray30.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '등록일자: ${_formatDate(_mapDiagram!.registrationDate!)}',
                  style: TextStyle(
                    color: context.colors.textPrimary.withOpacity(0.8),
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

  /// 편집 중인 그림판 프로세스 강제 종료
  Future<void> closeEditingProcess() async {
    if (_editingProcess != null && isEditMode) {
      try {
        final pid = _editingProcess!.pid;
        print('약도 편집 프로세스 종료 시도: PID=$pid');

        // Windows에서 taskkill 명령으로 강제 종료
        final killProcess = await Process.run('taskkill', ['/F', '/PID', pid.toString()]);

        if (killProcess.exitCode == 0) {
          print('약도 편집 프로세스가 강제 종료되었습니다.');
        } else {
          print('taskkill 실패, kill() 시도');
          _editingProcess!.kill(ProcessSignal.sigkill);
        }
      } catch (e) {
        print('약도 프로세스 종료 실패: $e');
      } finally {
        _editingProcess = null;
        if (mounted) {
          setState(() {
            isEditMode = false;
          });
          // 편집 모드 변경 알림
          widget.onEditModeChanged?.call();
        }
      }
    }
  }
}
