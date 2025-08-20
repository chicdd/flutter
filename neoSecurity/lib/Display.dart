import 'package:flutter/material.dart';
import 'package:neosecurity/ERPInfo/ERP_Home.dart';
import 'package:neosecurity/SecurityInfo/Security_Home.dart';
import 'package:neosecurity/Home.dart';
import 'package:neosecurity/Setting.dart';
import 'package:neosecurity/RestAPI.dart';

import 'functions.dart';
import 'globals.dart';

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

  Future<void> initializeData() async {
    try {
      // 1단계: 먼저 고객 리스트 가져오기
      final customers = await RestApiService().customerRequest(
        syscode,
        phoneCode,
      );
      print('customers$customers');
      cusList = customers;
      isremote = cusList[selectInt]['isremote'] ?? "";
      monnum = cusList[selectInt]['monnum'] ?? "";
      print('cusList$cusList');

      // 2단계: 첫 번째 고객 또는 선택된 고객의 상태 정보 가져오기
      if (customers.isNotEmpty) {
        final monnum = customers[0]['monnum'] ?? '';
        if (monnum.isNotEmpty) {
          stateList = await RestApiService().currentStateRequest(
            syscode,
            monnum,
            phoneCode,
          );
          // state 정보 사용
          state = stateList['state'] ?? '';
          print('state$state');
          print('monnum$monnum');
          print('isremote$isremote');
        }
      }
    } catch (e) {
      print('오류: $e');
    }
  }

  // 탭 변경 함수
  void _onItemTapped(int index) {
    if (mounted) {
      // mounted 체크 추가
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffefefef),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // 명시적으로 고정형 지정
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xffffffff),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Icon(Icons.home_filled),
            ),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Icon(Icons.person),
            ),
            label: '관제정보',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Icon(Icons.list_alt),
            ),
            label: '영업정보',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Icon(Icons.settings),
            ),
            label: '설정',
          ),
        ],
      ),
    );
  }
}
