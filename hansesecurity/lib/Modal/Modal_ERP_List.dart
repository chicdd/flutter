import 'package:flutter/material.dart';
import 'package:hansesecurity/globals.dart';

//거래처 선택
class ERPList extends StatefulWidget {
  const ERPList({super.key});

  @override
  State<ERPList> createState() => _ERPListState();
}

class _ERPListState extends State<ERPList> {
  late int Index;
  late String title;
  List<Map<String, String>> erpInfo = [];

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> filteredErpList = [];

  @override
  void initState() {
    super.initState();
    // 초기에는 전체 리스트를 표시
    filteredErpList = List.from(erpList);

    // 검색 텍스트가 변경될 때마다 필터링
    _searchController.addListener(_filterERPCustomers);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterERPCustomers);
    _searchController.dispose();
    super.dispose();
  }

  // 검색 필터링 함수
  void _filterERPCustomers() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        // 검색어가 비어있으면 전체 리스트 표시
        filteredErpList = List.from(erpList);
      } else {
        // 검색어가 있으면 필터링
        filteredErpList =
            erpList.where((erpCustomer) {
              final name = erpCustomer['name']?.toLowerCase() ?? '';
              return name.contains(query); // 검색어가 포함된 항목만 표시
            }).toList();
      }
    });
  }

  void onPressed(int index) {
    // filteredERPList에서 선택된 항목을 찾아서 원본 erpList의 인덱스를 찾기
    final selectedERPCustomer = filteredErpList[index];
    Navigator.pop(context, selectedERPCustomer);
    print(selectedERPCustomer);
    yongnum = selectedERPCustomer['yongnum'] ?? '';
  }

  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 16,
        right: 16,
      ),
      child: SizedBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '거래처 선택',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController, // 컨트롤러 추가
              decoration: const InputDecoration(
                hintText: '거래처명 검색', // 힌트 텍스트 수정
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Color(0xfff4f4f4),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 검색 결과 개수 표시 (선택사항)
            if (_searchController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '검색 결과: ${filteredErpList.length}개',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(filteredErpList.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: TextButton(
                        onPressed: () {
                          onPressed(index);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 10,
                          ),
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.transparent,
                          alignment: Alignment.centerLeft,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          filteredErpList[index]['name']!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
