import 'dart:io';

import 'package:appcheck/appcheck.dart';
import 'package:flutter/material.dart';
import 'package:hansesecurity/globals.dart';
import 'package:url_launcher/url_launcher.dart';
import '../RestAPI.dart';
import '../Select/Cus_Select.dart';

class DvrInfo extends StatefulWidget {
  const DvrInfo({super.key});
  @override
  State<DvrInfo> createState() => _DvrInfostate();
}

class _DvrInfostate extends State<DvrInfo> {
  List<Map<String, String>> dvrList = [];
  final appCheck = AppCheck();
  String result = "아직 확인 안 함";
  String launchResult = "앱 실행 대기중";
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

  Future<bool> _checkSkyrex() async {
    try {
      AppInfo? app;

      if (Platform.isIOS) {
        // iOS → URL Scheme 확인
        app = await appCheck.checkAvailability("skyrex://");
      } else if (Platform.isAndroid) {
        // Android → 패키지명 확인 (예시: kr.co.skyrex.viewer)
        app = await appCheck.checkAvailability("kr.co.skyrex.viewer");
      }

      bool installed = app != null;

      // 화면에 결과 표시
      setState(() {
        result = installed ? "설치됨 ✅" : "미설치 ❌";
      });

      return installed;
    } catch (e) {
      setState(() {
        result = "확인 오류 ⚠️: $e";
      });
      return false;
    }
  }

  Future<void> launchSkyrex() async {
    try {
      if (Platform.isIOS) {
        await appCheck.launchApp("skyrex://connect?ip=192.168.0.1&port=8080");
      } else if (Platform.isAndroid) {
        await appCheck.launchApp("skyrex://connect?ip=192.168.0.1&port=8080");
      }

      setState(() {
        launchResult = "SKYREX 실행됨 🚀";
      });
    } catch (e) {
      setState(() {
        launchResult = "실행 실패 ❌: $e";
      });
    }
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

                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        const SizedBox(width: 5),
                                        ElevatedButton(
                                          onPressed: () async {
                                            launchSkyrex();
                                          },
                                          //onPressed: launchSkyrex,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              side: BorderSide(
                                                color: Color(0xff545454),
                                              ),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            textStyle: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            shadowColor: Colors.black38,
                                            elevation: 4,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: const [
                                              Text(
                                                "영상 보기",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
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
                          ElevatedButton(
                            onPressed: _checkSkyrex,
                            child: const Text("Skyrex 설치 확인"),
                          ),
                          const SizedBox(height: 20),
                          Text(result, style: const TextStyle(fontSize: 18)),
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
