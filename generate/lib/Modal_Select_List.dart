import 'package:flutter/material.dart';
import 'package:generate/globals.dart' as globals;
import 'RestAPI.dart';

class SelectList extends StatefulWidget {
  final String selectClass;
  final String selectDefault;

  const SelectList({
    super.key,
    required this.selectClass,
    required this.selectDefault,
  });

  @override
  State<SelectList> createState() => _SelectListState();
}

class _SelectListState extends State<SelectList> {
  late Future<List<globals.DynamicModel>> _model;
  String ListName = "";
  @override
  void initState() {
    super.initState();

    ListName = customerNameCreator(widget.selectClass);
    String listKey = customerNameCreator(widget.selectClass);
    List<Map<String, String>> selectedList =
        globals.globalListMap[listKey] ?? [];

    loadAndStoreData(widget.selectClass);

    print(
      widget.selectClass +
          " : " +
          globals.globalListMap[widget.selectClass].toString(),
    );

    if (widget.selectDefault == '담당자 선택') {
      filterCustomer();
    }
  }

  void loadAndStoreData(String className) async {
    List<globals.DynamicModel> models = await RestApiService().fetch(className);

    // DynamicModel -> Map<String, String> 변환
    List<Map<String, String>> parsedList = models.map((e) => e.data).toList();

    // Map에 저장
    globals.globalListMap[className] = parsedList;
  }

  void _onItemSelected(int selectIndex) {
    Navigator.pop(context, selectIndex);
    print('선택된 인덱스: $selectIndex');
    setState(() {
      globals.selectIndex = customerCodeCreator(selectIndex);
      print('globals.selectIndex${globals.selectIndex}');
    });
  }

  String customerCodeCreator(int selectIndex) {
    selectIndex = selectIndex + 1;
    return '00$selectIndex';
  }

  String customerNameCreator(String modelName) {
    return modelName; // 이제 'customer' 또는 'manager' 반환
  }

  void filterCustomer() async {
    final list = await _model;

    final filtered = list
        .where((item) => item.data["거래처코드"] == globals.selectIndex)
        .toList();

    // 한글 가나다순 정렬 (예: 이름 키 기준)
    filtered.sort((a, b) {
      final aValue = a.data["담당자명"] ?? '';
      final bValue = b.data["담당자명"] ?? '';
      return aValue.compareTo(bValue); // 가나다순 정렬
    });

    setState(() {
      _model = Future.value(filtered);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 16,
        right: 16,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.selectDefault,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 리스트
            Expanded(
              child: FutureBuilder<List<globals.DynamicModel>>(
                future: _model,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('에러: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('데이터 없음'));
                  }

                  final items = snapshot.data!;
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return TextButton(
                        onPressed: () => _onItemSelected(index),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 10,
                          ),
                          foregroundColor: Colors.black,
                          alignment: Alignment.centerLeft,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          item.data.entries.length > 1
                              ? item.data.entries.toList()[1].value
                              : '값 없음',
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
