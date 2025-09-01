import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hansesecurity/Display.dart';
import 'package:hansesecurity/Main.dart';
import 'package:hansesecurity/randomNumCreate.dart';
import 'RestAPI.dart';
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
              keyboardType: TextInputType.number,
              inputFormatters: [
                PhoneNumberFormatter(), // 커스텀 포매터 사용
              ],
              controller: _phoneCode,
              decoration: InputDecoration(
                labelText: '휴대폰번호',
                hintText: '',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                // 인증번호 발송 버튼의 onPressed 수정
                suffixIcon: TextButton(
                  onPressed: () {
                    // 숫자만 추출해서 API 호출
                    String phoneNumber = _phoneCode.text.replaceAll(
                      RegExp(r'[^0-9]'),
                      '',
                    );

                    // 데모 계정 체크
                    if (phoneNumber == '987654321') {
                      // 데모 계정일 때는 SMS 발송하지 않고 바로 완료 메시지
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('데모 계정입니다. 인증번호: 1234')),
                      );
                      return;
                    }

                    // 일반 계정 로직
                    if (phoneNumber.length == 11) {
                      // 인증번호 발송 로직
                      RestApiService().sendSMS(
                        syscode,
                        sendPhone,
                        phoneNumber, // 하이픈 제거된 순수 숫자만 전달
                        _smsMessage,
                      );

                      phoneCode = phoneNumber;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('인증번호가 발송되었습니다.')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('올바른 휴대폰 번호를 입력해주세요.')),
                      );
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('인증번호 발송'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              keyboardType: TextInputType.number,
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
                  // 숫자만 추출해서 휴대폰 번호 확인
                  String phoneNumber = _phoneCode.text.replaceAll(
                    RegExp(r'[^0-9]'),
                    '',
                  );

                  // 데모 계정 체크 (987654321 + 인증번호 1234)
                  if (phoneNumber == '987654321' && inputCode == '1234') {
                    // 데모 계정으로 바로 로그인
                    phoneCode = '987654321';
                    saveToken(phoneCode); // 데모 계정 번호를 토큰으로 저장
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('데모 계정으로 로그인되었습니다.')),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Main()),
                    );
                    return; // 데모 계정 처리 후 함수 종료
                  }

                  // 기존 일반 로그인 로직
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
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Display(),
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

String formatPhoneNumberBasic(String phoneNumber) {
  // 숫자 외의 모든 문자 제거 (사용자가 하이픈이나 공백을 이미 입력했을 경우 대비)
  String digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');

  if (digitsOnly.length == 11) {
    // 010-1234-5678 형식
    return '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3, 7)}-${digitsOnly.substring(7)}';
  } else if (digitsOnly.length == 10) {
    // 02-1234-5678 또는 031-123-4567 형식
    if (digitsOnly.startsWith('02')) {
      // 서울 지역번호
      return '${digitsOnly.substring(0, 2)}-${digitsOnly.substring(2, 6)}-${digitsOnly.substring(6)}';
    } else {
      // 그 외 지역번호
      return '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
    }
  } else if (digitsOnly.length == 8) {
    // 대표번호 (예: 1588-1234)
    return '${digitsOnly.substring(0, 4)}-${digitsOnly.substring(4)}';
  }

  // 그 외의 경우는 원본 반환 (혹은 예외 처리)
  return phoneNumber;
}

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 숫자만 추출
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // 11자리를 초과하지 않도록 제한
    if (digitsOnly.length > 11) {
      digitsOnly = digitsOnly.substring(0, 11);
    }

    String formatted = '';

    if (digitsOnly.length >= 1) {
      if (digitsOnly.length <= 3) {
        // 3자리 이하: 그대로 표시
        formatted = digitsOnly;
      } else if (digitsOnly.length <= 7) {
        // 4~7자리: 010-0000 형태
        formatted = '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3)}';
      } else {
        // 8~11자리: 010-0000-0000 형태
        formatted =
            '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3, 7)}-${digitsOnly.substring(7)}';
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
