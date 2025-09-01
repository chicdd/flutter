import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hansesecurity/AuthGate.dart';
import 'dart:io';

import 'globals.dart';
import 'Display.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  await checkAuth();
  runApp(const MyApp());
  // load();
}

// 기본값 먼저 설정 (중요!)
// void load() async {
//   // checkAuth
//   try {
//     await checkAuth();
//     print('checkAuth 완료');
//   } catch (e) {
//     print('checkAuth 에러: $e');
//   }
//   try {
//
//     print('getCenterPhone() 완료');
//   } catch (e) {
//     print('getCenterPhone() 에러: $e');
//   }
// }

//토큰 확인
Future<void> checkAuth() async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'token');
  print('토큰읽기');
  if (token != null && token.isNotEmpty) {
    phoneCode = token; //토큰을 휴대폰번호로 넣기
    print('phoneCode: $phoneCode');
  } else {
    phoneCode = ''; // 기본값 설정
    print('토큰 없음');
  }
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
        DefaultWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'), // Korean
        Locale('en', 'US'), // English
      ],
      debugShowCheckedModeBanner: false,
    );
  }
}

// Main 클래스 단순화 (필요시 유지, 아니면 삭제 가능)
class Main extends StatelessWidget {
  const Main({super.key});

  @override
  Widget build(BuildContext context) {
    // Display로 모든 것을 위임
    return const Display();
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
