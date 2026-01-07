import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'theme.dart';
import 'screens/login_screen.dart';

void main() async {
  // Flutter 바인딩 초기화 (file_picker 등의 플러그인이 필요)
  WidgetsFlutterBinding.ensureInitialized();

  // 창 관리자 초기화
  await windowManager.ensureInitialized();

  // 로그인 화면용 창 설정 (500x400 크기)
  WindowOptions windowOptions = const WindowOptions(
    size: Size(500, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const SecurityIndexApp());
}

class SecurityIndexApp extends StatelessWidget {
  const SecurityIndexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '보안관제 시스템',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
      locale: const Locale('ko', 'KR'),
      home: const LoginScreen(),
    );
  }
}
