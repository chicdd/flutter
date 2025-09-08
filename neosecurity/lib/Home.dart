import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:neosecurity/SecurityInfo/Security_Home.dart';
import 'package:neosecurity/Setting.dart';

import 'package:url_launcher/url_launcher.dart';

import 'Select/Cus_Select.dart';
import 'functions.dart';
import 'globals.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Timer? _timer;
  Timer? _dataCheckTimer;
  late String title = '타이틀 없음';

  void _startDataMonitoring() {
    int attemptCount = 0; // 시도 횟수 카운터 추가
    const int maxAttempts = 20; // 최대 시도 횟수

    _dataCheckTimer = Timer.periodic(const Duration(milliseconds: 1000), (
      timer,
    ) {
      attemptCount++; // 시도 횟수 증가

      // cusList, stateList, state 모두 체크
      bool cusListReady = cusList.isNotEmpty;
      bool stateListReady = stateList.isNotEmpty;
      bool stateReady = state.isNotEmpty;

      if (cusListReady && stateListReady && stateReady && mounted) {
        setState(() {
          // Select 위젯 업데이트를 위한 setState
        });
        // 데이터를 받았으므로 타이머 중지
        timer.cancel();
        print('모든 데이터 감지됨, Select 업데이트');
        print('cusList 개수: ${cusList.length}');
        print('stateList: $stateList');
        print('state: $state');
        UiChanger(state);
        selectedOption = stateMatchingModel[stateList['state']] ?? '';
      } else if (attemptCount >= maxAttempts) {
        // 20번 시도 후에도 데이터가 없으면 타이머 중지
        timer.cancel();
        print('응답없음 - ${maxAttempts}번 시도 후 타임아웃');
        initializeData();
        print(
          '최종 상태 - cusList: $cusListReady, stateList: $stateListReady, state: $stateReady',
        );
      } else {
        // 5회마다 fetchUserList 호출
        if (attemptCount % 5 == 0) {
          print('데이터 없음, ${attemptCount}회 시도 중 fetchUserList() 실행');
          initializeData();
        }

        // 디버깅용 로그 (시도 횟수 포함)
        print(
          '데이터 대기 중 ($attemptCount/$maxAttempts) - cusList: $cusListReady, stateList: $stateListReady, state: $stateReady',
        );
      }
    });
  }

  void initState() {
    super.initState();
    _startDataMonitoring();
    setState(() {});

    //10초마다 setState 호출
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      setState(() {
        getState();
        state = stateMatchingModel[stateList['state']] ?? '';
      });
      print('globals.stateList${stateList}');

      //print("_selectedOption" + state);
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // 꼭 해제해 주세요!
    _dataCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: const Text(
            '시큐리티 정보',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        shadowColor: Colors.transparent,
      ),
      backgroundColor: const Color(0xfff7f7f7),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Column(
          children: [
            CusSelect(
              title: "",
              onPressed: () {
                setState(() {
                  print('stateList[state]' + stateList['state'].toString());
                });
                UiChanger(state);
              },
            ),

            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.asset(
                          getImagePath(stateList['state']),
                          fit: BoxFit.cover, // 필요에 따라 추가
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.0),
                      child: Row(
                        children: [
                          command('경계'),
                          const SizedBox(width: 10),
                          command('해제'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Padding(
                    //   padding: const EdgeInsets.symmetric(horizontal: 0.0),
                    //   child: Row(
                    //     children: [
                    //       command('문열림'),
                    //       const SizedBox(width: 10),
                    //       command('문닫힘'),
                    //     ],
                    //   ),
                    // ),
                    // const SizedBox(height: 10),
                    Row(
                      children: [
                        if (isremote == 'true') ...[
                          Expanded(
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  String result = await receiveRemote();
                                  if (result == "1") {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('원격요청되었습니다.'),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('원격오류. 관리자에게 문의하세요.'),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xff2196f3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  textStyle: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  shadowColor: Colors.transparent,
                                ),
                                child: const Text('원격요청'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],

                        if (centerPhone != "")
                          Expanded(
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  launchUrl(
                                    Uri(scheme: 'tel', path: centerPhone),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Color(0xff545454)),
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.phone, color: Colors.black54),
                                    SizedBox(width: 12),
                                    Text(
                                      "관제실 통화",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SecurityHome(),
                                ),
                              );
                              dispose();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                //side: BorderSide(color: Color(0xff545454)),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 0),
                              textStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              shadowColor: Colors.transparent,
                              elevation: 4,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.security,
                                  size: 30,
                                  color: Colors.black54,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  "관제정보",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const Setting(),
                                ),
                              );
                              dispose();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                //side: BorderSide(color: Color(0xff545454)),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 0),
                              textStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              shadowColor: Colors.transparent,
                              elevation: 4,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.settings,
                                  size: 30,
                                  color: Colors.black54,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  "환경설정",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  //const SizedBox(height: 20),

                  // Row(
                  //   children: [
                  //     Expanded(
                  //       child: SizedBox(
                  //         width: double.infinity,
                  //         child: ElevatedButton(
                  //           onPressed: () async {
                  //             Navigator.push(
                  //               context,
                  //               MaterialPageRoute(
                  //                 builder: (context) => const Notice(),
                  //               ),
                  //             );
                  //             dispose();
                  //           },
                  //           style: ElevatedButton.styleFrom(
                  //             backgroundColor: Colors.white,
                  //             shape: RoundedRectangleBorder(
                  //               borderRadius: BorderRadius.circular(12),
                  //               //side: BorderSide(color: Color(0xff545454)),
                  //             ),
                  //             padding: const EdgeInsets.symmetric(vertical: 0),
                  //             textStyle: TextStyle(
                  //               fontSize: 16,
                  //               fontWeight: FontWeight.w500,
                  //             ),
                  //             shadowColor: Colors.transparent,
                  //             elevation: 4,
                  //           ),
                  //           child: Column(
                  //             mainAxisAlignment: MainAxisAlignment.center,
                  //             children: [
                  //               Icon(
                  //                 Icons.campaign,
                  //                 size: 30,
                  //                 color: Colors.black54,
                  //               ),
                  //               SizedBox(width: 12),
                  //               Text(
                  //                 "공지사항",
                  //                 style: TextStyle(
                  //                   fontSize: 14,
                  //                   color: Colors.black54,
                  //                 ),
                  //               ),
                  //             ],
                  //           ),
                  //         ),
                  //       ),
                  //     ),
                  //
                  //
                  //     const SizedBox(width: 10),
                  //     Expanded(
                  //       child: SizedBox(
                  //         width: double.infinity,
                  //         child: ElevatedButton(
                  //           //로그인된 휴대폰번호로 영업고객이 있는지 확인하고 API에서 들고온 정보가 없으면 오류메세지
                  //           onPressed: () async {
                  //             () async {
                  //               bool isConfirmed = await RestApiService()
                  //                   .isERPUserConfirm(syscode, phoneCode);
                  //
                  //               if (!isConfirmed) {
                  //                 ScaffoldMessenger.of(context).showSnackBar(
                  //                   const SnackBar(
                  //                     content: Text('등록된 영업고객이 없습니다.'),
                  //                   ),
                  //                 );
                  //               } else {
                  //                 //검증 모두 통과하면
                  //                 Navigator.push(
                  //                   context,
                  //                   MaterialPageRoute(
                  //                     builder: (context) => const ErpHome(),
                  //                   ),
                  //                 );
                  //                 dispose();
                  //               }
                  //             }();
                  //           },
                  //           style: ElevatedButton.styleFrom(
                  //             backgroundColor: Colors.white,
                  //             shape: RoundedRectangleBorder(
                  //               borderRadius: BorderRadius.circular(12),
                  //               //side: BorderSide(color: Color(0xff545454)),
                  //             ),
                  //             padding: const EdgeInsets.symmetric(vertical: 0),
                  //             textStyle: TextStyle(
                  //               fontSize: 16,
                  //               fontWeight: FontWeight.w500,
                  //             ),
                  //             shadowColor: Colors.transparent,
                  //             elevation: 4,
                  //           ),
                  //           child: Column(
                  //             mainAxisAlignment: MainAxisAlignment.center,
                  //             children: [
                  //               Icon(
                  //                 Icons.bar_chart,
                  //                 size: 30,
                  //                 color: Colors.black54,
                  //               ),
                  //               SizedBox(width: 12),
                  //               Text(
                  //                 "영업정보",
                  //                 style: TextStyle(
                  //                   fontSize: 14,
                  //                   color: Colors.black54,
                  //                 ),
                  //               ),
                  //             ],
                  //           ),
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  //라디오버튼
  Widget command(String value) {
    final bool isSelected = selectedOption == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedOption = value;
            print(state);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xff5dc7ff) : Color(0xffefefef),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black54,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

String UiChanger(String state) {
  String result = "";

  result = stateMatchingModel[stateList['state']] ?? '';
  print(stateMatchingModel[stateList['state']]);
  print('UiChanger$result');
  getImagePath(state);
  return state;
}
