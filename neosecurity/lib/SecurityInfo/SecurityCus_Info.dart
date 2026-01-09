import 'dart:async';
import 'package:flutter/material.dart';
import '../RestAPI.dart';
import '../Select/Cus_Select.dart';
import 'package:neosecurity/globals.dart';

class SecurityCusInfo extends StatefulWidget {
  const SecurityCusInfo({super.key});

  @override
  State<SecurityCusInfo> createState() => _SecurityCusInfoState();
}

class _SecurityCusInfoState extends State<SecurityCusInfo> {
  Timer? _dataCheckTimer;
  void initState() {
    super.initState();
    fetchSecuBasic();
    fetchUserList();
    _startDataMonitoring();
  }

  @override
  void dispose() {
    _dataCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchSecuBasic() async {
    print('monnum$monnum');
    try {
      final result = await RestApiService().secuBasicRequest(
        syscode,
        monnum,
        phoneCode,
      );
      print('result$result');
      secuBasicList = result;

      if (result.isNotEmpty) {
        if (monnum.isNotEmpty) {
          stateList = await RestApiService().currentStateRequest(
            syscode,
            monnum,
            phoneCode,
          );
          // state 정보 사용
          state = stateList['state'] ?? '';
          print('state$state');
          print('monnum$monnum');
          print('isremote$isremote');
        }
      }

      //print("globals.secuBasicList: ${secuBasicList}");
    } catch (e) {
      //print("API 호출 오류: $e");
    }
    print('api호출함');
  }

  Future<void> fetchUserList() async {
    final result = await RestApiService().userListRequest(
      syscode,
      monnum,
      phoneCode,
    );
    userList = result;
    setState(() {});
  }

  void _startDataMonitoring() {
    int attemptCount = 0; // 시도 횟수 카운터 추가
    const int maxAttempts = 20; // 최대 시도 횟수

    _dataCheckTimer = Timer.periodic(Duration(milliseconds: 1000), (timer) {
      attemptCount++; // 시도 횟수 증가

      // cusList, stateList, state 모두 체크
      bool secuBasicListReady = secuBasicList.isNotEmpty;
      bool userListReady = userList.isNotEmpty;

      if (secuBasicListReady && userListReady && mounted) {
        setState(() {
          // Select 위젯 업데이트를 위한 setState
        });
        // 데이터를 받았으므로 타이머 중지
        timer.cancel();
        print('모든 데이터 감지됨, Select 업데이트');
        print('cusList 개수: ${cusList.length}');
      } else if (attemptCount >= maxAttempts) {
        // 20번 시도 후에도 데이터가 없으면 타이머 중지
        timer.cancel();
        print('응답없음 - ${maxAttempts}번 시도 후 타임아웃');
        fetchSecuBasic();
        fetchUserList();
        print(
          '최종 상태 - secuBasicListReady: $secuBasicListReady, userListReady: $userListReady',
        );
      } else {
        // 디버깅용 로그 (시도 횟수 포함)
        print(
          '데이터 대기 중 ($attemptCount/$maxAttempts) - secuBasicListReady: $secuBasicListReady, userListReady: $userListReady',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Column(
          children: [
            CusSelect(
              onPressed: () {
                setState(() {
                  fetchSecuBasic();
                  fetchUserList();
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
                        '기본 가입 정보',
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
                                secuBasicList.isNotEmpty
                                    ? secuBasicList[0]
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
                                secuBasicList.length > 1
                                    ? secuBasicList[1]
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
                        '사용자',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Column(
                      children:
                          (userList ?? []).map<Widget>((user) {
                            return Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 30,
                                    horizontal: 10,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        user['name'] ?? '로드 실패',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        user['phone'] ?? '로드 실패',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                                Divider(
                                  thickness: 1,
                                  height: 1,
                                  color: Color(0xffdfdfdf),
                                ),
                              ],
                            );
                          }).toList(),
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
