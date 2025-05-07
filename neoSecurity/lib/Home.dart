import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:untitled1/Cus_Info.dart';
import 'package:untitled1/Security_Info.dart';
import 'package:untitled1/Setting.dart';
import 'package:untitled1/Sign_Info.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Demo',
      theme: ThemeData(useMaterial3: false),
      home: const Home(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        // 실 기기에서 아래를 주석 처리하고 이 부분을 넣어야 한다.
        GlobalCupertinoLocalizations.delegate,
        // DefaultCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'), // Korean
        Locale('en', 'US'), // English
      ],
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    SecurityInfo(),
    CusInfo(),
    SignInfo(),
    Setting(),
  ];

  // 탭 변경 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
        backgroundColor: Color(0xffffffff), // 배경색 회색으로 맞춤
        selectedItemColor: Colors.black, // 선택된 아이템 색
        unselectedItemColor: Colors.black54, // 비선택 아이템 색
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 8.0), // 높이를 조절하는 패딩
              child: Icon(Icons.home_filled),
            ),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Icon(Icons.person),
            ),
            label: '고객정보',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Icon(Icons.list_alt),
            ),
            label: '신호정보',
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
