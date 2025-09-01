import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hansesecurity/Home.dart';
import 'package:hansesecurity/SecurityInfo/SecurityCus_Info.dart';
import 'package:hansesecurity/SecurityInfo/DvrInfo.dart';
import 'package:hansesecurity/SecurityInfo/Sign_Info.dart';
import 'package:hansesecurity/globals.dart';

class SecurityHome extends StatefulWidget {
  const SecurityHome({super.key});
  @override
  State<SecurityHome> createState() => SecurityHomeState();
}

class SecurityHomeState extends State<SecurityHome> {
  late int _Index = 0;
  late String title = '타이틀 없음';
  final List<Widget> _pages = [SecurityCusInfo(), SignInfo(), DvrInfo()];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    title = securityPageList[_Index];
  }

  void _onItemTapped(int index) {
    if (mounted) {
      // mounted 체크 추가
      setState(() {
        _selectedIndex = index; // BottomNavigationBar에 반영
        _Index = index; // body도 같이 반영
        title = securityPageList[index]; // 타이틀도 변경
      });
    }
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
                title,
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

      body: _pages[_Index],

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // 명시적으로 고정형 지정
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xffffffff),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        items: [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Icon(Icons.account_circle),
            ),
            label: securityPageList[0],
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Icon(Icons.notifications_active),
            ),
            label: securityPageList[1],
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Icon(Icons.videocam),
            ),
            label: securityPageList[2],
          ),
        ],
      ),
    );
  }
}
