import 'package:flutter/material.dart';
import 'package:hansesecurity/ERPInfo/ERP_Home.dart';
import 'package:hansesecurity/SecurityInfo/Security_Home.dart';
import 'package:hansesecurity/Home.dart';
import 'package:hansesecurity/Setting.dart';
import 'functions.dart';

class Display extends StatefulWidget {
  const Display({super.key});

  @override
  State<Display> createState() => _DisplayState();
}

class _DisplayState extends State<Display> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const Home(),
    const SecurityHome(),
    const ErpHome(),
    const Setting(),
  ];
  @override
  void initState() {
    getCenterPhone();
    initializeData();
    super.initState();
  }

  // 탭 변경 함수
  // void _onItemTapped(int index) {
  //   if (mounted) {
  //     // mounted 체크 추가
  //     setState(() {
  //       _selectedIndex = index;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffefefef),
      body: _pages[_selectedIndex],
      // bottomNavigationBar: BottomNavigationBar(
      //   type: BottomNavigationBarType.fixed, // 명시적으로 고정형 지정
      //   currentIndex: _selectedIndex,
      //   onTap: _onItemTapped,
      //   backgroundColor: const Color(0xffffffff),
      //   selectedItemColor: Colors.black,
      //   unselectedItemColor: Colors.black54,
      //   items: const [
      //     BottomNavigationBarItem(
      //       icon: Padding(
      //         padding: EdgeInsets.only(top: 8.0),
      //         child: Icon(Icons.home_filled),
      //       ),
      //       label: '홈',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Padding(
      //         padding: EdgeInsets.only(top: 8.0),
      //         child: Icon(Icons.person),
      //       ),
      //       label: '관제정보',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Padding(
      //         padding: EdgeInsets.only(top: 8.0),
      //         child: Icon(Icons.list_alt),
      //       ),
      //       label: '영업정보',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Padding(
      //         padding: EdgeInsets.only(top: 8.0),
      //         child: Icon(Icons.settings),
      //       ),
      //       label: '설정',
      //     ),
      //   ],
      // ),
    );
  }
}
