import 'package:flutter/material.dart';
import 'package:neosecurity/globals.dart';
import '../RestAPI.dart';
import '../Select/Cus_Select.dart';

class DvrInfo extends StatefulWidget {
  const DvrInfo({super.key});
  @override
  State<DvrInfo> createState() => _DvrInfostate();
}

class _DvrInfostate extends State<DvrInfo> {
  List<Map<String, String>> dvrList = [];

  @override
  void initState() {
    super.initState();
    fetchDvr();
  }

  void fetchDvr() async {
    try {
      dvrList = await RestApiService().dvrListRequest(
        syscode,
        monnum,
        phoneCode,
      );

      setState(() {});
    } catch (e) {
      //print("API 호출 오류: $e");
    }
    dvrList = dvrList;
  }

  @override
  Widget build(BuildContext context) {
    final groupedDvr = buildGroupedDvr(dvrList);
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Column(
              children: [
                CusSelect(
                  onPressed: () {
                    setState(() {
                      fetchDvr();
                    });
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'DVR 종류',
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
                                      '접속주소',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: groupedDvr.length,
                    itemBuilder: (context, index) {
                      final element = groupedDvr[index];
                      final item = element['data'] as Map<String, String>;
                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 20,
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
                                      item['dvrClass'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        const SizedBox(width: 5),
                                        Text(
                                          item['connectionIP'] ?? '',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
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

List<Map<String, dynamic>> buildGroupedDvr(List<Map<String, String>> dvr) {
  final List<Map<String, dynamic>> result = [];

  for (var item in dvr) {
    result.add({'type': 'item', 'data': item});
  }
  return result;
}
