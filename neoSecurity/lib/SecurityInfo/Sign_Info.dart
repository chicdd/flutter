import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:neosecurity/Modal/Modal_Customer_List.dart';
import 'package:neosecurity/Modal/Modal_Sign_Filter.dart';
import 'package:neosecurity/globals.dart' as globals;
import '../RestAPI.dart';
import '../Select/Cus_Select.dart';
import '../functions.dart';

class SignInfo extends StatefulWidget {
  const SignInfo({super.key});
  @override
  State<SignInfo> createState() => _SignInfoState();
}

class _SignInfoState extends State<SignInfo> {
  String filterPeriod = globals.periodList[globals.periodIndex];
  String filterSortOrder = globals.sortOrderList[globals.sortOrderIndex];
  String filterClass = globals.signList[globals.signIndex];

  DateTime startDate = globals.day_start; // 시작 날짜
  DateTime endDate = globals.day_end; // 종료 날짜

  List<Map<String, String>> signalList = globals.signalList;
  @override
  void onPressed() async {
    final result = await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (BuildContext context) => const ModalSignFilter(),
    );
    print(result);
    if (result != null) {
      filterPeriod = globals.periodList[result[0]];
      filterSortOrder = globals.sortOrderList[result[1]];
      filterClass = globals.signList[result[2]];
      startDate = result[3];
      endDate = result[4];
      fetchSignal();
    }
  }

  @override
  void initState() {
    super.initState();
    if (signalList.isEmpty) {
      fetchSignal(); // signalList에 값이 없을 때만 호출
    }
  }

  @override
  //최초에만 1회 발생
  Future<void> fetchSignal() async {
    try {
      if (globals.periodIndex == 0) {
        signalList = await RestApiService().signListRequest(
          globals.syscode,
          globals.monnum,
          startDate.toString(),
          endDate.toString(),
          globals.phoneCode,
        );
      } else {
        //필터 전체기간 선택 시
        signalList = await RestApiService().signListRequest(
          globals.syscode,
          globals.monnum,
          '2024-08-01 00:00:00.000000', //한세시큐리티의 가장 오래된 수신신호테이블명 2024-08-01 00:00:00.000000 입력 해 놓으면 엄청 서버부하됨..
          endDate.toString(),
          globals.phoneCode,
        );
      }

      if (filterSortOrder == '과거순') {
        signalList = List.from(signalList.reversed);
        print(signalList);
        print('역순정렬성공');
      }

      if (filterClass != '전체신호') {
        signalList =
            signalList
                .where((item) => item["signalName"] == filterClass)
                .toList();
      }
      setState(() {});
    } catch (e) {
      print("API 호출 오류: $e");
    }
    print('api호출함');
    globals.signalList = signalList;
  }

  @override
  Widget build(BuildContext context) {
    final groupedSigns = buildGrouped(signalList);
    final Map<String, List<Map<String, String>>> groupedMap = {};

    for (var element in groupedSigns) {
      if (element['type'] == 'header') {
        groupedMap[element['month']] = [];
      } else {
        final lastKey = groupedMap.keys.last;
        groupedMap[lastKey]!.add(element['data'] as Map<String, String>);
      }
    }

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
                    setState(() {});
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          filterPeriod,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 4),
                        const Text("·", style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(
                          filterSortOrder,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 4),
                        const Text("·", style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(filterClass, style: const TextStyle(fontSize: 16)),
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
            child: CustomScrollView(
              slivers:
                  groupedMap.entries.map((entry) {
                    final month = entry.key;
                    final items = entry.value;

                    return SliverStickyHeader(
                      header: Container(
                        height: 50,
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          month,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = items[index];
                          final isUnlock = item['icon'] == 'open';

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 30,
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item['date'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Icon(
                                          isUnlock
                                              ? Icons.lock_open_outlined
                                              : Icons.lock_outline,
                                          size: 20,
                                          color:
                                              isUnlock
                                                  ? const Color(0xfff32152)
                                                  : Colors.blue,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          item['signalName'] ?? '',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color:
                                                isUnlock
                                                    ? const Color(0xfff32152)
                                                    : Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item['time'] ?? '',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      item['user'] ?? '',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }, childCount: items.length),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> buildGrouped(List<Map<String, String>> list) {
    final List<Map<String, dynamic>> result = [];
    String? lastMonth;

    for (var item in list) {
      final date = item['date'] ?? '';
      final month = date.substring(0, 7).replaceAll('-', '.');

      if (lastMonth != month) {
        result.add({'type': 'header', 'month': month});
        lastMonth = month;
      }

      result.add({'type': 'item', 'data': item});
    }

    return result;
  }
}
