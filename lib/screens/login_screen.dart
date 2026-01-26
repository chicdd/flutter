import 'package:flutter/material.dart';
import 'package:securityindex/style.dart';
import 'package:window_manager/window_manager.dart';
import '../theme.dart';
import 'main_layout.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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
      backgroundColor: Colors.transparent,
      body: Center(
        child: Center(
          child: SizedBox(
            width: 500,
            height: 600,
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
                      '네오 관제인덱스',
                      style: GoogleFonts.roboto(
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // 개통코드 입력
                    TextField(
                      controller: _openingCodeController,
                      style: TextStyle(color: context.colors.textPrimary),
                      decoration: InputDecoration(
                        labelText: '개통코드',
                        labelStyle: TextStyle(
                          color: context.colors.textPrimary,
                        ),
                        hintText: '',
                        hintStyle: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.business,
                          size: 20,
                          color: context.colors.textSecondary,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: context.colors.dividerColor,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: context.colors.selectedColor,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Color(0x5fffffff),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 로그인 아이디 입력
                    TextField(
                      controller: _idController,
                      style: TextStyle(color: context.colors.textPrimary),
                      decoration: InputDecoration(
                        labelText: '아이디',
                        labelStyle: TextStyle(
                          color: context.colors.textPrimary,
                        ),
                        hintText: '',
                        hintStyle: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.person,
                          size: 20,
                          color: context.colors.textSecondary,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: context.colors.dividerColor,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: context.colors.selectedColor,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Color(0x5fffffff),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 로그인 암호 입력
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: TextStyle(color: context.colors.textPrimary),
                      decoration: InputDecoration(
                        labelText: '패스워드',
                        labelStyle: TextStyle(
                          color: context.colors.textPrimary,
                        ),
                        hintText: '',
                        hintStyle: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.lock,
                          size: 20,
                          color: context.colors.textSecondary,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: context.colors.dividerColor,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: context.colors.selectedColor,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Color(0x5fffffff),
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
                          backgroundColor: context.colors.selectedColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }
}

class Box<T> {
  T content; // 어떤 타입인지 모르지만 'T'라고 부르겠다!

  Box(this.content);

  void printContent() {
    print("박스 내용물: $content");
  }
}
