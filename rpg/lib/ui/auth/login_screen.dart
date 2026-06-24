// 로그인 화면 — ID/비밀번호 + 회원가입/아이디찾기/비밀번호찾기 진입.
import 'package:flutter/material.dart';

import '../../models/account.dart';
import '../../net/auth_service.dart';
import '../game_screen.dart';
import 'find_id_screen.dart';
import 'find_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _id = TextEditingController();
  final _pw = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _id.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await AuthService.instance.login(_id.text, _pw.text);
    if (!mounted) return;
    if (res.ok && res.account != null) {
      _enterGame(res.account!);
    } else {
      setState(() {
        _busy = false;
        _error = res.message;
        print('로그인실패');
      });
    }
  }

  void _enterGame(Account account) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => GameScreen(account: account)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.shield_moon,
                  size: 64,
                  color: Color(0xFFFFB300),
                ),
                const SizedBox(height: 12),
                const Text(
                  '2D 인스턴스 RPG',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _id,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'ID',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pw,
                  obscureText: true,
                  onSubmitted: (_) => _login(),
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _login,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('로그인'),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => _push(const FindIdScreen()),
                      child: const Text('아이디 찾기'),
                    ),
                    TextButton(
                      onPressed: () => _push(const FindPasswordScreen()),
                      child: const Text('비밀번호 찾기'),
                    ),
                    TextButton(
                      onPressed: () => _push(const RegisterScreen()),
                      child: const Text('회원가입'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}
