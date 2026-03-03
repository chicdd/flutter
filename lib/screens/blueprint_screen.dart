import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:securityindex/theme.dart';
import '../models/search_panel.dart';
import '../models/customer_detail.dart';
import '../models/blueprint.dart';
import '../services/api_service.dart';
import '../functions.dart';
import '../style.dart';

/// 도면 화면
class Blueprint extends StatefulWidget {
  final SearchPanel? searchpanel;
  final VoidCallback? onEditModeChanged;

  const Blueprint({
    super.key,
    this.searchpanel,
    this.onEditModeChanged,
  });

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
      backgroundColor: context.colors.background,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 도면 이미지 영역
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
            if (_blueprints.length > 1) const SizedBox(height: 20),
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
                                  ? context.colors.selectedColor
                                  : context.colors.white,
                              foregroundColor: isActive
                                  ? context.colors.white
                                  : context.colors.textPrimary,
                              elevation: isActive ? 2 : 0,
                              side: BorderSide(
                                color: isActive
                                    ? context.colors.selectedColor
                                    : context.colors.white,
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
                  ],
                ),
              ],
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
              color: context.colors.gray30,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: context.colors.gray30, fontSize: 16),
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
              color: context.colors.gray30,
            ),
            const SizedBox(height: 16),
            Text(
              '도면 데이터가 없습니다.',
              style: TextStyle(color: context.colors.gray30, fontSize: 16),
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
              color: context.colors.gray30,
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
                        color: context.colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '이미지를 표시할 수 없습니다.',
                        style: TextStyle(
                          color: context.colors.gray30,
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
                  color: context.colors.gray30.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '등록일자: ${_formatDate(currentBlueprint.registrationDate!)}',
                  style: TextStyle(
                    color: context.colors.textPrimary,
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
        print('도면 편집 프로세스 종료 시도: PID=$pid');

        // Windows에서 taskkill 명령으로 강제 종료
        final killProcess = await Process.run('taskkill', ['/F', '/PID', pid.toString()]);

        if (killProcess.exitCode == 0) {
          print('도면 편집 프로세스가 강제 종료되었습니다.');
        } else {
          print('taskkill 실패, kill() 시도');
          _editingProcess!.kill(ProcessSignal.sigkill);
        }
      } catch (e) {
        print('도면 프로세스 종료 실패: $e');
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

  /// 도면 이미지 수정 (그림판으로 열기)
  Future<void> editBlueprint() async {
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
      final tempFilePath = '${tempDir.path}\\blueprint_temp.png';

      // 임시 파일 생성
      final tempFile = File(tempFilePath);

      // 현재 도면 데이터
      final currentBlueprint =
          _blueprints.isNotEmpty && _currentIndex < _blueprints.length
          ? _blueprints[_currentIndex]
          : null;

      // 도면 이미지가 있으면 파일로 저장, 없으면 빈 PNG 파일 생성
      if (currentBlueprint != null && currentBlueprint.hasBlueprint) {
        await tempFile.writeAsBytes(currentBlueprint.blueprintImage!);
        print('기존 도면 이미지 저장: $tempFilePath');
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
            if (_currentIndex < _blueprints.length) {
              _blueprints[_currentIndex] = BlueprintData(
                controlManagementNumber:
                    customer?.controlManagementNumber ??
                    _blueprints[_currentIndex].controlManagementNumber,
                registrationDate: DateTime.now(),
                dataTypeCode: _blueprints[_currentIndex].dataTypeCode,
                blueprintImage: modifiedImageBytes,
              );
            } else {
              // 새 도면 추가
              _blueprints.add(
                BlueprintData(
                  controlManagementNumber:
                      customer?.controlManagementNumber ?? '',
                  registrationDate: DateTime.now(),
                  dataTypeCode: '1',
                  blueprintImage: modifiedImageBytes,
                ),
              );
            }
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
      print('도면 이미지 수정 오류: $e');
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

  /// 도면 이미지 저장
  Future<void> saveBlueprint() async {
    if (_blueprints.isEmpty || _currentIndex >= _blueprints.length) {
      showToast(context, message: '저장할 도면 이미지가 없습니다.');
      return;
    }

    final currentBlueprint = _blueprints[_currentIndex];
    if (!currentBlueprint.hasBlueprint) {
      showToast(context, message: '저장할 도면 이미지가 없습니다.');
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

      // API 호출하여 도면 이미지 저장
      await DatabaseService.updateBlueprint(
        managementNumber: customer.controlManagementNumber,
        blueprintImage: currentBlueprint.blueprintImage!,
        blueprintType: _currentIndex == 0 ? '1' : '2', // 1: 도면마스터, 2: 도면마스터2
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      showToast(context, message: '도면 이미지가 저장되었습니다.');
    } catch (e) {
      print('도면 이미지 저장 오류: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      showToast(context, message: '저장 중 오류가 발생했습니다: $e');
    }
  }
}
