import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Select/Cus_Select.dart';
import 'RestAPI.dart';
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
  late String _selectedOption;
  final tel = Uri.parse('tel:01012345678');

  void _startDataMonitoring() {
    int attemptCount = 0; // 시도 횟수 카운터 추가
    const int maxAttempts = 20; // 최대 시도 횟수

    _dataCheckTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
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
        print(
          '최종 상태 - cusList: $cusListReady, stateList: $stateListReady, state: $stateReady',
        );
      } else {
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

    //5초마다 setState 호출
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      setState(() {
        getState();
        state = stateMatchingModel[stateList['state']] ?? '';
      });
      print('globals.stateList${stateList}');

      print("_selectedOption" + state);
    });
  }

  // @override
  // void dispose() {
  //   _timer?.cancel(); // 꼭 해제해 주세요!
  //   super.dispose();
  // }

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
      body: SingleChildScrollView(
        child: Padding(
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset(
                        getImagePath(stateList['state']),
                        fit: BoxFit.cover, // 필요에 따라 추가
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.0),
                      child: Row(
                        children: [
                          command('문열림'),
                          const SizedBox(width: 10),
                          command('문닫힘'),
                        ],
                      ),
                    ),
                    Row(children: [const SizedBox(height: 20)]),
                    if (isremote == 'true')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            String result = await receiveRemote();
                            if (result == "1") {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('원격요청되었습니다.')),
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
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            shadowColor: Colors.transparent,
                          ),
                          child: const Text('원격요청'),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              if (centerPhone != null &&
                  centerPhone != '') //고객센터 전화번호를 불러오기 성공했다면 고객센터 전화 버튼을 불러온다.
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      print('전화 걸기');
                      launchUrl(Uri(scheme: 'tel', path: centerPhone));
                      // try {
                      //   // tel: 대신 전화 다이얼러만 열기
                      //   final Uri tel = Uri.parse(centerPhone);
                      //   await launchUrl(
                      //     tel,
                      //     mode: LaunchMode.externalApplication,
                      //
                      //   );
                      //   print('전화 걸기');
                      // } catch (e) {
                      //   print('전화 앱 열기 오류: $e');
                      // }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      shadowColor: Colors.black38,
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone, color: Colors.black54),
                        SizedBox(width: 12),
                        Text(
                          "관제실 통화",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
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
            color: isSelected ? Color(0xff2196f3) : Color(0xffefefef),
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

final Uri launchUri = Uri(
  scheme: 'tel', // 전화 걸기 앱 사용
  path: centerPhone, // 걸 전화번호
);
