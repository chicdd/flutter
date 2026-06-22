// 캐릭터 화면(모바일 전체화면) — InventoryPanel 을 호스팅 + 로그아웃.
import 'package:flutter/material.dart';

import '../net/auth_service.dart';
import '../state/player_profile.dart';
import 'auth/login_screen.dart';
import 'inventory_panel.dart';

class CharacterScreen extends StatelessWidget {
  final PlayerProfile profile;
  final VoidCallback? onUseTownScroll;
  const CharacterScreen({super.key, required this.profile, this.onUseTownScroll});

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    await AuthService.instance.logout();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('캐릭터 · 인벤토리'),
        actions: [
          IconButton(
            tooltip: '로그아웃',
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: InventoryPanel(
        profile: profile,
        onUseTownScroll: onUseTownScroll == null
            ? null
            : () {
                onUseTownScroll!();
                Navigator.of(context).maybePop(); // 귀환 후 게임으로
              },
      ),
    );
  }
}
