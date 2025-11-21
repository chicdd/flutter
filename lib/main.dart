import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/main_layout.dart';

void main() {
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
      home: const MainLayout(),
    );
  }
}
