import 'package:flutter/material.dart';
import 'package:neosecurity/Modal/Modal_Bill_Filter.dart';
import 'package:neosecurity/Modal/Modal_Customer_List.dart';
import 'package:neosecurity/globals.dart' as globals;
import '../RestAPI.dart';
import '../Select/Cus_Select.dart';
import '../functions.dart';

class BillInfo extends StatefulWidget {
  const BillInfo({super.key});
  @override
  State<BillInfo> createState() => _BillInfoState();
}

class _BillInfoState extends State<BillInfo> {
  String filterPeriod = globals.periodList[globals.billPeriodIndex];
  String filterSortOrder = globals.sortOrderList[globals.billSortOrderIndex];
  String filterClass = globals.billClassList[globals.billClassIndex];
  List<Map<String, String>> billList = globals.billList;
  @override
  void onPressed() async {
    final result = await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (BuildContext context) => const ModalBillFilter(),
    );
    print(result);
    if (result != null && result is List<int>) {
      setState(() {});
      filterPeriod = globals.periodList[result[0]];
      filterSortOrder = globals.sortOrderList[result[1]];
      filterClass = globals.billClassList[result[2]];
      fetchBill();
    }
  }

  @override
  void initState() {
    super.initState();
    if (billList.isEmpty) {
      fetchBill();
    }
  }

  Future<void> fetchBill() async {
    try {
      billList = await RestApiService().billListRequest(
        globals.syscode,
        globals.yongnum,
        globals.phoneCode,
      );

      if (filterSortOrder == '과거순') {
        //역순정렬
        billList = List.from(billList.reversed);
      }

      if (filterClass != '전체') {
        //매출종류
        billList =
            billList.where((item) => item["type"] == filterClass).toList();
      }

      setState(() {});

      print("globals.billList: $billList");
    } catch (e) {
      print("API 호출 오류: $e");
    }
    print('계산서api 호출됨');
    globals.billList = billList;
  }

  @override
  Widget build(BuildContext context) {
    final groupedBills = buildGrouped(billList, 'billdate');
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CusSelect(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      backgroundColor: Colors.white,
                      isScrollControlled: true,
                      builder: (BuildContext context) => CustomerList(),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(filterPeriod, style: TextStyle(fontSize: 16)),
                        SizedBox(width: 4), // 간격 추가
                        Text("·", style: TextStyle(fontSize: 16)),
                        SizedBox(width: 4), // 간격 추가
                        Text(filterSortOrder, style: TextStyle(fontSize: 16)),
                        SizedBox(width: 4), // 간격 추가
                        Text("·", style: TextStyle(fontSize: 16)),
                        SizedBox(width: 4), // 간격 추가
                        Text(filterClass, style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune),
                      onPressed: onPressed,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: groupedBills.length,
                    itemBuilder: (context, index) {
                      final element = groupedBills[index];

                      if (element['type'] == 'header') {
                        return SizedBox(
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Text(
                              element['month'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        );
                      }

                      final item = element['data'] as Map<String, String>;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 30,
                        ),
                        decoration: const BoxDecoration(color: Colors.white),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item['billdate'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const SizedBox(width: 5),
                                    Text(
                                      item['name'] ?? '',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item['type'] ?? '',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                Text(
                                  item['amount'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 1. 월별로 billHistory 그룹화
