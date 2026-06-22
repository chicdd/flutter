// 소셜 서비스(로컬) — 친구 / 레벨 랭킹 / 파티(경험치 공유).
// 계정·진행상황이 로컬(SharedPreferences)에 모두 있으므로 같은 기기 내에서 완전히 동작한다.
// 파티: 내 처치 경험치의 일부를 파티원의 저장 프로필에 분배(누적 후 flush). 파티 중엔 본인도 보너스.
import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/account.dart';
import '../state/player_profile.dart';
import 'auth_service.dart';
import 'nakama_service.dart';
import 'profile_store.dart';

class FriendInfo {
  final String id;
  final String nickname;
  final int level;
  final bool inParty;
  // 이 기기에 진행상황이 없는(다른 기기에서 가입한) 친구는 레벨을 알 수 없다.
  final bool levelKnown;
  const FriendInfo(this.id, this.nickname, this.level, this.inParty, {this.levelKnown = true});
}

// 친구 목록 저장 형식 — 닉네임도 같이 보관해야 다른 기기 가입 계정도 표시 가능.
class _FriendRef {
  final String id;
  final String nickname;
  const _FriendRef(this.id, this.nickname);

  Map<String, dynamic> toJson() => {'id': id, 'nickname': nickname};

  static _FriendRef fromJson(dynamic j) {
    if (j is String) return _FriendRef(j, j); // 이전 버전 데이터(ID만 저장)
    final m = j as Map<String, dynamic>;
    return _FriendRef(m['id'] as String, (m['nickname'] as String?) ?? m['id'] as String);
  }
}

class RankEntry {
  final int rank;
  final String id;
  final String nickname;
  final int level;
  final int exp;
  final bool isMe;
  const RankEntry(this.rank, this.id, this.nickname, this.level, this.exp, this.isMe);
}

class SocialService {
  final String myId;
  // 다른 기기에서 가입한 계정도 찾을 수 있게 Nakama 를 전역 디렉터리로 사용(best-effort).
  final NakamaService? net;
  SocialService(this.myId, {this.net});

  // 세션 파티(계정 ID 목록, 본인 제외) + 분배 보너스.
  static const double selfPartyBonus = 0.10; // 파티 중 본인 경험치 +10%
  static const double shareRate = 0.30; // 파티원에게 분배되는 비율

  final List<String> party = [];
  final Map<String, int> _partyLevels = {}; // 파티원 레벨(멘토 캐치업 계산)
  final Map<String, int> _pendingExp = {}; // 미반영 분배 경험치
  int _myLevel = 1;

  bool get inParty => party.isNotEmpty;
  int get partyMaxLevel => _partyLevels.values.isEmpty ? 1 : _partyLevels.values.reduce(max);

  void setMyLevel(int lv) => _myLevel = lv;

  // 파티 보너스 + 멘토 캐치업: 파티 최고 레벨보다 낮을수록 경험치 추가(고저레벨 함께 성장).
  double get selfExpMultiplier {
    if (!inParty) return 1.0;
    final gap = (partyMaxLevel - _myLevel).clamp(0, 30);
    final catchup = (gap * 0.08).clamp(0.0, 1.2); // 최대 +120%
    return 1 + selfPartyBonus + catchup;
  }

  // ── 친구 ──
  String _friendsKey() => 'friends_$myId';

  Future<List<_FriendRef>> _friendIds() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_friendsKey());
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List).map(_FriendRef.fromJson).toList();
  }

  Future<void> _saveFriendIds(List<_FriendRef> refs) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_friendsKey(), jsonEncode(refs.map((r) => r.toJson()).toList()));
  }

  // 전역 디렉터리(서버 스토리지) — 모든 기기의 가입자(id/nickname/level/exp). best-effort.
  Future<List<({String id, String nickname, int level, int exp})>> _directory() async {
    if (net == null) return const [];
    return net!.listDirectory();
  }

  // ID 또는 닉네임으로 친구 추가(전역). 로컬 → 전역 디렉터리 → 서버 username 순으로 조회.
  Future<String?> addFriend(String input) async {
    final q = input.trim();
    if (q.isEmpty) return 'ID 또는 닉네임을 입력하세요.';
    final ql = q.toLowerCase();

    var acc = await AuthService.instance.getAccount(q);
    String? foundId = acc?.id;
    String? foundNickname = acc?.nickname;

    if (foundId == null) {
      final byNick = (await AuthService.instance.allAccounts())
          .where((a) => a.nickname.toLowerCase() == ql)
          .cast<Account?>()
          .firstWhere((a) => true, orElse: () => null);
      foundId = byNick?.id;
      foundNickname = byNick?.nickname;
    }

    // 전역 디렉터리에서 ID 정확 → 닉네임 정확 → 부분일치 순으로 탐색.
    if (foundId == null) {
      final dir = await _directory();
      ({String id, String nickname, int level, int exp})? hit;
      for (final e in dir) {
        if (e.id.toLowerCase() == ql) { hit = e; break; }
      }
      hit ??= dir.where((e) => e.nickname.toLowerCase() == ql).cast<({String id, String nickname, int level, int exp})?>().firstWhere((_) => true, orElse: () => null);
      hit ??= dir.where((e) => e.nickname.toLowerCase().contains(ql) || e.id.toLowerCase().contains(ql)).cast<({String id, String nickname, int level, int exp})?>().firstWhere((_) => true, orElse: () => null);
      if (hit != null) {
        foundId = hit.id;
        foundNickname = hit.nickname;
      }
    }

    if (foundId == null && net != null) {
      final remote = await net!.findUserById(q);
      if (remote != null) {
        foundId = remote.id;
        foundNickname = remote.nickname;
      }
    }

    if (foundId == null) return '해당 ID/닉네임의 유저가 없습니다.';
    if (foundId == myId) return '자기 자신은 추가할 수 없습니다.';
    final refs = await _friendIds();
    if (refs.any((r) => r.id == foundId)) return '이미 친구입니다.';
    refs.add(_FriendRef(foundId, foundNickname ?? foundId));
    await _saveFriendIds(refs);
    return null; // 성공
  }

  // 닉네임/ID 부분 일치 유저 검색(전역). 로컬 계정 + 서버 전역 디렉터리를 합쳐 검색한다.
  Future<List<FriendInfo>> searchAccounts(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final friendIds = (await _friendIds()).map((r) => r.id).toSet();
    final seen = <String>{};
    final out = <FriendInfo>[];

    // 1) 로컬 계정(이 기기 가입자) — 레벨 정확.
    for (final a in await AuthService.instance.allAccounts()) {
      if (a.id == myId || friendIds.contains(a.id)) continue;
      if (a.nickname.toLowerCase().contains(q) || a.id.toLowerCase().contains(q)) {
        final lv = await ProfileStore.levelOf(a.id);
        out.add(FriendInfo(a.id, a.nickname, lv.level, false));
        seen.add(a.id);
      }
    }

    // 2) 전역 디렉터리(다른 기기 가입자 포함) — 닉네임 부분검색이 전역으로 동작.
    for (final e in await _directory()) {
      if (e.id == myId || friendIds.contains(e.id) || seen.contains(e.id)) continue;
      if (e.nickname.toLowerCase().contains(q) || e.id.toLowerCase().contains(q)) {
        out.add(FriendInfo(e.id, e.nickname, e.level, false));
        seen.add(e.id);
      }
    }

    out.sort((a, b) => b.level.compareTo(a.level));
    return out;
  }

  Future<void> removeFriend(String id) async {
    final refs = await _friendIds();
    refs.removeWhere((r) => r.id == id);
    await _saveFriendIds(refs);
    party.remove(id);
  }

  Future<List<FriendInfo>> friends() async {
    final refs = await _friendIds();
    if (refs.isEmpty) return [];
    // 전역 디렉터리로 친구 레벨을 동기화(다른 기기 친구도 레벨 표시).
    final dir = {for (final e in await _directory()) e.id: e};
    final out = <FriendInfo>[];
    for (final r in refs) {
      final acc = await AuthService.instance.getAccount(r.id);
      final raw = await ProfileStore.loadRaw(r.id);
      final remote = dir[r.id];
      final localLv = await ProfileStore.levelOf(r.id);
      final level = remote?.level ?? localLv.level;
      out.add(FriendInfo(
        r.id,
        remote?.nickname ?? acc?.nickname ?? r.nickname,
        level,
        party.contains(r.id),
        levelKnown: remote != null || acc != null || raw != null,
      ));
    }
    out.sort((a, b) => b.level.compareTo(a.level));
    return out;
  }

  // ── 레벨 랭킹(전역) ──
  Future<List<RankEntry>> ranking() async {
    await flush(); // 분배분 반영 후 집계
    // 로컬 계정 + 전역 디렉터리를 합쳐 전역 랭킹을 만든다(id 중복 제거, 더 높은 레벨 우선).
    final rows = <String, ({String id, String nickname, int level, int exp})>{};
    for (final a in await AuthService.instance.allAccounts()) {
      final lv = await ProfileStore.levelOf(a.id);
      rows[a.id] = (id: a.id, nickname: a.nickname, level: lv.level, exp: lv.exp);
    }
    for (final e in await _directory()) {
      final cur = rows[e.id];
      if (cur == null || e.level > cur.level || (e.level == cur.level && e.exp > cur.exp)) {
        rows[e.id] = (id: e.id, nickname: e.nickname, level: e.level, exp: e.exp);
      }
    }
    final list = rows.values.toList()
      ..sort((x, y) {
        final c = y.level.compareTo(x.level);
        return c != 0 ? c : y.exp.compareTo(x.exp);
      });
    return [
      for (var i = 0; i < list.length; i++)
        RankEntry(i + 1, list[i].id, list[i].nickname, list[i].level, list[i].exp, list[i].id == myId),
    ];
  }

  // ── 파티 ──
  void addToParty(String id, int level) {
    if (id != myId && !party.contains(id)) {
      party.add(id);
      _partyLevels[id] = level;
    }
  }

  void removeFromParty(String id) {
    party.remove(id);
    _partyLevels.remove(id);
  }

  // 처치 시 호출: 파티원에게 분배할 경험치를 누적.
  void shareExp(int baseExp) {
    if (party.isEmpty) return;
    final each = (baseExp * shareRate).round();
    if (each <= 0) return;
    for (final id in party) {
      _pendingExp.update(id, (v) => v + each, ifAbsent: () => each);
    }
  }

  // 누적 분배분을 각 파티원의 저장 프로필에 반영.
  Future<void> flush() async {
    if (_pendingExp.isEmpty) return;
    final pending = Map<String, int>.from(_pendingExp);
    _pendingExp.clear();
    for (final entry in pending.entries) {
      final raw = await ProfileStore.loadRaw(entry.key);
      final p = PlayerProfile();
      if (raw != null) p.loadJson(raw);
      p.gainExp(entry.value);
      await ProfileStore.save(entry.key, p);
    }
  }
}
