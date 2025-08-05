import 'package:flutter/material.dart';
import 'package:neosecurity/Main.dart';
import 'package:neosecurity/randomNumCreate.dart';

import 'RestAPI.dart';
import 'globals.dart' as globals;

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _phoneCode = TextEditingController();
  final _password = TextEditingController();
  final String _smsMessage = "[인증번호:${random4Number()}] 인증번호를 입력해주세요.(한세시큐리티)";

  String _message = '';

  void _login() {
    String phoneCode = _phoneCode.text;
    String password = _password.text;

    setState(() {
      if (phoneCode == 'admin' && password == '1234') {
        _message = '로그인 성공!';
      } else {
        _message = '아이디 또는 비밀번호가 잘못되었습니다.';
      }
    });
  }

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
                    // RestApiService().sendSMS(
                    //   globals.syscode,
                    //   globals.sendPhone,
                    //   _phoneCode.text,
                    //   _smsMessage,
                    // );
                    print(random4Number());
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
                  if (inputCode == globals.certNumber) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Main()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('인증번호가 일치하지 않습니다.')),
                    );
                  }
                  print("certNumber : " + globals.certNumber);
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

            const SizedBox(height: 16),
            Text(_message, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
