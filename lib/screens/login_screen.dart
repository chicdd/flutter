import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../theme.dart';
import '../style.dart';
import 'main_layout.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import '../models/login_user.dart';
import '../models/company_data.dart';

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

  bool _saveId = false;
  bool _autoLogin = false;
  String _companyName = '네오 관제인덱스';

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  @override
  void dispose() {
    _openingCodeController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 저장된 데이터 불러오기
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. SharedPreferences에서 직접 읽기
    final savedCompanyName = prefs.getString('company_name') ?? '미설정 업체';

    // 2. 전역 ApiConfig에도 동기화 (다른 API 호출 시 사용하기 위함)
    ApiConfig().companyName = savedCompanyName;

    // 3. UI 반영
    if (mounted) {
      // context가 살아있는지 확인
      setState(() {
        _companyName = savedCompanyName;
      });
      print('회사명 변경 완료: $_companyName');
    }
    // 아이디 저장 체크 여부 불러오기
    final savedIdCheckbox = prefs.getBool('saveId') ?? false;
    setState(() {
      _saveId = savedIdCheckbox;
    });

    // 아이디 저장이 체크되어 있으면 아이디 불러오기
    if (_saveId) {
      final savedId = prefs.getString('userId');
      if (savedId != null) {
        _idController.text = savedId;
      }
    }

    // 자동로그인 체크 여부 불러오기
    final autoLoginCheckbox = prefs.getBool('autoLogin') ?? false;
    setState(() {
      _autoLogin = autoLoginCheckbox;
    });

    // 자동로그인이 체크되어 있으면 저장된 사용자 정보로 자동 로그인 시도
    if (_autoLogin) {
      final savedUser = await UserService.loadUser();
      if (savedUser != null) {
        // 저장된 사용자 정보가 있으면 바로 메인 화면으로 이동
        Future.delayed(Duration.zero, () async {
          await windowManager.setResizable(true);
          await windowManager.setMinimumSize(const Size(1280, 720));
          await windowManager.maximize();

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MainLayout()),
            );
          }
        });
      } else {
        // 저장된 사용자 정보가 없으면 저장된 ID와 비밀번호로 로그인 시도
        final savedPassword = prefs.getString('userPassword');
        if (savedPassword != null) {
          _passwordController.text = savedPassword;
          Future.delayed(Duration.zero, () => _handleLogin());
        }
      }
    }
  }

  /// 데이터 저장
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    // 아이디 저장 체크박스 저장
    await prefs.setBool('saveId', _saveId);

    if (_saveId) {
      // 아이디 저장
      await prefs.setString('userId', _idController.text);
    } else {
      // 아이디 삭제
      await prefs.remove('userId');
    }

    // 자동로그인 체크박스는 로그인 성공 시에만 저장됨
  }

  /// 자동로그인 데이터 저장 (로그인 성공 시)
  Future<void> _saveAutoLoginData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('autoLogin', _autoLogin);

    if (_autoLogin) {
      // 자동로그인 체크 시 아이디와 비밀번호 저장
      await prefs.setString('userId', _idController.text);
      await prefs.setString('userPassword', _passwordController.text);
      await prefs.setBool('saveId', true); // 자동로그인이면 아이디 저장도 자동으로 체크
    } else {
      // 자동로그인 해제 시 비밀번호만 삭제
      await prefs.remove('userPassword');
    }
  }

  Future<void> _handleLogin() async {
    final id = _idController.text.trim();
    final password = _passwordController.text.trim();

    // 입력 검증
    if (id.isEmpty || password.isEmpty) {
      if (mounted) {
        showToast(context, message: '아이디와 비밀번호를 입력해주세요.');
      }
      return;
    }

    try {
      // 로그인 API 호출
      final result = await DatabaseService.login(id: id, password: password);

      if (result == null) {
        if (mounted) {
          showToast(context, message: '서버와의 통신에 실패했습니다.');
        }
        return;
      }

      // 에러 메시지 확인
      if (result.containsKey('error')) {
        if (mounted) {
          showToast(context, message: result['error'] as String);
        }
        return;
      }

      // 로그인 성공
      final loginUser = LoginUser.fromJson(result);
      // 사용자 정보 저장
      await UserService.saveUser(loginUser);
      print('사용자 정보 저장');
      // 아이디 저장 데이터 저장
      await _saveData();
      print('아이디 저장 데이터 저장');
      // 자동로그인 데이터 저장
      await _saveAutoLoginData();

      // 창을 최대화하고 메인 화면으로 이동
      await windowManager.setResizable(true);
      await windowManager.setMinimumSize(const Size(1280, 720));
      await windowManager.maximize();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainLayout()),
        );
      }
    } catch (e) {
      print('로그인 처리 중 오류: $e');
      if (mounted) {
        showToast(context, message: '로그인 처리 중 오류가 발생했습니다.');
      }
    }
  }

  /// 개통설정 모달 열기
  Future<void> _showOpeningCodeModal() async {
    final openingCodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: context.colors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 제목
              Text(
                '개통설정',
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // 개통코드 입력
              TextField(
                controller: openingCodeController,
                style: TextStyle(color: context.colors.textPrimary),
                decoration: InputDecoration(
                  labelText: '개통코드',
                  labelStyle: TextStyle(color: context.colors.textPrimary),
                  hintText: '개통코드를 입력하세요',
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
              const SizedBox(height: 24),

              // 버튼 영역
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 취소 버튼
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      '취소',
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 확인 버튼
                  ElevatedButton(
                    onPressed: () async {
                      final code = openingCodeController.text.trim();
                      if (code.isEmpty) {
                        showToast(context, message: '개통코드를 입력해주세요.');
                        return;
                      }

                      // 1. 로컬 데이터에서 검색
                      final company = CompanyRepository.findByCode(code);

                      if (company != null) {
                        // 2. 검색 성공 시 정보 저장
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('api_url', company.apiUrl);
                        await prefs.setString('company_name', company.name);

                        showToast(
                          context,
                          message: '${company.name}으로 개통되었습니다.',
                        );

                        setState(() {
                          _companyName = company.name;
                        });

                        // 3. 메인 화면으로 이동하거나 API 클라이언트 초기화 로직 실행
                        print("설정된 주소: ${company.apiUrl}");
                        Navigator.of(context).pop();
                      } else {
                        // 4. 검색 실패 시
                        showToast(context, message: '일치하는 개통코드가 없습니다.');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.selectedColor,
                      foregroundColor: context.colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.cardBackground.withOpacity(0.8),
      body: Stack(
        children: [
          Center(
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
                        _companyName,
                        style: GoogleFonts.roboto(
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

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
                      const SizedBox(height: 16),

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
                      const SizedBox(height: 16),

                      // 아이디 저장, 자동로그인 체크박스
                      Row(
                        children: [
                          // 아이디 저장 체크박스
                          Expanded(
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _saveId,
                                  onChanged: (value) {
                                    setState(() {
                                      _saveId = value ?? false;
                                    });
                                  },
                                  activeColor: context.colors.selectedColor,
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _saveId = !_saveId;
                                    });
                                  },
                                  child: Text(
                                    '아이디 저장',
                                    style: TextStyle(
                                      color: context.colors.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 자동로그인 체크박스
                          Expanded(
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _autoLogin,
                                  onChanged: (value) {
                                    setState(() {
                                      _autoLogin = value ?? false;
                                    });
                                  },
                                  activeColor: context.colors.selectedColor,
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _autoLogin = !_autoLogin;
                                    });
                                  },
                                  child: Text(
                                    '자동로그인',
                                    style: TextStyle(
                                      color: context.colors.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 개통설정 버튼 (오른쪽 아래)
          Positioned(
            right: 24,
            bottom: 24,
            child: TextButton.icon(
              onPressed: _showOpeningCodeModal,
              icon: Icon(
                Icons.settings,
                size: 18,
                color: context.colors.textSecondary,
              ),
              label: Text(
                '개통설정',
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 14,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
