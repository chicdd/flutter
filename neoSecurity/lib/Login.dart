import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:neosecurity/Main.dart';
import 'package:neosecurity/randomNumCreate.dart';

import 'RestAPI.dart';
import 'functions.dart';
import 'globals.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _phoneCode = TextEditingController();
  final _password = TextEditingController();
  final String _smsMessage = "[인증번호:${random4Number()}] 인증번호를 입력해주세요.(한세시큐리티)";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('한세시큐리티'),
      //   centerTitle: true,
      //   automaticallyImplyLeading: false,
      // ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15), // 원하는 radius 값
              child: Image.asset("image/hanse.png", height: 65),
            ),
            const SizedBox(height: 40),
            TextField(
              keyboardType: TextInputType.number, //숫자키패드
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9]')), //숫자만 입력되도록
              ],
              controller: _phoneCode,
              decoration: InputDecoration(
                labelText: '휴대폰번호',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                suffixIcon: TextButton(
                  onPressed: () {
                    //랜덤4자리숫자생성

                    // 인증번호 발송 로직
                    RestApiService().sendSMS(
                      syscode,
                      sendPhone,
                      _phoneCode.text,
                      _smsMessage,
                    );
                    //print(random4Number());
                    phoneCode = _phoneCode.text;
                    ScaffoldMessenger.of(context).showSnackBar(
                      //하단 인증번호가 발송되었음 표시
                      const SnackBar(content: Text('인증번호가 발송되었습니다.')),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: const Text('인증번호 발송'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _password,
              decoration: const InputDecoration(
                labelText: '인증번호',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24, width: 50),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  String inputCode = _password.text;

                  if (inputCode != certNumber) {
                    //인증번호 검증
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('인증번호가 일치하지 않습니다.')),
                    );
                  } else {
                    //관제고객인지 체크
                    () async {
                      bool isConfirmed = await RestApiService().isUserConfirm(
                        syscode,
                        phoneCode,
                      );

                      if (!isConfirmed) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('등록된 관제고객이 아닙니다.')),
                        );
                      } else {
                        //검증 모두 통과하면
                        saveToken(phoneCode); //휴대폰번호를 토큰으로 휴대폰에 저장
                        //await getCustomer();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Main(),
                          ), //Main으로 위젯 넘기기
                        );
                      }
                    }();
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
                child: const Text('로그인'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void saveToken(String token) async {
  const storage = FlutterSecureStorage();
  await storage.write(key: 'token', value: token);
}
