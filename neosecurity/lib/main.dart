import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:neosecurity/AuthGate.dart';
import 'dart:io';

import 'flavor_config.dart';
import 'globals.dart';
import 'Display.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();

  FlavorConfig.setup(
    appName: '값없음', // 여기 Android Manifest placeholders 값
    gaetongCode: '개통코드없음', // BuildConfig.GAETONG_CODE 값
  );

  await fetchFlavorInfo();
  await checkAuth();

  runApp(const MyApp());
}

Future<void> fetchFlavorInfo() async {
  const channel = MethodChannel('com.neo.config/channel');
  try {
    company = await channel.invokeMethod<String>('getAppName') ?? '';
    syscode = await channel.invokeMethod<String>('getGaetongCode') ?? '';
    print('앱 이름: $company, 개통코드: $syscode');
  } catch (e) {
    print('Failed to get flavor info: $e');
  }
}

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
    final flavorConfig = FlavorConfig.instance;

    return MaterialApp(
      title: flavorConfig.appName,
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
