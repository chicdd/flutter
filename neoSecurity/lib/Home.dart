import 'dart:async';
import 'package:flutter/material.dart';
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
  String _selectedOption = ''; // 라디오버튼 기본 선택값
  Timer? _timer;

  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getCustomer();
      await getState();
      setState(() {
        _selectedOption = UiChanger(stateList['state'].toString());
      });
    });
    // if (isfirst == 1) {
    //   //최초에
    //   WidgetsBinding.instance.addPostFrameCallback((_) async {
    //     await getCenterPhone(); //고객센터전화번호 불러오기
    //     await getCustomer();
    //     print('호출됨');
    //     await getState();
    //
    //     setState(() {
    //       _selectedOption = UiChanger(
    //         stateList['state'].toString(),
    //       ); //현재 상태 값에 따라서 라디오버튼을 갱신해준다. stateMatchingModel 모델 참고
    //     });
    //   });
    //   isfirst = 0;
    // } else {
    //   print('새로고침함');
    //   WidgetsBinding.instance.addPostFrameCallback((_) async {
    //     await getCenterPhone(); //고객센터전화번호 불러오기
    //     await getCustomer();
    //     await getState();
    //     setState(() {
    //       _selectedOption = UiChanger(stateList['state'].toString());
    //     });
    //   });
    // }
    // 5초마다 setState 호출
    // _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
    //   setState(() {
    //     _counter++; // 또는 API 호출, 데이터 갱신 등
    //     getState();
    //     _selectedOption = stateMatchingModel[stateList['state']] ?? '';
    //   });
    //   print('globals.stateList${stateList}');
    //   print(_counter);
    //   print("_selectedOption" + _selectedOption);
    // });
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
          padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 5),
          child: Column(
            children: [
              CusSelect(
                title: "",
                onPressed: () {
                  setState(() {
                    print('stateList[state]' + stateList['state'].toString());
                  });
                  _selectedOption = UiChanger(stateList['state'].toString());
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
                    onPressed: () {
                      PhoneCall(centerPhone);
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
    final bool isSelected = _selectedOption == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedOption = value;
            state = value;
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

  //전화걸기 이벤트
  void PhoneCall(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    // if (await canLaunchUrl(url)) {
    //   await launchUrl(url);
    // } else {
    //   throw '전화를 걸 수 없습니다: $phoneNumber';
    // }
  }
}

String UiChanger(String state) {
  String result = "";
  result = stateMatchingModel[state] ?? '';
  getImagePath(state);
  return result;
}
