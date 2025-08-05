import 'package:flutter/material.dart';
import 'package:generator/globals.dart' as globals;

import 'RestAPI.dart';

class SelectList extends StatefulWidget {
  final String selectClass;
  const SelectList({super.key, required this.selectClass});

  @override
  State<SelectList> createState() => _SelectListState();
}

class _SelectListState extends State<SelectList> {
  late int Index;
  late String title;
  late Future<List<globals.Customer>> _customerFuture;
  void _onItemSelected(int selectInt) {
    setState(() {});
    Navigator.pop(context, selectInt);
  }

  @override
  void initState() {
    super.initState();

    switch (widget.selectClass) {
      case "Customer":
        _customerFuture = RestApiService().fetchCustomer().then((value) {
          globals.customerList = value; // 전역 리스트에 저장
          return value;
        });
        break;
      // case "담당자명":
      //   _futureList = RestApiService().fetchManager();
      //   break;
      // default:
      //   _futureList = Future.value([]); // 기본값
    }
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
              child: FutureBuilder<List<globals.Customer>>(
                future: _customerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('에러: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('데이터 없음'));
                  }

                  final customers = snapshot.data!;
                  return ListView.builder(
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: TextButton(
                          onPressed: () {
                            _onItemSelected(index);
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
                            customer.name,
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
