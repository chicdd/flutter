// 회원가입 화면 — ID/닉네임/비밀번호 + 비밀번호 힌트(질문·답변).
import 'package:flutter/material.dart';

import '../../net/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _id = TextEditingController();
  final _nick = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  final _hintQ = TextEditingController();
  final _hintA = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_id, _nick, _pw, _pw2, _hintQ, _hintA]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await AuthService.instance.register(
      id: _id.text,
      nickname: _nick.text,
      password: _pw.text,
      passwordConfirm: _pw2.text,
      hintQuestion: _hintQ.text,
      hintAnswer: _hintA.text,
    );
    if (!mounted) return;
    if (res.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message)),
      );
      Navigator.of(context).pop();
    } else {
      setState(() {
        _busy = false;
        _error = res.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field(_id, 'ID (영문/숫자/_, 4자 이상)', Icons.person),
                const SizedBox(height: 12),
                _field(_nick, '닉네임 (아이디 찾기에 사용)', Icons.badge),
                const SizedBox(height: 12),
                _field(_pw, '비밀번호 (4자 이상)', Icons.lock, obscure: true),
                const SizedBox(height: 12),
                _field(_pw2, '비밀번호 확인', Icons.lock_outline, obscure: true),
                const Divider(height: 32),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('비밀번호 힌트 (분실 시 복구에 사용)',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ),
                const SizedBox(height: 12),
                _field(_hintQ, '힌트 질문 (예: 내 첫 반려동물 이름?)', Icons.help_outline),
                const SizedBox(height: 12),
                _field(_hintA, '힌트 답변', Icons.vpn_key),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _register,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _busy
                        ? const SizedBox(
                            height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('가입하기'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
