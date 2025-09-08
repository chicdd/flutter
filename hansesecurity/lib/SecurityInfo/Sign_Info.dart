import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:hansesecurity/Modal/Modal_Sign_Filter.dart';
import 'package:hansesecurity/globals.dart';
import '../RestAPI.dart';
import '../Select/Cus_Select.dart';

class SignInfo extends StatefulWidget {
  const SignInfo({super.key});
  @override
  State<SignInfo> createState() => _SignInfoState();
}

class _SignInfoState extends State<SignInfo> {
  Timer? _dataCheckTimer;
  late String filterPeriod;
  late String filterSortOrder;
  late String filterClass;

  DateTime startDate = day_start;
  DateTime endDate = day_end;

  late Future<List<Map<String, String>>> _signalFuture;

  @override
  void initState() {
    super.initState();
    _initializeFilters();
    _refreshData();
    _startDataMonitoring();
  }

  @override
  void dispose() {
    _dataCheckTimer?.cancel();
    super.dispose();
  }

  void _startDataMonitoring() {
    int attemptCount = 0; // 시도 횟수 카운터 추가
    const int maxAttempts = 20; // 최대 시도 횟수

    _dataCheckTimer = Timer.periodic(const Duration(milliseconds: 1000), (
      timer,
    ) {
      attemptCount++; // 시도 횟수 증가

      // cusList, stateList, state 모두 체크
      bool signListReady = signList.isNotEmpty;

      if (signListReady && mounted) {
        setState(() {
          // Select 위젯 업데이트를 위한 setState
        });
        // 데이터를 받았으므로 타이머 중지
        timer.cancel();
      } else if (attemptCount >= maxAttempts) {
        // 20번 시도 후에도 데이터가 없으면 타이머 중지
        timer.cancel();
        print('응답없음 - ${maxAttempts}번 시도 후 타임아웃');
        print('최종 상태 - signList: $signListReady');
      } else {
        // 5회마다 fetchUserList 호출
        if (attemptCount % 5 == 0) {
          print('데이터 없음, ${attemptCount}회 시도 중 fetchUserList() 실행');
          _refreshData();
        }

        // 디버깅용 로그 (시도 횟수 포함)
        print(
          '데이터 대기 중 ($attemptCount/$maxAttempts) - signList: $signListReady',
        );
      }
    });
  }

  void _initializeFilters() {
    filterPeriod =
        (periodList.isNotEmpty && periodIndex < periodList.length)
            ? periodList[periodIndex]
            : '지정기간';

    filterSortOrder =
        (sortOrderList.isNotEmpty && sortOrderIndex < sortOrderList.length)
            ? sortOrderList[sortOrderIndex]
            : '최신순';

    filterClass =
        (signList.isNotEmpty && signIndex < signList.length)
            ? signList[signIndex]
            : '전체신호';
  }

  Future<List<Map<String, String>>> fetchSignal() async {
    try {
      print('API 호출 시작');

      List<Map<String, String>> tempSignalList = [];

      if (periodIndex == 0) {
        tempSignalList = await RestApiService().signListRequest(
          syscode,
          monnum,
          startDate.toString(),
          endDate.toString(),
          phoneCode,
        );
      } else {
        tempSignalList = await RestApiService().signListRequest(
          syscode,
          monnum,
          '2024-08-01 00:00:00.000000',
          endDate.toString(),
          phoneCode,
        );
      }
      if (filterSortOrder == '과거순') {
        tempSignalList = List.from(tempSignalList.reversed);
        print('역순정렬성공');
      }

      if (filterClass != '전체신호') {
        tempSignalList =
            tempSignalList
                .where((item) => item["signalName"] == filterClass)
                .toList();
      }

      print('API 호출 완료: ${tempSignalList.length}개 항목');
      print('tempSignalList$tempSignalList');
      return tempSignalList;
    } catch (e) {
      //print("API 호출 오류: $e");
      throw e; // FutureBuilder에서 에러 상태로 처리
    }
  }

  void _refreshData() {
    setState(() {
      _signalFuture = fetchSignal(); // 새로운 Future 생성
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
      builder: (BuildContext context) => const ModalSignFilter(),
    );

    if (result != null) {
      setState(() {
        filterPeriod =
            (periodList.isNotEmpty && result[0] < periodList.length)
                ? periodList[result[0]]
                : '지정기간';
        filterSortOrder =
            (sortOrderList.isNotEmpty && result[1] < sortOrderList.length)
                ? sortOrderList[result[1]]
                : '최신순';
        filterClass =
            (signList.isNotEmpty && result[2] < signList.length)
                ? signList[result[2]]
                : '전체신호';
        startDate = result[3];
        endDate = result[4];
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
              future: _signalFuture,
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
                final signalData = snapshot.data ?? [];

                if (signalData.isEmpty) {
                  return const Center(
                    child: Text(
                      '신호 데이터가 없습니다.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return _buildSignalList(signalData);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalList(List<Map<String, String>> signalData) {
    final groupedSigns = buildGrouped(signalData);
    final Map<String, List<Map<String, String>>> groupedMap = {};

    for (var element in groupedSigns) {
      if (element['type'] == 'header') {
        groupedMap[element['month']] = [];
      } else if (groupedMap.isNotEmpty) {
        final lastKey = groupedMap.keys.last;
        groupedMap[lastKey]!.add(element['data'] as Map<String, String>);
      }
    }

    return CustomScrollView(
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
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['date'] ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Icon(
                                //   isUnlock
                                //       ? Icons.lock_open_outlined
                                //       : Icons.lock_outline,
                                //   size: 20,
                                //   color:
                                //       isUnlock
                                //           ? const Color(0xfff32152)
                                //           : Colors.blue,
                                // ),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
    );
  }

  Widget _buildFilterHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Column(
        children: [
          CusSelect(
            onPressed: () {
              setState(() {
                _initializeFilters();
                _signalFuture = fetchSignal();
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

  List<Map<String, dynamic>> buildGrouped(List<Map<String, String>> list) {
    final List<Map<String, dynamic>> result = [];
    String? lastMonth;

    if (list.isEmpty) {
      return result;
    }

    for (var item in list) {
      final date = item['date'] ?? '';
      if (date.length < 7) {
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
}
