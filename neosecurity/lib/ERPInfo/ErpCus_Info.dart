import 'dart:async';

import 'package:flutter/material.dart';
import 'package:neosecurity/Select/ERP_Select.dart';
import '../RestAPI.dart';
import 'package:neosecurity/globals.dart';

class ERPCusInfo extends StatefulWidget {
  const ERPCusInfo({super.key});

  @override
  State<ERPCusInfo> createState() => _ERPCusInfoState();
}

class _ERPCusInfoState extends State<ERPCusInfo> {
  Timer? _dataCheckTimer;
  @override
  void initState() {
    erpinitializeData();
    _startDataMonitoring();
    super.initState();
  }

  @override
  void dispose() {
    _dataCheckTimer?.cancel();
    super.dispose();
  }

  void _startDataMonitoring() {
    int attemptCount = 0; // 시도 횟수 카운터 추가
    const int maxAttempts = 20; // 최대 시도 횟수

    _dataCheckTimer = Timer.periodic(Duration(milliseconds: 1000), (timer) {
      attemptCount++; // 시도 횟수 증가

      bool erpCusInfoListReady = erpCusInfoList.isNotEmpty;
      bool erpListReady = erpList.isNotEmpty;

      if (erpCusInfoListReady && erpListReady && mounted) {
        setState(() {
          // Select 위젯 업데이트를 위한 setState
        });
        // 데이터를 받았으므로 타이머 중지
        timer.cancel();
        print('모든 데이터 감지됨, Select 업데이트');
        print('erpCusInfoList 개수: ${erpCusInfoList.length}');
      } else if (attemptCount >= maxAttempts) {
        // 20번 시도 후에도 데이터가 없으면 타이머 중지
        timer.cancel();
        print('응답없음 - ${maxAttempts}번 시도 후 타임아웃');
        print(
          '최종 상태 - erpCusInfoListReady: $erpCusInfoListReady, erpListReady: $erpListReady',
        );
      } else {
        // 디버깅용 로그 (시도 횟수 포함)
        print(
          '데이터 대기 중 ($attemptCount/$maxAttempts) - erpCusInfoListReady: $erpCusInfoListReady, erpListReady: $erpListReady',
        );
      }
    });
  }

  Future<void> fetchErpCusInfo() async {
    try {
      final result = await RestApiService().erpCusInfoRequest(
        syscode,
        yongnum,
        phoneCode,
      );
      erpCusInfoList = result;
      setState(() {});
      //print("erpCusInfoList: ${erpCusInfoList}");
    } catch (e) {
      //print("API 호출 오류: $e");
    }
    print('api호출함');
  }

  Future<void> erpinitializeData() async {
    try {
      // 1단계: 먼저 고객 리스트 가져오기
      final erpcustomers = await RestApiService().erpCusListRequest(
        syscode,
        phoneCode,
      );
      erpList = erpcustomers;
      print('result$erpcustomers');
      //selectErpList = erpList[erpselectInt];
      yongnum = erpList[erpselectInt]['yongnum'] ?? '';

      // 2단계: 첫 번째 고객 또는 선택된 고객의 상태 정보 가져오기
      if (erpcustomers.isNotEmpty) {
        final yongnum = erpcustomers[0]['yongnum'] ?? '';
        if (yongnum.isNotEmpty) {
          final result = await RestApiService().erpCusInfoRequest(
            syscode,
            yongnum,
            phoneCode,
          );
          erpCusInfoList = result;
          //print("erpCusInfoList: ${erpCusInfoList}");
        }
      }
    } catch (e) {
      print('오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Column(
          children: [
            ERPSelect(
              onPressed: () {
                setState(() {
                  fetchErpCusInfo();
                });
              },
            ),

            const SizedBox(height: 15),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        '기본 정보',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        // color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),

                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '고객명',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Text(
                                erpCusInfoList.isNotEmpty
                                    ? erpCusInfoList[0]
                                    : '로딩 중...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '가입일자',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Text(
                                erpCusInfoList.isNotEmpty
                                    ? erpCusInfoList[1]
                                    : '로딩 중...',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '연락처',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Text(
                                erpCusInfoList.isNotEmpty
                                    ? erpCusInfoList[2]
                                    : '로딩 중...',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '납입방법',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Text(
                                erpCusInfoList.isNotEmpty
                                    ? erpCusInfoList[3]
                                    : '로딩 중...',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '청구금액',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Text(
                                erpCusInfoList.isNotEmpty
                                    ? erpCusInfoList[4]
                                    : '로딩 중...',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 50),

                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        '계산서정보',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        // color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),

                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '등록번호',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Text(
                                erpCusInfoList.isNotEmpty
                                    ? erpCusInfoList[5]
                                    : '로딩 중...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '상호',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Text(
                                erpCusInfoList.isNotEmpty
                                    ? erpCusInfoList[6]
                                    : '로딩 중...',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '성명',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Flexible(
                                child: Text(
                                  erpCusInfoList.isNotEmpty
                                      ? erpCusInfoList[7]
                                      : '로딩 중...',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '사업장주소',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Flexible(
                                child: Text(
                                  erpCusInfoList.isNotEmpty
                                      ? erpCusInfoList[8]
                                      : '로딩 중...',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '업태',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Text(
                                erpCusInfoList.isNotEmpty
                                    ? erpCusInfoList[9]
                                    : '로딩 중...',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '종목',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Text(
                                erpCusInfoList.isNotEmpty
                                    ? erpCusInfoList[10]
                                    : '로딩 중...',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '담당자',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Text(
                                erpCusInfoList.isNotEmpty
                                    ? erpCusInfoList[11]
                                    : '로딩 중...',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '핸드폰',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Text(
                                erpCusInfoList.isNotEmpty
                                    ? erpCusInfoList[12]
                                    : '로딩 중...',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '이메일',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Text(
                                erpCusInfoList.isNotEmpty
                                    ? erpCusInfoList[13]
                                    : '로딩 중...',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
