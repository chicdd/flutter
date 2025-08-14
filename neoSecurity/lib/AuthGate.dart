import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:neosecurity/Display.dart'; // Main 대신 Display import
import 'package:neosecurity/globals.dart';

import 'Home.dart';
import 'Login.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> isAuthenticated() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    print('AuthGate에서 토큰읽기');
    return token != null && token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isAuthenticated(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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

        if (snapshot.hasError) {
          print('인증 오류: ${snapshot.error}');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('오류 발생'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // 다시 시도 또는 로그인 페이지로 이동
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const Login()),
                      );
                    },
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          );
        }

        final isLoggedIn = snapshot.data ?? false;
        print('인증 결과: $isLoggedIn');

        // Main 대신 Display 호출
        return isLoggedIn ? const Display() : const Login();
      },
    );
  }
}
