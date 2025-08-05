import 'package:flutter/material.dart';
import 'package:neosecurity/Modal/Modal_Customer_List.dart';
import '../Modal/Modal_page_List.dart';
import '../RestAPI.dart';
import '../Select/Cus_Select.dart';
import 'package:neosecurity/globals.dart' as globals;

class SecurityCusInfo extends StatefulWidget {
  const SecurityCusInfo({super.key});

  @override
  State<SecurityCusInfo> createState() => _SecurityCusInfoState();
}

class _SecurityCusInfoState extends State<SecurityCusInfo> {
  List<String> secuBasicList = globals.secuBasicList;
  List<Map<String, String>> userList = globals.userList;

  void initState() {
    super.initState();
    if (secuBasicList.isEmpty && userList.isEmpty) {
      fetchSecuBasic();
      fetchUserList();
    }
  }

  void fetchSecuBasic() async {
    try {
      List<String> result = await RestApiService().secuBasicRequest(
        globals.syscode,
        globals.monnum,
        globals.phoneCode,
      );

      setState(() {
        secuBasicList = result;
      });

      print("globals.secuBasicList: ${secuBasicList}");
    } catch (e) {
      print("API 호출 오류: $e");
    }
    print('api호출함');
    globals.secuBasicList = secuBasicList;
  }

  void fetchUserList() async {
    userList = await RestApiService().userListRequest(
      globals.syscode,
      globals.monnum,
      globals.phoneCode,
    );
    setState(() {});
    globals.userList = userList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CusSelect(
              title: "거래처명",
              onPressed: () {
                setState(() {});
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
