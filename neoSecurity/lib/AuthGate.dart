import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:neosecurity/Main.dart';
import 'package:neosecurity/globals.dart';

import 'Home.dart';
import 'Login.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> isAuthenticated() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    print('토큰읽기');
    return token != null && token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isAuthenticated(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('빌드');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          print('오류');
          return const Scaffold(body: Center(child: Text('오류 발생')));
        }

        final isLoggedIn = snapshot.data ?? false;
        print('화면호출');
        return isLoggedIn ? const Main() : const Login();
      },
    );
  }
}
