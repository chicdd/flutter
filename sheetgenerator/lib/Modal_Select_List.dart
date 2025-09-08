import 'package:flutter/material.dart';
import 'package:sheetgenerator/globals.dart';

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
  late int Index;
  late String title;
  late Future<List<Map<String, dynamic>>> _customerFuture;
  String selectClass = "";
  void _onItemSelected(int selectInt) {
    setState(() {});
    Navigator.pop(context, selectInt);
  }

  @override
  void initState() {
    super.initState();
    _customerFuture = RestApiService().fetch(widget.selectClass);
    //selectClass = matchingModel(widget.selectClass);
    print(_customerFuture);
    // switch (widget.selectClass) {
    //   case "Customer":
    //     _customerFuture = RestApiService().fetchCustomer().then((value) {
    //       customerList = value; // 전역 리스트에 저장
    //       return value;
    //     });
    //     break;
    //   case "Manager":
    //     _managerFuture = RestApiService().fetchManager().then((value) {
    //       managerList = value; // 전역 리스트에 저장
    //       return value;
    //     });
    //     break;
    //   default:
    //   //_futureList = Future.value([]); // 기본값
    // }
  }
  // void initState() {
  //   super.initState();
  //   _customerFuture = RestApiService().fetchCustomer().then((value) {
  //     globals.customerList = value; // 전역 리스트에 저장
  //     return value;
  //   });
  // }

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
                const Text(
                  '계산서 종류 선택',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // 버튼 목록
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _customerFuture, // ✅ 여기 수정
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('에러: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('데이터 없음'));
                  }

                  final list = snapshot.data!;
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final reslut = list[index][widget.selectDefault];
                      print(reslut);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: TextButton(
                          onPressed: () => _onItemSelected(index),
                          child: Text(
                            reslut.values.elementAt(1), // ✅ Map에서 name 키 꺼내기
                            style: const TextStyle(fontSize: 16),
                          ),
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
