// 서버 권위 인증 서비스. 계정(ID/닉네임/비밀번호/힌트)은 클라이언트에 저장하지 않고 전부 Nakama 가 보관한다.
//  - 비밀번호: Nakama 계정 시스템(authenticateEmail, id→합성 이메일 1:1)이 직접 해시·검증.
//  - 비밀번호 힌트: 질문+솔트는 공개 스토리지(비번찾기 1단계엔 로그인 세션이 없어 공개 필요),
//    답변 해시는 그 누구도 못 읽는 잠긴 스토리지(서버 RPC 만 비교 가능)에 보관.
//  - 자동로그인: SharedPreferences 에는 "재사용 가능한 세션 토큰"만 캐시한다(비밀번호 아님 — 토큰은
//    만료/폐기 가능하고, 그 자체로는 비밀번호를 알아낼 수 없다).
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/account.dart';
import 'nakama_service.dart';

class AuthResult {
  final bool ok;
  final String message;
  final Account? account;
  const AuthResult(this.ok, this.message, [this.account]);
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _kSessionCache = 'auth_session_cache';

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _sp async => _prefs ??= await SharedPreferences.getInstance();

  // ── 해시 유틸(비밀번호 힌트 답변에만 사용 — 비밀번호 자체는 Nakama 가 처리) ──
  String _genSalt() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    return base64Encode(bytes);
  }

  String _hash(String value, String salt) =>
      sha256.convert(utf8.encode('$salt::$value')).toString();

  String _norm(String s) => s.trim();
  String _normKey(String s) => s.trim().toLowerCase();

  String _authErrorMessage(Object e, {required bool isRegister}) {
    int? code;
    String? serverMsg;
    try {
      final dyn = e as dynamic;
      code = dyn.code as int?;
      serverMsg = dyn.message as String?;
    } catch (_) {
      // GrpcError/ResponseError 가 아닌 예외(주로 네트워크 오류) — 아래 기본 메시지로 처리.
    }
    if (isRegister) {
      if (code == 6 || code == 16) return '이미 사용 중인 ID입니다.';
      if (code == 3) return serverMsg ?? '입력값을 확인해주세요.';
    } else {
      if (code == 5) return '존재하지 않는 ID입니다.';
      if (code == 16) return '비밀번호가 올바르지 않습니다.';
    }
    return '서버에 연결할 수 없습니다. 잠시 후 다시 시도해주세요.';
  }

  String _rpcErrorMessage(Object e) =>
      e is NakamaRpcException ? e.message : '서버에 연결할 수 없습니다. 잠시 후 다시 시도해주세요.';

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
    if (password.length < 8) return const AuthResult(false, '비밀번호는 8자 이상이어야 합니다.');
    if (password != passwordConfirm) return const AuthResult(false, '비밀번호가 일치하지 않습니다.');
    if (_norm(hintQuestion).isEmpty || _norm(hintAnswer).isEmpty) {
      return const AuthResult(false, '비밀번호 힌트 질문과 답변을 입력하세요.');
    }

    final salt = _genSalt();
    try {
      await NakamaService.instance.registerAccount(
        id: cid,
        password: password,
        nickname: cnick,
        hintQuestion: _norm(hintQuestion),
        hintSalt: salt,
        hintAnswerHash: _hash(_normKey(hintAnswer), salt),
      );
    } catch (e) {
      return AuthResult(false, _authErrorMessage(e, isRegister: true));
    }
    await _cacheSession();
    return AuthResult(true, '가입이 완료되었습니다.', Account(id: cid, nickname: cnick));
  }

  // ── 로그인 ──
  Future<AuthResult> login(String id, String password) async {
    final cid = _norm(id);
    if (cid.isEmpty) return const AuthResult(false, '존재하지 않는 ID입니다.');
    if (password.isEmpty) return const AuthResult(false, '비밀번호를 입력하세요.');
    try {
      final r = await NakamaService.instance.loginAccount(id: cid, password: password);
      final account = Account(id: r.id, nickname: r.nickname);
      await _cacheSession();
      return AuthResult(true, '환영합니다, ${account.nickname}님!', account);
    } catch (e) {
      return AuthResult(false, _authErrorMessage(e, isRegister: false));
    }
  }

  // ── 아이디 찾기(닉네임, 전역) ──
  Future<List<String>> findIdsByNickname(String nickname) async {
    await NakamaService.instance.ensureGuestSession();
    return NakamaService.instance.findIdsByNickname(nickname);
  }

  // ── 비밀번호 찾기(재설정) ──
  Future<String?> getHintQuestion(String id) async {
    final cid = _norm(id);
    if (cid.isEmpty) return null;
    await NakamaService.instance.ensureGuestSession();
    final hint = await NakamaService.instance.fetchHintQuestion(cid);
    return hint?.question;
  }

  // 힌트 답변 검증(맞으면 재설정 단계로).
  Future<AuthResult> verifyHint(String id, String hintAnswer) async {
    final cid = _norm(id);
    await NakamaService.instance.ensureGuestSession();
    final hint = await NakamaService.instance.fetchHintQuestion(cid);
    if (hint == null) return const AuthResult(false, '존재하지 않는 ID입니다.');
    try {
      await NakamaService.instance.verifyHintAnswer(cid, _hash(_normKey(hintAnswer), hint.salt));
      return const AuthResult(true, '확인되었습니다. 새 비밀번호를 입력하세요.');
    } catch (e) {
      return AuthResult(false, _rpcErrorMessage(e));
    }
  }

  // 비밀번호 재설정 — 힌트 답변을 다시 받아 서버에서 재검증한다(이전 단계의 "확인됨"을 그대로 믿지 않음).
  Future<AuthResult> resetPassword({
    required String id,
    required String hintAnswer,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    if (newPassword.length < 8) return const AuthResult(false, '비밀번호는 8자 이상이어야 합니다.');
    if (newPassword != newPasswordConfirm) return const AuthResult(false, '비밀번호가 일치하지 않습니다.');
    final cid = _norm(id);
    await NakamaService.instance.ensureGuestSession();
    final hint = await NakamaService.instance.fetchHintQuestion(cid);
    if (hint == null) return const AuthResult(false, '존재하지 않는 ID입니다.');
    try {
      await NakamaService.instance.resetPasswordWithHint(
        cid,
        _hash(_normKey(hintAnswer), hint.salt),
        newPassword,
      );
      return const AuthResult(true, '비밀번호가 변경되었습니다. 새 비밀번호로 로그인하세요.');
    } catch (e) {
      return AuthResult(false, _rpcErrorMessage(e));
    }
  }

  // ── 조회(친구/랭킹용) — 서버에 등록된 계정을 ID로 정확히 조회(전역, 기기 무관). ──
  Future<Account?> getAccount(String id) async {
    final cid = _norm(id);
    if (cid.isEmpty) return null;
    await NakamaService.instance.ensureGuestSession();
    final r = await NakamaService.instance.findUserById(cid);
    return r == null ? null : Account(id: r.id, nickname: r.nickname);
  }

  // ── 세션(자동로그인) ──
  Future<void> _cacheSession() async {
    final session = NakamaService.instance.session;
    if (session == null) return;
    final sp = await _sp;
    await sp.setString(
      _kSessionCache,
      jsonEncode({
        'token': session.token,
        'refresh': session.refreshToken,
        'uid': session.userId,
        'exp': session.expiresAt.toIso8601String(),
        'rexp': session.refreshExpiresAt.toIso8601String(),
      }),
    );
  }

  Future<Account?> currentAccount() async {
    final sp = await _sp;
    final raw = sp.getString(_kSessionCache);
    if (raw == null || raw.isEmpty) return null;

    Map<String, dynamic> cached;
    try {
      cached = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      await sp.remove(_kSessionCache);
      return null;
    }

    bool restored;
    try {
      restored = await NakamaService.instance.restoreSession(
        token: cached['token'] as String,
        refreshToken: cached['refresh'] as String,
        userId: cached['uid'] as String,
        expiresAt: DateTime.parse(cached['exp'] as String),
        refreshExpiresAt: DateTime.parse(cached['rexp'] as String),
      );
    } catch (_) {
      restored = false;
    }
    if (!restored) {
      await sp.remove(_kSessionCache);
      return null;
    }
    await _cacheSession(); // 세션 리프레시는 토큰을 회전시키므로 갱신된 토큰으로 다시 캐시.

    final identity = await NakamaService.instance.fetchCurrentIdentity();
    if (identity == null) return null;
    return Account(id: identity.id, nickname: identity.nickname);
  }

  Future<void> logout() async {
    final sp = await _sp;
    await sp.remove(_kSessionCache);
  }
}
