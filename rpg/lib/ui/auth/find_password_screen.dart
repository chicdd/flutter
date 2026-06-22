// 비밀번호 찾기(초기화) — ID 입력 → 힌트 질문 표시 → 힌트 답변 검증 → 새 비밀번호 설정.
// 비밀번호는 해시 저장이라 복구 불가: "찾기"는 재설정 방식이다.
import 'package:flutter/material.dart';

import '../../net/auth_service.dart';

class FindPasswordScreen extends StatefulWidget {
  const FindPasswordScreen({super.key});

  @override
  State<FindPasswordScreen> createState() => _FindPasswordScreenState();
}

enum _Step { enterId, verifyHint, resetPassword }

class _FindPasswordScreenState extends State<FindPasswordScreen> {
  final _id = TextEditingController();
  final _answer = TextEditingController();
  final _newPw = TextEditingController();
  final _newPw2 = TextEditingController();

  _Step _step = _Step.enterId;
  String _hintQuestion = '';
  String? _error;
  bool _done = false;

  @override
  void dispose() {
    _id.dispose();
    _answer.dispose();
    _newPw.dispose();
    _newPw2.dispose();
    super.dispose();
  }

  Future<void> _loadHint() async {
    final q = await AuthService.instance.getHintQuestion(_id.text);
    if (!mounted) return;
    setState(() {
      if (q == null) {
        _error = '존재하지 않는 ID입니다.';
      } else {
        _error = null;
        _hintQuestion = q.isEmpty ? '(등록된 힌트 질문 없음)' : q;
        _step = _Step.verifyHint;
      }
    });
  }

  Future<void> _verify() async {
    final res = await AuthService.instance.verifyHint(_id.text, _answer.text);
    if (!mounted) return;
    setState(() {
      if (res.ok) {
        _error = null;
        _step = _Step.resetPassword;
      } else {
        _error = res.message;
      }
    });
  }

  Future<void> _reset() async {
    final res = await AuthService.instance.resetPassword(
      id: _id.text,
      newPassword: _newPw.text,
      newPasswordConfirm: _newPw2.text,
    );
    if (!mounted) return;
    if (res.ok) {
      setState(() {
        _done = true;
        _error = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted) Navigator.of(context).pop();
    } else {
      setState(() => _error = res.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 찾기')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _id,
                  enabled: _step == _Step.enterId,
                  onSubmitted: (_) => _loadHint(),
                  decoration: const InputDecoration(
                    labelText: 'ID',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                if (_step == _Step.enterId)
                  FilledButton(
                    onPressed: _loadHint,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('다음'),
                    ),
                  ),

                // 2단계: 힌트 질문 + 답변 검증.
                if (_step == _Step.verifyHint) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF242424),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.help_outline, color: Color(0xFFFFB300)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('힌트: $_hintQuestion',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _answer,
                    onSubmitted: (_) => _verify(),
                    decoration: const InputDecoration(
                      labelText: '힌트 답변',
                      prefixIcon: Icon(Icons.vpn_key),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _verify,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('확인'),
                    ),
                  ),
                ],

                // 3단계: 새 비밀번호 설정.
                if (_step == _Step.resetPassword) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('새 비밀번호를 입력하세요.', style: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPw,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '새 비밀번호 (4자 이상)',
                      prefixIcon: Icon(Icons.lock_reset),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPw2,
                    obscureText: true,
                    onSubmitted: (_) => _reset(),
                    decoration: const InputDecoration(
                      labelText: '새 비밀번호 확인',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _done ? null : _reset,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('비밀번호 변경'),
                    ),
                  ),
                ],

                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
