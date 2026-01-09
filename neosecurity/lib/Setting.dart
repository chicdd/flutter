import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:neosecurity/Login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import 'Home.dart';
import 'globals.dart';

class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  State<Setting> createState() => _SettingState();
}

//초기화작업
void logout(BuildContext context) async {
  const storage = FlutterSecureStorage();
  await storage.delete(key: 'token');
  print('토큰 삭제됨');
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const Login()),
  );
  selectInt = 0;
  monnum = "";
  yongnum = "";
  secuBasicList = [];
  erpCusInfoList = [];
  userList = [];
  signalList = [];
  dvrList = [];
  claimList = [];
  billList = [];
  cusList = [];
  erpList = [];
  noticeList = [];
  stateList = {};
}


class _SettingState extends State<Setting> {

  String version = '';

  @override
  void initState() {
    super.initState();
    _getVersion();
  }


  Future<void> _getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      version = packageInfo.version; // FLUTTER_BUILD_NAME
      // packageInfo.buildNumber; // FLUTTER_BUILD_NUMBER
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: const IconThemeData(
          color: Colors.black, // 색변경
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(
              context,
              MaterialPageRoute(builder: (context) => const Home()),
            );
          },
        ),
        title: Row(
          children: [
            SizedBox(
              width: 130,
              child: Text(
                '설정',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        shadowColor: Colors.transparent,
      ),
      backgroundColor: const Color(0xfff7f7f7),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        // Padding(
                        //   padding: const EdgeInsets.symmetric(
                        //     horizontal: 20,
                        //     vertical: 8,
                        //   ),
                        //   child: SizedBox(
                        //     width: double.infinity,
                        //     child: Row(
                        //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //       children: [
                        //         Row(
                        //           children: [
                        //             Padding(
                        //               padding: const EdgeInsets.only(top: 4),
                        //               child: Icon(
                        //                 Icons.content_paste_outlined,
                        //                 color: Colors.black,
                        //               ),
                        //             ),
                        //             SizedBox(width: 12),
                        //             Text(
                        //               "공지사항",
                        //               style: TextStyle(
                        //                 fontSize: 18,
                        //                 color: Colors.black,
                        //               ),
                        //             ),
                        //           ],
                        //         ),
                        //         Padding(
                        //           padding: const EdgeInsets.only(top: 4),
                        //           child: Icon(
                        //             Icons.arrow_forward_ios_outlined,
                        //             size: 24,
                        //             color: Colors.black54,
                        //           ),
                        //         ),
                        //       ],
                        //     ),
                        //   ),
                        // ),
                        // const SizedBox(height: 25),
                        // // Divider(thickness: 1, height: 1, color: Color(0xffdfdfdf)),
                        // Padding(
                        //   padding: const EdgeInsets.symmetric(
                        //     horizontal: 20,
                        //     vertical: 8,
                        //   ),
                        //   child: SizedBox(
                        //     width: double.infinity,
                        //     child: Row(
                        //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //       children: [
                        //         Row(
                        //           children: [
                        //             Padding(
                        //               padding: const EdgeInsets.only(top: 4),
                        //               child: Icon(
                        //                 Icons.support_agent_outlined,
                        //                 color: Colors.black,
                        //               ),
                        //             ),
                        //             SizedBox(width: 12),
                        //             Text(
                        //               "기술지원 앱 설치",
                        //               style: TextStyle(
                        //                 fontSize: 18,
                        //                 color: Colors.black,
                        //               ),
                        //             ),
                        //           ],
                        //         ),
                        //         Padding(
                        //           padding: const EdgeInsets.only(top: 4),
                        //           child: Icon(
                        //             Icons.arrow_forward_ios_outlined,
                        //             size: 24,
                        //             color: Colors.black54,
                        //           ),
                        //         ),
                        //       ],
                        //     ),
                        //   ),
                        // ),
                        // const SizedBox(height: 50),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '전화번호',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),

                                Text(
                                  formatPhoneNumber(phoneCode),
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '앱버전',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                Text(version, style: TextStyle(fontSize: 18)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        logout(context);
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
                      child: const Text('로그아웃'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> fetchUsers() async {
  final response = await http.get(Uri.parse('http://localhost:3000/users'));

  if (response.statusCode == 200) {
    final List users = jsonDecode(response.body);
    print(users);
  } else {
    throw Exception('Failed to load users');
  }
}

String formatPhoneNumber(String input) {
  // 숫자만 남기기
  final digits = input.replaceAll(RegExp(r'\D'), '');

  // 11자리일 경우 (휴대폰 번호)
  if (digits.length == 11) {
    return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
  }

  // 10자리일 경우 (일부 지역번호 포함 번호 등)
  if (digits.length == 10) {
    return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
  }

  // 형식이 맞지 않을 경우 그대로 반환
  return input;
}
