import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../style.dart';
import '../theme.dart';
import '../services/theme_service.dart';
import '../services/user_service.dart';
import 'login_screen.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => SettingsState();
}

class SettingsState extends State<Settings>
    with SingleTickerProviderStateMixin {
  final _themeService = ThemeService();
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(begin: Colors.grey.shade300, end: Colors.green)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    // 초기 상태 설정
    if (_themeService.isDarkMode) {
      _animationController.value = 1.0;
    }

    // ThemeService 리스너 등록
    _themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    if (_themeService.isDarkMode) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _toggleDarkMode() {
    _themeService.toggleDarkMode();
  }

  /// 로그아웃 처리
  Future<void> _handleLogout() async {
    try {
      // 사용자 정보 삭제
      await UserService.clearUser();

      // 자동로그인 관련 데이터 삭제
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('autoLogin');
      await prefs.remove('userPassword');

      // 선택사항: 아이디 저장도 초기화하려면 아래 주석 해제
      // await prefs.remove('userId');
      // await prefs.remove('saveId');

      print('✅ 로그아웃 완료');

      // 로그인 화면으로 이동
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('❌ 로그아웃 중 오류 발생: $e');
      if (mounted) {
        showToast(context, message: '로그아웃 중 오류가 발생했습니다: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingItem(
              icon: Icons.dark_mode,
              title: '다크 모드',
              subtitle: '어두운 테마를 사용합니다',
              trailing: GestureDetector(
                onTap: _toggleDarkMode,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Container(
                      width: 56,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _colorAnimation.value,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Stack(
                        children: [
                          AnimatedPositioned(
                            duration: const Duration(),
                            curve: Curves.easeInOut,
                            left: _slideAnimation.value * 24,
                            top: 2,
                            bottom: 2,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildSettingItem(
              icon: Icons.refresh,
              title: '드롭다운 캐시 초기화',
              subtitle: '캐시를 초기화하여 최신 데이터를 불러옵니다',
              onTap: () {
                // 캐시 초기화
                CodeDataCache.clearCache();
                print('✅ 드롭다운 캐시가 초기화되었습니다.');

                showToast(context, message: '드롭다운 캐시가 초기화되었습니다.');
              },
            ),
            const SizedBox(height: 20),
            _buildSettingItem(
              icon: Icons.logout,
              title: '로그아웃',
              subtitle: '현재 계정에서 로그아웃합니다',
              onTap: () async {
                // 로그아웃 확인 다이얼로그
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('로그아웃'),
                    content: const Text('정말 로그아웃 하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          backgroundColor: context.colors.gray30,
                          foregroundColor: context.colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              8.0,
                            ), // 원하는 둥글기 정도 설정
                          ),
                        ),
                        child: Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(
                          foregroundColor: context.colors.white,
                          backgroundColor: context.colors.selectedColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text('로그아웃'),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true) {
                  await _handleLogout();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 설정 아이템 빌더
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: colors.textSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 16), trailing],
          ],
        ),
      ),
    );
  }
}
