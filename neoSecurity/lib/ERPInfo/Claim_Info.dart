import 'package:flutter/material.dart';
import 'package:neosecurity/Modal/Modal_Claim_Filter.dart';
import 'package:neosecurity/Modal/Modal_Customer_List.dart';
import 'package:neosecurity/Modal/Modal_Sign_Filter.dart';
import 'package:neosecurity/Modal/Modal_page_List.dart';
import 'package:neosecurity/Select/Deposit_Select.dart';
import 'package:neosecurity/Select/ERP_Select.dart';
import 'package:neosecurity/globals.dart';
import '../RestAPI.dart';
import '../Select/Cus_Select.dart';
import '../functions.dart';

class ClaimInfo extends StatefulWidget {
  const ClaimInfo({super.key});
  @override
  State<ClaimInfo> createState() => _ClaimInfoState();
}

class _ClaimInfoState extends State<ClaimInfo> {
  String filterPeriod = periodList[claimPeriodIndex];
  String filterSortOrder = sortOrderList[claimSortOrderIndex];
  String filterDepositClass = depositList[depositClassIndex];
  String filterSalesClass = salesList[salesClassIndex];
  String filterClaimClass = claimClassList[claimClassIndex];

  @override
  void onPressed() async {
    final result = await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (BuildContext context) => const ModalClaimFilter(),
    );
    print(result);
    if (result != null) {
      setState(() {});
      filterPeriod = periodList[result[0]];
      filterSortOrder = sortOrderList[result[1]];
      filterDepositClass = depositList[result[2]];
      filterSalesClass = salesList[result[3]];
      filterClaimClass = claimClassList[result[4]];
      fetchClaim();
    }
  }

  @override
  void initState() {
    super.initState();
    fetchClaim();
  }

  Future<void> fetchClaim() async {
    try {
      claimList = await RestApiService().claimListRequest(
        syscode,
        yongnum,
        mi_checkChanger(claimClassIndex),
        phoneCode,
      );
      if (filterSortOrder == '과거순') {
        //역순정렬
        claimList = List.from(claimList.reversed);
      }

      if (filterDepositClass != '전체') {
        //입금방법
        claimList =
            claimList
                .where((item) => item["way"] == filterDepositClass)
                .toList();
      }

      if (filterSalesClass != '전체') {
        //매출종류
        claimList =
            claimList
                .where((item) => item["type"] == filterSalesClass)
                .toList();
      }

      setState(() {});

      print("claimList: $claimList");
    } catch (e) {
      print("API 호출 오류: $e");
    }
    print('청구api 호출됨');
  }

  @override
  Widget build(BuildContext context) {
    final groupedClaims = buildGrouped(claimList);
    //final groupedClaims = buildGrouped(claimList, 'claimdate');
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                ERPSelect(
                  onPressed: () {
                    setState(() {
                      fetchClaim();
                    });
                  },
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(filterSortOrder, style: TextStyle(fontSize: 16)),
                        SizedBox(width: 4), // 간격 추가
                        Text("·", style: TextStyle(fontSize: 16)),
                        SizedBox(width: 4), // 간격 추가
                        Text(
                          filterDepositClass,
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(width: 4), // 간격 추가
                        Text("·", style: TextStyle(fontSize: 16)),
                        SizedBox(width: 4), // 간격 추가
                        Text(filterSalesClass, style: TextStyle(fontSize: 16)),
                        SizedBox(width: 4), // 간격 추가
                        Text("·", style: TextStyle(fontSize: 16)),
                        SizedBox(width: 4), // 간격 추가
                        Text(filterClaimClass, style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    IconButton(
                      //필터 화면은 중복되니까 나중에 합쳐보기
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
                    itemCount: groupedClaims.length,
                    itemBuilder: (context, index) {
                      final element = groupedClaims[index];

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
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      item['claimdate'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      item['date'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xff888888),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  item['way'] ?? '',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item['type'] ?? '',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                Text(
                                  item['amount'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
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

  List<Map<String, dynamic>> buildGrouped(List<Map<String, String>> list) {
    final List<Map<String, dynamic>> result = [];
    String? lastMonth;

    for (var item in list) {
      final date = item['date'] ?? '';
      if (date.length < 7) {
        // 'date'가 비었거나 너무 짧으면 그냥 '기타' 같은 분류로 묶거나 건너뜀
        print("⚠️ 잘못된 날짜 형식: '$date'");
        result.add({'type': 'item', 'data': item});
        continue;
      }

      final month = date.substring(0, 7).replaceAll('-', '.');

      if (lastMonth != month) {
        result.add({'type': 'header', 'month': month});
        lastMonth = month;
      }

      result.add({'type': 'item', 'data': item});
    }

    return result;
  }

  String mi_checkChanger(int mi_check) {
    return mi_check == 0
        ? ''
        : mi_check == 1
        ? '0'
        : mi_check == 2
        ? '1'
        : '';
  }
}
