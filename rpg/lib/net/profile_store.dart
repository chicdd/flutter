// 계정별 진행상황(PlayerProfile) 저장/복원 — SharedPreferences.
// 랭킹/파티 경험치 공유가 의미를 가지려면 각 계정의 레벨/경험치가 영속돼야 한다.
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../state/player_profile.dart';

class ProfileStore {
  ProfileStore._();

  static String _key(String accountId) => 'profile_$accountId';

  static Future<void> save(String accountId, PlayerProfile p) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key(accountId), jsonEncode(p.toJson()));
  }

  static Future<Map<String, dynamic>?> loadRaw(String accountId) async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_key(accountId));
    if (s == null || s.isEmpty) return null;
    return jsonDecode(s) as Map<String, dynamic>;
  }

  // 전체 프로필 없이 레벨/경험치만 빠르게(랭킹용).
  static Future<({int level, int exp})> levelOf(String accountId) async {
    final j = await loadRaw(accountId);
    return (
      level: (j?['level'] as num?)?.toInt() ?? 1,
      exp: (j?['exp'] as num?)?.toInt() ?? 0,
    );
  }
}
