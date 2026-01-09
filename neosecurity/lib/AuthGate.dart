import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:neosecurity/Display.dart'; // Main 대신 Display import
import 'Login.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      print('AuthGate에서 토큰읽기');

      setState(() {
        _isAuthenticated = token != null && token.isNotEmpty;
        _isLoading = false;
      });

      print('인증 결과: $_isAuthenticated');
    } catch (e) {
      print('인증 오류: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    _checkAuthentication();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      print('인증 확인 중...');
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('로딩 중...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('오류 발생'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _retry, child: const Text('다시 시도')),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const Login()),
                  );
                },
                child: const Text('로그인 페이지로'),
              ),
            ],
          ),
        ),
      );
    }

    // Main 대신 Display 호출
    return _isAuthenticated ? const Display() : const Login();
  }
}
