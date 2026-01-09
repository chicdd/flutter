import 'package:flutter/material.dart';
import 'package:securityindex/style.dart';
import 'package:window_manager/window_manager.dart';
import '../theme.dart';
import 'main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _openingCodeController = TextEditingController();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _openingCodeController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // TODO: DB에서 로그인 검증 기능 구현 필요
    // 현재는 검증 없이 바로 메인 화면으로 이동

    // 창을 최대화하고 메인 화면으로 이동
    await windowManager.setResizable(true);
    await windowManager.setMinimumSize(const Size(1280, 720));
    await windowManager.maximize();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainLayout()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Container(
          width: 500,
          height: 600,
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppTheme.elevatedShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 로고 또는 제목
                  Text(
                    '보안관제 시스템',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '로그인',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // 개통코드 입력
                  TextField(
                    controller: _openingCodeController,
                    decoration: const InputDecoration(
                      labelText: '개통코드',
                      hintText: '개통코드를 입력하세요',
                      hintStyle: const TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(Icons.business, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 로그인 아이디 입력
                  TextField(
                    controller: _idController,
                    decoration: const InputDecoration(
                      labelText: '로그인 아이디',
                      hintText: '아이디를 입력하세요',
                      hintStyle: const TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(Icons.person, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 로그인 암호 입력
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '로그인 암호',
                      hintText: '암호를 입력하세요',
                      hintStyle: const TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(Icons.lock, size: 20),
                    ),
                    onSubmitted: (_) => _handleLogin(),
                  ),
                  const SizedBox(height: 32),

                  // 로그인 버튼
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.selectedColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '로그인',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
