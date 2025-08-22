import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sheetgenerator/Modal_Select_List.dart';
import 'package:sheetgenerator/Select.dart';

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Main(),
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
  int _depositclassIndex = 0;
  // 탭 변경 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '네오 견적서 생성기',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        shadowColor: Colors.transparent,
      ),
      backgroundColor: const Color(0xffefefef),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Select(
              selectClass: "customer",
              selectDefault: "거래처선택",
              onPressed: (int selectedIndex) {
                setState(() {});
              },
            ),
            SizedBox(height: 20),
            Select(
              selectClass: "manager",
              selectDefault: "담당자선택",
              onPressed: (int selectedIndex) {
                setState(() {});
              },
            ),
          ],
        ),
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
