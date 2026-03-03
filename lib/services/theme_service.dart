import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 다크모드 상태를 전역으로 관리하는 서비스
class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  static const String _themeKey = 'isDarkMode';

  factory ThemeService() {
    return _instance;
  }

  ThemeService._internal();

  bool _isDarkMode = false;
  bool _isInitialized = false;

  bool get isDarkMode => _isDarkMode;
  bool get isInitialized => _isInitialized;

  /// 저장된 테마 설정 불러오기
  Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('테마 불러오기 오류: $e');
      _isInitialized = true;
    }
  }

  /// 테마 설정 저장
  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
    } catch (e) {
      print('테마 저장 오류: $e');
    }
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _saveTheme();
    notifyListeners();
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    _saveTheme();
    notifyListeners();
  }
}
