// Modal_Customer_List.dart
import 'package:flutter/material.dart';
import 'package:hansesecurity/globals.dart';

//거래처 선택
class CustomerList extends StatefulWidget {
  const CustomerList({super.key});

  @override
  State<CustomerList> createState() => _CustomerListState();
}

class _CustomerListState extends State<CustomerList> {
  late int Index;
  late String title;
  List<Map<String, String>> cusInfo = [];

  // 검색 관련 변수들
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> filteredCusList = [];

  @override
  void initState() {
    super.initState();
    // 초기에는 전체 리스트를 표시
    filteredCusList = List.from(cusList);

    // 검색 텍스트가 변경될 때마다 필터링
    _searchController.addListener(_filterCustomers);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCustomers);
    _searchController.dispose();
    super.dispose();
  }

  // 검색 필터링 함수
  void _filterCustomers() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        // 검색어가 비어있으면 전체 리스트 표시
        filteredCusList = List.from(cusList);
      } else {
        // 검색어가 있으면 필터링
        filteredCusList = cusList.where((customer) {
          final name = customer['name']?.toLowerCase() ?? '';
          return name.contains(query); // 검색어가 포함된 항목만 표시
        }).toList();
      }
    });
  }

  void onPressed(int index) {
    // filteredCusList에서 선택된 항목을 찾아서 원본 cusList의 인덱스를 찾기
    final selectedCustomer = filteredCusList[index];
    Navigator.pop(context, selectedCustomer);
    print(selectedCustomer);
    monnum = selectedCustomer['monnum'] ?? '';
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
                    '검색 결과: ${filteredCusList.length}개',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(filteredCusList.length, (index) { // filteredCusList 사용
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
                          filteredCusList[index]['name']!, // filteredCusList 사용
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