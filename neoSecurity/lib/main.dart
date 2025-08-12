import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:neosecurity/AuthGate.dart';
import 'package:neosecurity/ERPInfo/ERP_Home.dart';
import 'package:neosecurity/SecurityInfo/Security_Home.dart';
import 'package:neosecurity/Home.dart';
import 'package:neosecurity/Setting.dart';
import 'package:neosecurity/SecurityInfo/Sign_Info.dart';
import 'dart:io';
import 'Login.dart';
import 'RestAPI.dart';
import 'functions.dart';
import 'globals.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  checkAuth();
  await getCenterPhone(); //고객센터 전화번호 불러오기.
  await getCustomer();
  runApp(const MyApp());
}

//토큰 확인
Future<void> checkAuth() async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'token');
  print('토큰읽기');
  phoneCode = token!; //토큰을 휴대폰번호로 넣기
  print('phoneCode' + phoneCode);
  // 인증되었으면 그대로 진행
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Demo',
      theme: ThemeData(useMaterial3: false),
      home: const AuthGate(),
      // 한글 Locale 설정
      locale: const Locale('ko', 'KR'),
      localizationsDelegates: const [
        // 기본 cupertino + material 로컬라이제이션 지원
        DefaultCupertinoLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'), // Korean
        Locale('en', 'US'), // English
      ],
    );
  }
}

class Main extends StatefulWidget {
  const Main({super.key});

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [Home(), SecurityHome(), ErpHome(), Setting()];

  // 탭 변경 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    print('토큰읽기');
    phoneCode = token!; //토큰을 휴대폰번호로 넣기
    if (token == null || token.isEmpty) {
      print('토큰없음');
      // 인증 실패 → 로그인 페이지로 이동
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Login()),
        );
      });
    } else {
      print('토큰있음');
    }
    // 인증되었으면 그대로 진행
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
        backgroundColor: Color(0xffffffff),
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

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // '?'를 추가해서 null safety 확보
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
