import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/document_info.dart';
import '../services/api_service.dart';
import '../functions.dart';
import '../style.dart';
import '../theme.dart';
import '../widgets/component.dart';
import '../widgets/common_table.dart';
import 'base_table_screen.dart';

/// 문서지원 화면
class DocumentSupport extends BaseTableScreen<DocumentInfo> {
  const DocumentSupport({super.key, super.searchpanel});

  @override
  State<DocumentSupport> createState() => DocumentSupportState();
}

class DocumentSupportState extends BaseTableScreenState<DocumentInfo, DocumentSupport> {
  @override
  String get tableTitle => '첨부 데이터 리스트';

  @override
  bool get showAddButton => true;

  @override
  Map<int, double> get initialColumnWidths => {
        0: 150.0, // 문서일련번호
        1: 300.0, // 문서명
        2: 100.0, // 확장자
        3: 150.0, // 문서종류
        4: 300.0, // 문서설명
        5: 150.0, // 첨부일자
        6: 120.0, // 첨부자
      };

  @override
  Future<List<DocumentInfo>> loadDataFromApi(String key) async {
    return await DatabaseService.getDocumentInfo(key);
  }

  @override
  List<TableColumnConfig> buildColumns() {
    return [
      TableColumnConfig(
        header: '문서일련번호',
        width: columnWidths[0],
        valueBuilder: (data) => (data as DocumentInfo).documentSerialNumber ?? '-',
      ),
      TableColumnConfig(
        header: '문서명',
        width: columnWidths[1],
        valueBuilder: (data) => (data as DocumentInfo).documentName ?? '-',
      ),
      TableColumnConfig(
        header: '확장자',
        width: columnWidths[2],
        valueBuilder: (data) => (data as DocumentInfo).documentExtension ?? '-',
      ),
      TableColumnConfig(
        header: '문서종류',
        width: columnWidths[3],
        valueBuilder: (data) => (data as DocumentInfo).documentType ?? '-',
      ),
      TableColumnConfig(
        header: '문서설명',
        width: columnWidths[4],
        valueBuilder: (data) => (data as DocumentInfo).documentDescription ?? '-',
      ),
      TableColumnConfig(
        header: '첨부일자',
        width: columnWidths[5],
        valueBuilder: (data) => (data as DocumentInfo).attachmentDate ?? '-',
      ),
      TableColumnConfig(
        header: '첨부자',
        width: columnWidths[6],
        valueBuilder: (data) => (data as DocumentInfo).attacher ?? '-',
      ),
    ];
  }

  @override
  void onAddButtonPressed() {
    final customer = customerService.selectedCustomer;
    if (customer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('고객을 먼저 선택해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final managementNumber = customer.controlManagementNumber ?? '';
    print('선택된 고객 관제관리번호: $managementNumber');

    if (managementNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('관제관리번호가 없습니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _AddDocumentModal(
        managementNumber: managementNumber,
        onDocumentAdded: () {
          refreshData();
        },
      ),
    );
  }
}

/// 문서 추가 모달
class _AddDocumentModal extends StatefulWidget {
  final String managementNumber;
  final VoidCallback onDocumentAdded;
  const _AddDocumentModal({
    super.key,
    required this.managementNumber,
    required this.onDocumentAdded,
  });

  @override
  State<_AddDocumentModal> createState() => _AddDocumentModalState();
}

class _AddDocumentModalState extends State<_AddDocumentModal> {
  // 폼 컨트롤러
  final TextEditingController _documentNameController = TextEditingController();
  final TextEditingController _documentDescriptionController =
      TextEditingController();

  String? documentType; // 회사구분
  List<CodeData> _documentTypeList = [];

  // 체크박스 상태
  bool _saveFilter = false;

  // 선택된 파일 정보
  String? _selectedFileName;
  String? _documentName; // 확장자 제외한 파일명
  String? _documentExtension; // 파일 확장자
  List<int>? _fileBytes; // 파일 바이트 데이터

  @override
  void initState() {
    super.initState();
    // 드롭다운 데이터 로드
    _loadModalDropdownData();
  }

  /// 모달용 드롭다운 데이터 로드
  Future<void> _loadModalDropdownData() async {
    final docTypeList = await loadDropdownData('documenttype');
    if (mounted) {
      setState(() {
        _documentTypeList = docTypeList;
      });
    }
  }

  /// 문서 종류 추가 모달 표시
  void _showAddDocumentTypeModal(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent, // 배경을 투명하게 설정하여 한 번 더 어두워지지 않도록
      builder: (context) => _AddDocumentTypeModal(
        onDocumentTypeAdded: () async {
          // 드롭다운 데이터 새로고침
          await _loadModalDropdownData();
        },
      ),
    );
  }

  @override
  void dispose() {
    _documentNameController.dispose();
    _documentDescriptionController.dispose();
    super.dispose();
  }

  /// 문서 업로드
  Future<void> _uploadDocument() async {
    print('=== 문서 업로드 시작 ===');
    print('관제관리번호: ${widget.managementNumber}');
    print('문서명: $_documentName');
    print('파일 확장자: $_documentExtension');
    print('문서종류: $documentType');

    // 유효성 검사
    if (widget.managementNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('관제관리번호가 없습니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('파일을 선택해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_documentName == null || _documentName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('문서명이 없습니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (documentType == null || documentType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('문서종류를 선택해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final documentDescription = _documentDescriptionController.text.trim();

    // documentType(코드)로부터 코드명 찾기
    final documentTypeData = _documentTypeList.firstWhere(
      (item) => item.code == documentType,
      orElse: () => CodeData(code: '', name: ''),
    );
    final documentTypeName = documentTypeData.name;

    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      print('API 호출 파라미터:');
      print('  - managementNumber: ${widget.managementNumber}');
      print('  - documentName: $_documentName');
      print('  - documentExtension: ${_documentExtension ?? ""}');
      print('  - documentDescription: $documentDescription');
      print('  - documentType(코드): $documentType');
      print('  - documentTypeName(코드명): $documentTypeName');
      print('  - fileBytes length: ${_fileBytes!.length}');
      print('  - fileName: $_selectedFileName');

      // API 호출
      final success = await CodeDataCache.uploadDocument(
        managementNumber: widget.managementNumber,
        documentName: _documentName!,
        documentExtension: _documentExtension ?? '',
        documentDescription: documentDescription,
        documentTypeName: documentTypeName,
        fileBytes: _fileBytes!,
        fileName: _selectedFileName!,
      );

      // 로딩 닫기
      if (mounted) Navigator.of(context).pop();

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('문서가 업로드되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );

          widget.onDocumentAdded(); // 문서 목록 새로고침
          Navigator.of(context).pop(); // 모달 닫기
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('문서 업로드에 실패했습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // 로딩 닫기
      if (mounted) Navigator.of(context).pop();

      print('문서 업로드 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('문서 업로드 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 파일 선택
  Future<void> _selectFile() async {
    try {
      print('파일 선택 시작...');

      // FilePicker 인스턴스 직접 사용
      FilePickerResult? result;
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
          withData: true, // 파일 바이트를 직접 가져오기
        );
      } catch (pickerError) {
        print('FilePicker 초기화 오류: $pickerError');

        // 대체 방법: withData 없이 시도
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
        );
      }

      print('파일 선택 결과: ${result != null ? "파일 선택됨" : "취소됨"}');

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        print('선택된 파일: ${file.name}, 크기: ${file.size} bytes');

        // 파일명과 확장자 분리
        final fullFileName = file.name;
        final lastDotIndex = fullFileName.lastIndexOf('.');

        String documentName;
        String documentExtension;

        if (lastDotIndex != -1 && lastDotIndex < fullFileName.length - 1) {
          // 확장자가 있는 경우
          documentName = fullFileName.substring(0, lastDotIndex);
          documentExtension = fullFileName.substring(lastDotIndex + 1);
        } else {
          // 확장자가 없는 경우
          documentName = fullFileName;
          documentExtension = '';
        }

        // 파일 바이트 읽기
        List<int>? fileBytes;

        // withData: true 옵션으로 bytes를 직접 가져옴
        if (file.bytes != null) {
          fileBytes = file.bytes!;
          print('파일 바이트 읽기 성공: ${fileBytes.length} bytes');
        } else if (file.path != null) {
          // 경로가 있는 경우 (데스크톱/모바일)
          try {
            final fileData = File(file.path!);
            fileBytes = await fileData.readAsBytes();
            print('경로에서 파일 읽기 성공: ${fileBytes.length} bytes');
          } catch (fileError) {
            print('파일 읽기 오류: $fileError');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('파일을 읽을 수 없습니다.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        }

        if (fileBytes != null && fileBytes.isNotEmpty) {
          setState(() {
            _selectedFileName = fullFileName;
            _documentName = documentName;
            _documentExtension = documentExtension;
            _fileBytes = fileBytes;
            _documentNameController.text = documentName; // 문서명 필드에 표시
          });

          print('파일 선택 완료: $fullFileName');
          print('문서명: $documentName, 확장자: $documentExtension');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('파일이 선택되었습니다: $fullFileName'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('파일 데이터를 읽을 수 없습니다.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        print('파일 선택이 취소되었습니다.');
      }
    } catch (e, stackTrace) {
      print('파일 선택 오류: $e');
      print('스택 트레이스: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('파일 선택 중 오류가 발생했습니다.\n오류: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 모달 제목
            const Text(
              '문서형식',
              style: TextStyle(
                color: Color(0xFF252525),
                fontSize: 18,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // 문서명 필드
            // 문서 선택 버튼
            Row(
              children: [
                Expanded(
                  child: CommonTextField(
                    label: '문서명',
                    controller: _documentNameController,
                    readOnly: true, // 읽기전용
                    hintText: '파일을 선택하면 자동으로 입력됩니다',
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 13),
                  child: SizedBox(
                    height: 34,
                    width: 130,
                    child: ElevatedButton(
                      onPressed: _selectFile, // 파일 선택 메서드 연결
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '문서 선택',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 문서종류 드롭다운
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildDropdownField(
                        label: '문서종류',
                        value: documentType,
                        items: _documentTypeList,
                        onChanged: (String? newValue) {
                          setState(() {
                            documentType = newValue!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 문서 종류 추가 버튼
                Padding(
                  padding: const EdgeInsets.only(top: 21),
                  child: SizedBox(
                    height: 34,
                    width: 130,
                    child: ElevatedButton(
                      onPressed: () {
                        _showAddDocumentTypeModal(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '문서 종류 추가',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 문서설명 필드 (멀티라인)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '문서설명',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _documentDescriptionController,
                  maxLines: 5,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1D1D1F),
                  ),
                  decoration: InputDecoration(
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    contentPadding: const EdgeInsets.all(12),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF007AFF),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 저장 폴더 열기
            buildCheckbox('저장 폴더 열기', _saveFilter, (value) {
              setState(() {
                _saveFilter = value ?? false;
              });
            }),
            const SizedBox(height: 24),
            // 문서첨부저장 버튼
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _uploadDocument, // 문서 업로드 메서드 연결
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '문서 첨부 저장',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 텍스트 필드 빌더
  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            style: const TextStyle(fontSize: 14, color: Color(0xFF252525)),
          ),
        ),
      ],
    );
  }
}

/// ========================================
/// 문서 종류 추가 모달
/// ========================================
class _AddDocumentTypeModal extends StatefulWidget {
  final VoidCallback onDocumentTypeAdded;

  const _AddDocumentTypeModal({super.key, required this.onDocumentTypeAdded});

  @override
  State<_AddDocumentTypeModal> createState() => _AddDocumentTypeModalState();
}

class _AddDocumentTypeModalState extends State<_AddDocumentTypeModal> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _codeNameController = TextEditingController();
  List<CodeData> _documentTypeList = [];

  @override
  void initState() {
    super.initState();
    _loadDocumentTypes();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeNameController.dispose();
    super.dispose();
  }

  /// 문서 종류 목록 로드 (캐시 무시하고 최신 데이터 조회)
  Future<void> _loadDocumentTypes() async {
    setState(() {});

    try {
      // 캐시 삭제하여 항상 최신 데이터 조회
      CodeDataCache.clearCacheForType('documenttype');

      final docTypeList = await loadDropdownData('documenttype');
      if (mounted) {
        setState(() {
          _documentTypeList = docTypeList;
        });
      }
    } catch (e) {
      print('문서 종류 로드 오류: $e');
      if (mounted) {
        setState(() {});
      }
    }
  }

  /// 문서 종류 삭제
  Future<void> _deleteDocumentType(String documentCode) async {
    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('문서 종류 삭제'),
        content: Text('문서종류코드 "$documentCode"를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // API 호출하여 문서 종류 삭제
    final success = await CodeDataCache.deleteCodeType(
      typeName: 'documenttype',
      code: documentCode,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('문서 종류가 삭제되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );

        await _loadDocumentTypes();
        widget.onDocumentTypeAdded();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('문서 종류 삭제에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 문서 종류 추가
  Future<void> _addDocumentType() async {
    final code = _codeController.text.trim();
    final codeName = _codeNameController.text.trim();
    // 유효성 검사
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('문서종류코드를 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (codeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('문서코드명을 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 3자리 숫자인지 확인
    if (code.length != 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('문서종류코드는 3자리여야 합니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 숫자만 입력되었는지 확인
    if (int.tryParse(code) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('문서종류코드는 숫자만 입력 가능합니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // API 호출하여 문서 종류 추가
    final success = await CodeDataCache.insertCode(
      typeName: 'documenttype',
      code: code,
      codeName: codeName,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('문서 종류가 추가되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );

        _codeController.clear();
        _codeNameController.clear();
        await _loadDocumentTypes();
        widget.onDocumentTypeAdded();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('문서 종류 추가에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 모달 제목
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '문서 종류 관리',
                  style: TextStyle(
                    color: Color(0xFF252525),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 문서종류코드와 문서코드명 입력 필드
            Row(
              children: [
                // 문서종류코드 입력 필드 (숫자 3자리)
                SizedBox(
                  width: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '문서종류코드',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 3,
                          decoration: InputDecoration(
                            hintText: '001',
                            hintStyle: const TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 14,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            filled: true,
                            fillColor: AppTheme.backgroundColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppTheme.dividerColor,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppTheme.dividerColor,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppTheme.selectedColor,
                                width: 1,
                              ),
                            ),
                            counterText: '', // 글자 수 카운터 숨기기
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 문서코드명 입력 필드
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '문서코드명',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _codeNameController,
                          decoration: InputDecoration(
                            hintText: '문서코드명을 입력하세요.',
                            hintStyle: const TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 14,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            filled: true,
                            fillColor: AppTheme.backgroundColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppTheme.dividerColor,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppTheme.dividerColor,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppTheme.selectedColor,
                                width: 1,
                              ),
                            ),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 문서 종류 추가 버튼
                Padding(
                  padding: const EdgeInsets.only(top: 13),
                  child: SizedBox(
                    height: 34,
                    width: 140,
                    child: ElevatedButton(
                      onPressed: _addDocumentType,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '문서코드명 추가',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 테이블 헤더
            const Text(
              '문서 종류 목록',
              style: TextStyle(
                color: Color(0xFF252525),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // 테이블
            Expanded(
              child: _documentTypeList.isEmpty
                  ? const Center(
                      child: Text(
                        '등록된 문서 종류가 없습니다.',
                        style: TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 14,
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFD9D9D9)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          // 테이블 헤더
                          Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: const Text(
                                      '문서종류코드',
                                      style: TextStyle(
                                        color: Color(0xFF252525),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 20,
                                  color: const Color(0xFFD9D9D9),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: const Text(
                                      '문서종류코드명',
                                      style: TextStyle(
                                        color: Color(0xFF252525),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 테이블 바디
                          Expanded(
                            child: ListView.builder(
                              itemCount: _documentTypeList.length,
                              itemBuilder: (context, index) {
                                final item = _documentTypeList[index];
                                return GestureDetector(
                                  onDoubleTap: () =>
                                      _deleteDocumentType(item.code),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color:
                                              index ==
                                                  _documentTypeList.length - 1
                                              ? Colors.transparent
                                              : const Color(0xFFD9D9D9),
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            child: Text(
                                              item.code,
                                              style: const TextStyle(
                                                color: Color(0xFF252525),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 1,
                                          height: 40,
                                          color: const Color(0xFFD9D9D9),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            child: Text(
                                              item.name,
                                              style: const TextStyle(
                                                color: Color(0xFF252525),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
