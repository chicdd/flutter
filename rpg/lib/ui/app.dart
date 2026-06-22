// 앱 루트 (§9). 다크 테마 + 인증 게이트(자동 로그인) → 게임 화면.
import 'package:flutter/material.dart';

import '../models/account.dart';
import '../net/auth_service.dart';
import 'auth/login_screen.dart';
import 'game_screen.dart';

class RpgApp extends StatelessWidget {
  const RpgApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2D 인스턴스 RPG',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6D4C41),
          brightness: Brightness.dark,
        ),
      ),
      home: const _AuthGate(),
    );
  }
}

// 저장된 세션이 있으면 바로 게임으로, 없으면 로그인 화면으로.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Account?>(
      future: AuthService.instance.currentAccount(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final account = snap.data;
        if (account != null) return GameScreen(account: account);
        return const LoginScreen();
      },
    );
  }
}
