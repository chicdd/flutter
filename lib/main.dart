import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:securityindex/screens/main_layout.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'services/theme_service.dart';

void main() async {
  // Flutter 바인딩 초기화 (file_picker 등의 플러그인이 필요)
  WidgetsFlutterBinding.ensureInitialized();

  // 창 관리자 초기화
  await windowManager.ensureInitialized();
  await windowManager.setMinimumSize(const Size(500, 600));

  // 로그인 화면용 창 설정 (500x400 크기)
  WindowOptions windowOptions = const WindowOptions(
    size: Size(500, 600),
    center: true,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Windows Acrylic/Mica 효과 초기화 (에러 처리 포함)
  try {
    await Window.initialize();
    // Windows 11: aero, mica, acrylic, tabbed 등 사용 가능
    // Windows 10: acrylic 사용
    await Window.setEffect(
      effect: WindowEffect.acrylic, // 가장 범용적인 블러 효과완전 투명
      dark: false,
    );
    print('✅ Window effect 적용 성공');
  } catch (e) {
    print('❌ Window effect 설정 실패: $e');
    // 효과 설정에 실패해도 앱은 계속 실행
  }

  // // 데이터베이스 연결 테스트
  // print('🔄 데이터베이스 연결을 시도합니다...');
  // await DBConnection.connect();

  runApp(const SecurityIndexApp());
}

class SecurityIndexApp extends StatefulWidget {
  const SecurityIndexApp({super.key});

  @override
  State<SecurityIndexApp> createState() => _SecurityIndexAppState();
}

class _SecurityIndexAppState extends State<SecurityIndexApp> {
  final _themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    _themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
      child: MaterialApp(
        title: '보안관제 시스템',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
        locale: const Locale('ko', 'KR'),
        home: const LoginScreen(),
      ),
    );
  }
}
