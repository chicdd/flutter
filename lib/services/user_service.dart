import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/login_user.dart';

/// 로그인한 사용자 정보를 관리하는 서비스
class UserService {
  static const String _userKey = 'current_user';
  static const String _regionCodeKey = 'user_region_code';

  static LoginUser? _currentUser;

  /// 현재 로그인한 사용자 정보 조회
  static LoginUser? get currentUser => _currentUser;

  /// 현재 사용자의 지역코드 조회
  static String? get regionCode => _currentUser?.resionCode;

  /// 사용자 정보 저장 (로그인 시)
  static Future<void> saveUser(LoginUser user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
    await prefs.setString(_regionCodeKey, user.resionCode);
  }

  /// 저장된 사용자 정보 불러오기
  static Future<LoginUser?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      final userMap = json.decode(userJson) as Map<String, dynamic>;
      _currentUser = LoginUser.fromJson(userMap);
      return _currentUser;
    }
    return null;
  }

  /// 사용자 정보 삭제 (로그아웃 시)
  static Future<void> clearUser() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_regionCodeKey);
  }

  /// 저장된 지역코드 조회
  static Future<String?> getRegionCode() async {
    if (_currentUser != null) {
      return _currentUser!.resionCode;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_regionCodeKey);
  }
}
