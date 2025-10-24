import 'package:flutter/material.dart';

class CodeSettingScreen extends StatefulWidget {
  const CodeSettingScreen({super.key});

  @override
  State<CodeSettingScreen> createState() => _CodeSettingScreenState();
}

class _CodeSettingScreenState extends State<CodeSettingScreen> {
  int _selectedTabIndex = 0;
  int _selectedCodeIndex = -1;
  bool _isNewMode = false;

  final List<String> _tabs = [
    '계약종류',
    '전환구분',
    '회선구분',
    '사용자정의A',
    '사용자정의B',
    '주장치',
    '지사',
    '권역',
    '업종분류',
    '계약분류',
  ];

  final Map<String, List<Map<String, String>>> _tabData = {
    '계약종류': [
      {'code': '001', 'name': '직접영업'},
      {'code': '002', 'name': '간접영업'},
      {'code': '003', 'name': '사원판매'},
      {'code': '004', 'name': '자문위원'},
      {'code': '005', 'name': '상으톰'},
      {'code': '006', 'name': '미관'},
    ],
    '전환구분': [
      {'code': '001', 'name': '신규'},
      {'code': '002', 'name': '전환'},
    ],
    '회선구분': [
      {'code': '001', 'name': '유선'},
      {'code': '002', 'name': '무선'},
    ],
    '사용자정의A': [],
    '사용자정의B': [],
    '주장치': [],
    '지사': [],
    '권역': [],
    '업종분류': [],
    '계약분류': [],
  };

  final _codeController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String get _currentTab => _tabs[_selectedTabIndex];
  List<Map<String, String>> get _currentData => _tabData[_currentTab]!;

  void _selectCode(int index) {
    setState(() {
      _selectedCodeIndex = index;
      _isNewMode = false;
      _codeController.text = _currentData[index]['code']!;
      _nameController.text = _currentData[index]['name']!;
    });
  }

  void _startNewMode() {
    setState(() {
      _selectedCodeIndex = -1;
      _isNewMode = true;
      _codeController.clear();
      _nameController.clear();
    });
  }

  void _saveData() {
    if (_nameController.text.isEmpty) {
      _showMessage('${_currentTab}명을 입력해주세요');
      return;
    }

    setState(() {
      if (_isNewMode) {
        // 신규 추가: 자동으로 코드 생성
        final newCode = (_currentData.length + 1).toString().padLeft(3, '0');
        _currentData.add({'code': newCode, 'name': _nameController.text});
        _showMessage('새 항목이 추가되었습니다');
        _isNewMode = false;
        _codeController.clear();
        _nameController.clear();
      } else if (_selectedCodeIndex >= 0) {
        // 수정 모드
        _currentData[_selectedCodeIndex]['name'] = _nameController.text;
        _showMessage('데이터가 저장되었습니다');
      }
    });
  }

  void _deleteData() {
    if (_selectedCodeIndex < 0) {
      _showMessage('삭제할 항목을 선택해주세요');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('삭제 확인'),
        content: const Text('선택한 항목을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentData.removeAt(_selectedCodeIndex);
                _selectedCodeIndex = -1;
                _codeController.clear();
                _nameController.clear();
              });
              _showMessage('데이터가 삭제되었습니다');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F7),
      child: Row(
        children: [
          // 좌측 세로 탭 메뉴
          Container(
            width: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: ListView.builder(
              itemCount: _tabs.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedTabIndex == index;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedTabIndex = index;
                      _selectedCodeIndex = -1;
                      _isNewMode = false;
                      _codeController.clear();
                      _nameController.clear();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE3F2FD)
                          : Colors.transparent,
                      border: Border(
                        left: BorderSide(
                          color: isSelected
                              ? const Color(0xFF007AFF)
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      _tabs[index],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? const Color(0xFF007AFF)
                            : const Color(0xFF86868B),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // 우측 콘텐츠
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 상단 테이블
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F7),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Expanded(
                                  flex: 1,
                                  child: Text(
                                    '기본코드',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    '$_currentTab명',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: Colors.grey.shade300),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _currentData.length,
                              itemBuilder: (context, index) {
                                final item = _currentData[index];
                                final isSelected = _selectedCodeIndex == index;
                                return InkWell(
                                  onTap: () => _selectCode(index),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFE3F2FD)
                                          : Colors.transparent,
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            item['code']!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            item['name']!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                            ),
                                            textAlign: TextAlign.center,
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
                  const SizedBox(height: 16),
                  // 하단 입력 폼
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_currentTab 정보',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: _buildInputField(
                                '기본코드',
                                _codeController,
                                readOnly: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: _buildInputField(
                                '$_currentTab명',
                                _nameController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: _deleteData,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                              child: const Text(
                                '데이터 삭제',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _saveData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF007AFF),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                              child: const Text(
                                '데이터 저장',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _startNewMode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF34C759),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                              child: const Text(
                                '신규추가시작',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF86868B),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            filled: true,
            fillColor: readOnly ? const Color(0xFFF5F5F7) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
