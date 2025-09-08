import 'package:flutter/material.dart';
import 'package:hansesecurity/Modal/Modal_Claim_Filter.dart';
import 'package:hansesecurity/Select/ERP_Select.dart';
import 'package:hansesecurity/globals.dart';
import '../RestAPI.dart';

class ClaimInfo extends StatefulWidget {
  const ClaimInfo({super.key});
  @override
  State<ClaimInfo> createState() => _ClaimInfoState();
}

class _ClaimInfoState extends State<ClaimInfo> {
  late String filterPeriod;
  late String filterSortOrder;
  late String filterDepositClass;
  late String filterSalesClass;
  late String filterClaimClass;

  late Future<List<Map<String, String>>> _claimFuture;

  @override
  void initState() {
    super.initState();
    _initializeFilters();
    _claimFuture = fetchClaim(); // Future로 저장
  }

  void _initializeFilters() {
    filterPeriod =
        (periodList.isNotEmpty && claimPeriodIndex < periodList.length)
            ? periodList[claimPeriodIndex]
            : '전체기간';

    filterSortOrder =
        (sortOrderList.isNotEmpty && claimSortOrderIndex < sortOrderList.length)
            ? sortOrderList[claimSortOrderIndex]
            : '최신순';

    filterDepositClass =
        (depositList.isNotEmpty && depositClassIndex < depositList.length)
            ? depositList[depositClassIndex]
            : '전체';

    filterSalesClass =
        (salesList.isNotEmpty && salesClassIndex < salesList.length)
            ? salesList[salesClassIndex]
            : '전체';

    filterClaimClass =
        (claimClassList.isNotEmpty && claimClassIndex < claimClassList.length)
            ? claimClassList[claimClassIndex]
            : '전체';
  }

  Future<List<Map<String, String>>> fetchClaim() async {
    try {
      print('청구 API 호출 시작');

      List<Map<String, String>> tempClaimList = await RestApiService()
          .claimListRequest(
            syscode,
            yongnum,
            mi_checkChanger(claimClassIndex),
            phoneCode,
          );

      if (filterSortOrder == '과거순') {
        tempClaimList = List.from(tempClaimList.reversed);
        print('역순정렬성공');
      }

      if (filterDepositClass != '전체') {
        tempClaimList =
            tempClaimList
                .where((item) => item["way"] == filterDepositClass)
                .toList();
      }

      if (filterSalesClass != '전체') {
        tempClaimList =
            tempClaimList
                .where((item) => item["type"] == filterSalesClass)
                .toList();
      }

      print('청구 API 호출 완료: ${tempClaimList.length}개 항목');
      print('tempClaimList: $tempClaimList');
      return tempClaimList;
    } catch (e) {
      //print("청구 API 호출 오류: $e");
      throw e; // FutureBuilder에서 에러 상태로 처리
    }
  }

  void _refreshData() {
    setState(() {
      _claimFuture = fetchClaim(); // 새로운 Future 생성
    });
  }

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
      setState(() {
        filterPeriod = periodList[result[0]];
        filterSortOrder = sortOrderList[result[1]];
        filterDepositClass = depositList[result[2]];
        filterSalesClass = salesList[result[3]];
        filterClaimClass = claimClassList[result[4]];
      });
      _refreshData(); // 필터 변경 시 데이터 새로고침
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      body: Column(
        children: [
          _buildFilterHeader(),
          Expanded(
            child: FutureBuilder<List<Map<String, String>>>(
              future: _claimFuture,
              builder: (context, snapshot) {
                // 로딩 중
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 에러 발생
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('오류: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshData,
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  );
                }

                // 데이터 로드 완료
                final claimData = snapshot.data ?? [];

                if (claimData.isEmpty) {
                  return const Center(
                    child: Text(
                      '청구 데이터가 없습니다.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return _buildClaimList(claimData);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimList(List<Map<String, String>> claimData) {
    final groupedClaims = buildGrouped(claimData);

    return SingleChildScrollView(
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
                          style: const TextStyle(
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
    );
  }

  Widget _buildFilterHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Column(
        children: [
          ERPSelect(
            onPressed: () {
              setState(() {
                _initializeFilters();
                _claimFuture = fetchClaim();
              });
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(filterSortOrder, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  const Text("·", style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(
                    filterDepositClass,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  const Text("·", style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(filterSalesClass, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  const Text("·", style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(filterClaimClass, style: const TextStyle(fontSize: 16)),
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
    );
  }

  List<Map<String, dynamic>> buildGrouped(List<Map<String, String>> list) {
    final List<Map<String, dynamic>> result = [];
    String? lastMonth;

    for (var item in list) {
      final date = item['date'] ?? '';
      if (date.length < 7) {
        // 'date'가 비었거나 너무 짧으면 그냥 '기타' 같은 분류로 묶거나 건너뜀
        //print("⚠️ 잘못된 날짜 형식: '$date'");
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
