// 아이디 찾기 — 닉네임으로 등록된 ID 조회.
import 'package:flutter/material.dart';

import '../../net/auth_service.dart';

class FindIdScreen extends StatefulWidget {
  const FindIdScreen({super.key});

  @override
  State<FindIdScreen> createState() => _FindIdScreenState();
}

class _FindIdScreenState extends State<FindIdScreen> {
  final _nick = TextEditingController();
  bool _searched = false;
  List<String> _results = [];

  @override
  void dispose() {
    _nick.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final r = await AuthService.instance.findIdsByNickname(_nick.text);
    if (!mounted) return;
    setState(() {
      _searched = true;
      _results = r;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('아이디 찾기')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('가입 시 등록한 닉네임으로 ID를 찾습니다.',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                TextField(
                  controller: _nick,
                  onSubmitted: (_) => _search(),
                  decoration: const InputDecoration(
                    labelText: '닉네임',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _search,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('아이디 찾기'),
                  ),
                ),
                const SizedBox(height: 20),
                if (_searched)
                  _results.isEmpty
                      ? const Text('일치하는 ID가 없습니다.',
                          style: TextStyle(color: Colors.redAccent))
                      : Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF242424),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('등록된 ID', style: TextStyle(color: Colors.white54, fontSize: 12)),
                              const SizedBox(height: 8),
                              ..._results.map((id) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.person, size: 18, color: Color(0xFFFFB300)),
                                        const SizedBox(width: 8),
                                        Text(id,
                                            style: const TextStyle(
                                                fontSize: 16, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
