import 'package:flutter/material.dart';
import '../models/document_info.dart';
import '../models/search_panel.dart';
import '../models/customer_detail.dart';
import '../services/api_service.dart';
import '../functions.dart';
import '../theme.dart';
import '../widgets/custom_top_bar.dart';
import '../widgets/common_table.dart';

/// 문서지원 화면
class DocumentSupport extends StatefulWidget {
  final SearchPanel? searchpanel;
  const DocumentSupport({super.key, this.searchpanel});

  @override
  State<DocumentSupport> createState() => DocumentSupportState();
}

class DocumentSupportState extends State<DocumentSupport>
    with CustomerServiceHandler {
  // 검색 컨트롤러
  final TextEditingController _searchController = TextEditingController();

  // 문서 데이터 목록
  List<DocumentInfo> _documents = [];

  // 페이지 내 검색
  String _pageSearchQuery = '';

  // 검색 쿼리 업데이트 메서드
  void updateSearchQuery(String query) {
    setState(() {
      _pageSearchQuery = query;
    });
  }

  @override
  void initState() {
    super.initState();
    // 공통 리스너 초기화
    initCustomerServiceListener();
    // 초기 데이터 로드
    _initializeData();
  }

  @override
  void dispose() {
    // 공통 리스너 해제
    disposeCustomerServiceListener();
    _searchController.dispose();
    super.dispose();
  }

  /// 초기 데이터 로드
  Future<void> _initializeData() async {
    // 서비스에서 고객 데이터 로드
    await _loadCustomerDataFromService();
  }

  /// 전역 서비스에서 고객 데이터 로드
  Future<void> _loadCustomerDataFromService() async {
    final customer = customerService.selectedCustomer;

    if (customer != null) {
      await _loadDocumentData(customer.controlManagementNumber);
    } else {
      setState(() {
        _documents = [];
      });
    }
  }

  /// CustomerServiceHandler 콜백 구현
  @override
  void onCustomerChanged(SearchPanel? customer, CustomerDetail? detail) {
    if (customer != null) {
      _loadDocumentData(customer.controlManagementNumber);
    } else {
      setState(() {
        _documents = [];
      });
    }
  }

  /// 문서 데이터 로드
  Future<void> _loadDocumentData(String managementNumber) async {
    try {
      final documentList = await DatabaseService.getDocumentInfo(
        managementNumber,
      );

      if (mounted) {
        setState(() {
          _documents = documentList;
        });
      }

      print('문서 데이터 로드 완료: ${documentList.length}개');
    } catch (e) {
      print('문서 데이터 로드 오류: $e');
      if (mounted) {
        setState(() {
          _documents = [];
        });
      }
    }
  }

  /// 문서 추가 모달 표시
  void _showAddDocumentModal() {
    showDialog(context: context, builder: (context) => _AddDocumentModal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // 상단바
          // 메인 컨텐츠
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Expanded(child: _buildTableSection())],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 테이블 섹션
  Widget _buildTableSection() {
    return CommonDataTable(
      title: '첨부 데이터 리스트',
      columns: [
        TableColumnConfig(
          header: '문서일련번호',
          flex: 1,
          valueBuilder: (data) => data.documentSerialNumber ?? '-',
          cellBuilder: (data, value) => Center(
            child: HighlightedText(
              text: value,
              query: _pageSearchQuery,
              style: const TextStyle(
                color: Color(0xFF252525),
                fontSize: 15,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        TableColumnConfig(
          header: '문서명',
          flex: 2,
          valueBuilder: (data) => data.documentName ?? '-',
          cellBuilder: (data, value) => Center(
            child: HighlightedText(
              text: value,
              query: _pageSearchQuery,
              style: const TextStyle(
                color: Color(0xFF252525),
                fontSize: 15,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        TableColumnConfig(
          header: '문서확장자',
          flex: 1,
          valueBuilder: (data) => data.documentExtension ?? '-',
          cellBuilder: (data, value) => Center(
            child: HighlightedText(
              text: value,
              query: _pageSearchQuery,
              style: const TextStyle(
                color: Color(0xFF252525),
                fontSize: 15,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        TableColumnConfig(
          header: '문서종류',
          flex: 1,
          valueBuilder: (data) => data.documentType ?? '-',
          cellBuilder: (data, value) => Center(
            child: HighlightedText(
              text: value,
              query: _pageSearchQuery,
              style: const TextStyle(
                color: Color(0xFF252525),
                fontSize: 15,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        TableColumnConfig(
          header: '문서설명',
          flex: 2,
          valueBuilder: (data) => data.documentDescription ?? '-',
          cellBuilder: (data, value) => Center(
            child: HighlightedText(
              text: value,
              query: _pageSearchQuery,
              style: const TextStyle(
                color: Color(0xFF252525),
                fontSize: 15,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        TableColumnConfig(
          header: '첨부일자',
          flex: 1,
          valueBuilder: (data) => data.attachmentDate ?? '-',
          cellBuilder: (data, value) => Center(
            child: HighlightedText(
              text: value,
              query: _pageSearchQuery,
              style: const TextStyle(
                color: Color(0xFF252525),
                fontSize: 15,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        TableColumnConfig(
          header: '첨부자',
          flex: 1,
          valueBuilder: (data) => data.attacher ?? '-',
          cellBuilder: (data, value) => Center(
            child: HighlightedText(
              text: value,
              query: _pageSearchQuery,
              style: const TextStyle(
                color: Color(0xFF252525),
                fontSize: 15,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
      data: _documents,
      emptyMessage: '문서 데이터가 없습니다.',
      headerAction: ElevatedButton(
        onPressed: _showAddDocumentModal,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF007AFF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          elevation: 0,
        ),
        child: const Text(
          '추가',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

/// 문서 추가 모달
class _AddDocumentModal extends StatefulWidget {
  const _AddDocumentModal({Key? key}) : super(key: key);

  @override
  State<_AddDocumentModal> createState() => _AddDocumentModalState();
}

class _AddDocumentModalState extends State<_AddDocumentModal> {
  // 폼 컨트롤러
  final TextEditingController _documentNameController =
      TextEditingController();
  final TextEditingController _documentDescriptionController =
      TextEditingController();

  // 문서종류 드롭다운
  String? _selectedDocumentType;
  final List<CodeData> _documentTypes = []; // TODO: API에서 로드

  // 체크박스 상태
  bool _saveFilter = false;

  // 선택된 파일 이름
  String? _selectedFileName;

  @override
  void dispose() {
    _documentNameController.dispose();
    _documentDescriptionController.dispose();
    super.dispose();
  }

  // 파일 선택 (실제 구현은 file_picker 패키지 필요)
  void _selectFile() {
    // TODO: file_picker 패키지를 사용하여 파일 선택
    setState(() {
      _selectedFileName = '관제프로그램 매뉴얼.docx'; // 임시 예시
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            const SizedBox(height: 20),
            // 문서명 필드
            _buildTextField('문서명', _documentNameController),
            const SizedBox(height: 12),
            // 문서 선택 버튼
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _selectedFileName ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF252525),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _selectFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                      const Text(
                        '문서종류',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedDocumentType,
                            hint: const Text(
                              '-',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF999999),
                              ),
                            ),
                            isExpanded: true,
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xFF666666),
                            ),
                            items: _documentTypes
                                .map((type) => DropdownMenuItem<String>(
                                      value: type.code,
                                      child: Text(
                                        type.name,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedDocumentType = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 문서 종류 추가 버튼
                Padding(
                  padding: const EdgeInsets.only(top: 26),
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: 문서 종류 추가 기능
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: TextField(
                    controller: _documentDescriptionController,
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF252525),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 저장 필터 체크박스
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _saveFilter,
                    onChanged: (value) {
                      setState(() {
                        _saveFilter = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFF007AFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '저장필터열기',
                  style: TextStyle(
                    color: Color(0xFF252525),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 문서첨부저장 버튼
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: 문서 저장 API 호출
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '문서첨부저장',
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
