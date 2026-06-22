// 로컬 우선 인증 서비스 (SharedPreferences 저장).
// ID/닉네임은 평문, 비밀번호·힌트답변은 솔트+SHA-256 해시. 비밀번호는 복호화 불가.
// 비밀번호 찾기 = 힌트 답변 검증 후 "재설정"(새 비밀번호 입력). 추후 서버 RPC 백엔드로 교체 용이.
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/account.dart';

class AuthResult {
  final bool ok;
  final String message;
  final Account? account;
  const AuthResult(this.ok, this.message, [this.account]);
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _kAccounts = 'auth_accounts';
  static const _kCurrent = 'auth_current_user';

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _sp async => _prefs ??= await SharedPreferences.getInstance();

  // ── 해시 유틸 ──
  String _genSalt() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    return base64Encode(bytes);
  }

  String _hash(String value, String salt) =>
      sha256.convert(utf8.encode('$salt::$value')).toString();

  // ── 저장소 ──
  Future<Map<String, Account>> _loadAll() async {
    final sp = await _sp;
    final raw = sp.getString(_kAccounts);
    if (raw == null || raw.isEmpty) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, Account.fromJson(v as Map<String, dynamic>)));
  }

  Future<void> _saveAll(Map<String, Account> accounts) async {
    final sp = await _sp;
    await sp.setString(_kAccounts, jsonEncode(accounts.map((k, v) => MapEntry(k, v.toJson()))));
  }

  String _norm(String s) => s.trim();
  String _normKey(String s) => s.trim().toLowerCase();

  // ── 회원가입 ──
  Future<AuthResult> register({
    required String id,
    required String nickname,
    required String password,
    required String passwordConfirm,
    required String hintQuestion,
    required String hintAnswer,
  }) async {
    final cid = _norm(id);
    final cnick = _norm(nickname);
    if (cid.length < 4) return const AuthResult(false, 'ID는 4자 이상이어야 합니다.');
    if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(cid)) {
      return const AuthResult(false, 'ID는 영문/숫자/밑줄(_)만 사용할 수 있습니다.');
    }
    if (cnick.isEmpty) return const AuthResult(false, '닉네임을 입력하세요.');
    if (password.length < 4) return const AuthResult(false, '비밀번호는 4자 이상이어야 합니다.');
    if (password != passwordConfirm) return const AuthResult(false, '비밀번호가 일치하지 않습니다.');
    if (_norm(hintQuestion).isEmpty || _norm(hintAnswer).isEmpty) {
      return const AuthResult(false, '비밀번호 힌트 질문과 답변을 입력하세요.');
    }

    final all = await _loadAll();
    if (all.containsKey(cid)) return const AuthResult(false, '이미 사용 중인 ID입니다.');

    final salt = _genSalt();
    final account = Account(
      id: cid,
      nickname: cnick,
      salt: salt,
      passwordHash: _hash(password, salt),
      hintQuestion: _norm(hintQuestion),
      hintAnswerHash: _hash(_normKey(hintAnswer), salt),
    );
    all[cid] = account;
    await _saveAll(all);
    return AuthResult(true, '가입이 완료되었습니다.', account);
  }

  // ── 로그인 ──
  Future<AuthResult> login(String id, String password) async {
    final cid = _norm(id);
    final all = await _loadAll();
    final acc = all[cid];
    if (acc == null) return const AuthResult(false, '존재하지 않는 ID입니다.');
    if (acc.passwordHash != _hash(password, acc.salt)) {
      return const AuthResult(false, '비밀번호가 올바르지 않습니다.');
    }
    final sp = await _sp;
    await sp.setString(_kCurrent, cid);
    return AuthResult(true, '환영합니다, ${acc.nickname}님!', acc);
  }

  // ── 아이디 찾기(닉네임) ──
  Future<List<String>> findIdsByNickname(String nickname) async {
    final key = _normKey(nickname);
    if (key.isEmpty) return [];
    final all = await _loadAll();
    return all.values.where((a) => _normKey(a.nickname) == key).map((a) => a.id).toList();
  }

  // ── 비밀번호 찾기(재설정) ──
  Future<String?> getHintQuestion(String id) async {
    final all = await _loadAll();
    return all[_norm(id)]?.hintQuestion;
  }

  // 힌트 답변 검증(맞으면 재설정 단계로).
  Future<AuthResult> verifyHint(String id, String hintAnswer) async {
    final all = await _loadAll();
    final acc = all[_norm(id)];
    if (acc == null) return const AuthResult(false, '존재하지 않는 ID입니다.');
    if (acc.hintAnswerHash != _hash(_normKey(hintAnswer), acc.salt)) {
      return const AuthResult(false, '힌트 답변이 일치하지 않습니다.');
    }
    return const AuthResult(true, '확인되었습니다. 새 비밀번호를 입력하세요.');
  }

  // 비밀번호 재설정(솔트 유지).
  Future<AuthResult> resetPassword({
    required String id,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    if (newPassword.length < 4) return const AuthResult(false, '비밀번호는 4자 이상이어야 합니다.');
    if (newPassword != newPasswordConfirm) return const AuthResult(false, '비밀번호가 일치하지 않습니다.');
    final all = await _loadAll();
    final acc = all[_norm(id)];
    if (acc == null) return const AuthResult(false, '존재하지 않는 ID입니다.');
    all[acc.id] = acc.copyWith(passwordHash: _hash(newPassword, acc.salt));
    await _saveAll(all);
    return const AuthResult(true, '비밀번호가 변경되었습니다. 새 비밀번호로 로그인하세요.');
  }

  // ── 조회(친구/랭킹용) ──
  Future<List<Account>> allAccounts() async => (await _loadAll()).values.toList();
  Future<Account?> getAccount(String id) async => (await _loadAll())[_norm(id)];

  // ── 세션 ──
  Future<Account?> currentAccount() async {
    final sp = await _sp;
    final id = sp.getString(_kCurrent);
    if (id == null) return null;
    final all = await _loadAll();
    return all[id];
  }

  Future<void> logout() async {
    final sp = await _sp;
    await sp.remove(_kCurrent);
  }
}
