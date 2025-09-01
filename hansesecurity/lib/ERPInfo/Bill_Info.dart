import 'package:flutter/material.dart';
import 'package:hansesecurity/Modal/Modal_Bill_Filter.dart';
import 'package:hansesecurity/Select/ERP_Select.dart';
import 'package:hansesecurity/globals.dart';
import '../RestAPI.dart';
import '../functions.dart';

class BillInfo extends StatefulWidget {
  const BillInfo({super.key});
  @override
  State<BillInfo> createState() => _BillInfoState();
}

class _BillInfoState extends State<BillInfo> {
  late String filterPeriod;
  late String filterSortOrder;
  late String filterClass;

  late Future<List<Map<String, String>>> _billFuture;

  @override
  void initState() {
    super.initState();
    _initializeFilters();
    _billFuture = fetchBill(); // Future로 저장
  }

  void _initializeFilters() {
    filterPeriod =
        (periodList.isNotEmpty && billPeriodIndex < periodList.length)
            ? periodList[billPeriodIndex]
            : '전체기간';

    filterSortOrder =
        (sortOrderList.isNotEmpty && billSortOrderIndex < sortOrderList.length)
            ? sortOrderList[billSortOrderIndex]
            : '최신순';

    filterClass =
        (billClassList.isNotEmpty && billClassIndex < billClassList.length)
            ? billClassList[billClassIndex]
            : '전체';
  }

  Future<List<Map<String, String>>> fetchBill() async {
    try {
      print('계산서 API 호출 시작');

      List<Map<String, String>> tempBillList = await RestApiService()
          .billListRequest(syscode, yongnum, phoneCode);

      if (filterSortOrder == '과거순') {
        tempBillList = List.from(tempBillList.reversed);
        print('역순정렬성공');
      }

      if (filterClass != '전체') {
        tempBillList =
            tempBillList.where((item) => item["type"] == filterClass).toList();
      }

      print('계산서 API 호출 완료: ${tempBillList.length}개 항목');
      print('tempBillList: $tempBillList');
      return tempBillList;
    } catch (e) {
      //print("계산서 API 호출 오류: $e");
      throw e; // FutureBuilder에서 에러 상태로 처리
    }
  }

  void _refreshData() {
    setState(() {
      _billFuture = fetchBill(); // 새로운 Future 생성
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
      builder: (BuildContext context) => const ModalBillFilter(),
    );

    print(result);
    if (result != null && result is List<int>) {
      setState(() {
        filterPeriod = periodList[result[0]];
        filterSortOrder = sortOrderList[result[1]];
        filterClass = billClassList[result[2]];
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
              future: _billFuture,
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
                final billData = snapshot.data ?? [];

                if (billData.isEmpty) {
                  return const Center(
                    child: Text(
                      '계산서 데이터가 없습니다.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return _buildBillList(billData);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillList(List<Map<String, String>> billData) {
    final groupedBills = buildGrouped(billData, 'billdate');

    return SingleChildScrollView(
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
                              style: const TextStyle(
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
                _billFuture = fetchBill();
              });
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(filterPeriod, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  const Text("·", style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(filterSortOrder, style: const TextStyle(fontSize: 16)),
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
    );
  }
}
