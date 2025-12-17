import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme.dart';
import 'screens/main_layout.dart';

void main() {
  // Flutter 바인딩 초기화 (file_picker 등의 플러그인이 필요)
  WidgetsFlutterBinding.ensureInitialized();
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
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ko', 'KR'),
      home: const MainLayout(),
    );
  }
}
