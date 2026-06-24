// Nakama 클라이언트 래퍼 (§9 net). RPC 호출 + 세션 관리.
// 경제 로직 없음: 모든 변경은 서버 RPC 로 위임하고 결과를 표시만 한다(§3).
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:nakama/nakama.dart';

import '../models/drop_result.dart';
import '../models/instance.dart';
import '../models/inventory.dart';

class NakamaRpcException implements Exception {
  final String message;
  final String? code;
  NakamaRpcException(this.message, [this.code]);
  @override
  String toString() => 'NakamaRpcException($code): $message';
}

class NakamaService {
  NakamaService._();
  static final NakamaService instance = NakamaService._();

  // 접속 대상 Nakama HTTP API 호스트.
  //  - 원격 서버: 'chic33.duckdns.org' (포트 7350 이 방화벽/보안그룹에서 열려 있어야 함)
  //  - 로컬 도커: '127.0.0.1'
  //  - 안드로이드 에뮬레이터에서 로컬 도커 접속 시: '10.0.2.2'
  static const String host = 'chic33.duckdns.org';
  static const String serverKey = 'defaultkey';
  static const int httpPort = 7350;
  static const int grpcPort = 7349;

  // MVP 개발용 고정 디바이스 ID(한 신원으로 경제 테스트). 거래 테스트엔 2개 빌드/ID 사용.
  static const String defaultDeviceId = 'rpg-dev-device-0001';

  NakamaBaseClient? _client;
  Session? _session;

  bool get isConnected => _session != null;
  Session? get session => _session;

  void _ensureClient() {
    _client ??= getNakamaClient(
      host: host,
      serverKey: serverKey,
      httpPort: httpPort,
      grpcPort: grpcPort,
      ssl: false,
    );
  }

  Future<void> connect({String deviceId = defaultDeviceId, String? username}) async {
    _ensureClient();
    _session = await _client!.authenticateDevice(
      deviceId: deviceId,
      create: true,
      username: username,
    );
  }

  // ── 계정 인증(이메일+비밀번호) ──
  // id → 합성 이메일(<id>@rpg.local) 1:1. 비밀번호는 Nakama 계정 시스템이 직접 해시·검증하므로
  // 클라/서버 어느 쪽도 평문·해시를 별도로 저장하지 않는다. ID 중복 가입은 Nakama 의 이메일/유저네임
  // 유일성 제약이 그대로 막아준다.
  static String authEmailFor(String id) => '$id@rpg.local';

  static const String _hintCollection = 'auth_hint';
  static const String _hintQuestionKey = 'q'; // {q, salt} — publicRead(비번찾기 1단계는 로그인 전이라 공개 필요)
  static const String _hintAnswerKey = 'a'; // {a} — noRead/noWrite(가입 후 그 누구도 못 읽음, 서버 RPC 전용)

  // 비로그인 상태(아이디/비밀번호 찾기)에도 조회·RPC 호출엔 세션이 필요하다. 어느 게스트로 접속하든
  // 검증 로직은 대상 id 기준으로 동작하므로 신원 자체는 의미 없다(전송 수단일 뿐).
  static const String guestDeviceId = 'rpg-auth-guest';
  Future<void> ensureGuestSession() async {
    if (isConnected) return;
    await connect(deviceId: guestDeviceId);
  }

  // 회원가입: Nakama 계정 생성(비밀번호는 서버가 보관) + 닉네임 설정 + 비번 힌트 저장 + 전역 디렉터리 등록.
  Future<void> registerAccount({
    required String id,
    required String password,
    required String nickname,
    required String hintQuestion,
    required String hintSalt,
    required String hintAnswerHash,
  }) async {
    _ensureClient();
    final session = await _client!.authenticateEmail(
      email: authEmailFor(id),
      password: password,
      username: id,
      create: true,
    );
    _session = session;
    await _client!.updateAccount(session: session, username: id, displayName: nickname);
    await _client!.writeStorageObjects(session: session, objects: [
      StorageObjectWrite(
        collection: _hintCollection,
        key: _hintQuestionKey,
        value: jsonEncode({'q': hintQuestion, 'salt': hintSalt}),
        permissionRead: StorageReadPermission.publicRead,
        permissionWrite: StorageWritePermission.ownerWrite,
      ),
      StorageObjectWrite(
        collection: _hintCollection,
        key: _hintAnswerKey,
        value: jsonEncode({'a': hintAnswerHash}),
        permissionRead: StorageReadPermission.noRead,
        permissionWrite: StorageWritePermission.noWrite,
      ),
    ]);
    await publishDirectory(id: id, nickname: nickname, level: 1, exp: 0);
  }

  // 로그인: username+password 인증(이메일 불필요 — Nakama 가 비밀번호를 직접 검증).
  Future<({String id, String nickname})> loginAccount({
    required String id,
    required String password,
  }) async {
    _ensureClient();
    final session = await _client!.authenticateEmail(
      username: id,
      password: password,
      create: false,
    );
    _session = session;
    return _fetchIdentity(session, fallbackId: id);
  }

  Future<({String id, String nickname})> _fetchIdentity(Session session, {required String fallbackId}) async {
    final account = await _client!.getAccount(session);
    final nickname = (account.user.displayName != null && account.user.displayName!.isNotEmpty)
        ? account.user.displayName!
        : fallbackId;
    return (id: account.user.username ?? fallbackId, nickname: nickname);
  }

  // 현재 세션의 신원(자동로그인 복원 후 호출).
  Future<({String id, String nickname})?> fetchCurrentIdentity() async {
    final client = _client;
    final session = _session;
    if (client == null || session == null) return null;
    try {
      return await _fetchIdentity(session, fallbackId: session.userId);
    } catch (_) {
      return null;
    }
  }

  // 자동로그인용 세션 캐시 복원(평문 비밀번호 아님 — 만료/폐기 가능한 토큰만 다룬다).
  Future<bool> restoreSession({
    required String token,
    required String refreshToken,
    required String userId,
    required DateTime expiresAt,
    required DateTime refreshExpiresAt,
  }) async {
    _ensureClient();
    try {
      final cached = Session(
        token: token,
        refreshToken: refreshToken,
        created: false,
        vars: const {},
        userId: userId,
        expiresAt: expiresAt,
        refreshExpiresAt: refreshExpiresAt,
      );
      _session = await _client!.sessionRefresh(session: cached);
      return true;
    } catch (_) {
      _session = null;
      return false;
    }
  }

  Future<String?> _resolveUserId(String id) async {
    final client = _client;
    final session = _session;
    if (client == null || session == null || id.isEmpty) return null;
    try {
      final users = await client.getUsers(session: session, ids: const [], usernames: [id]);
      if (users.isEmpty) return null;
      return users.first.id;
    } catch (_) {
      return null;
    }
  }

  // 비밀번호 찾기 1단계: 힌트 질문 + 솔트(공개 저장소 — 답변 해시는 별도로 잠겨있어 여기 없음).
  Future<({String question, String salt})?> fetchHintQuestion(String id) async {
    final client = _client;
    final session = _session;
    if (client == null || session == null) return null;
    final uid = await _resolveUserId(id);
    if (uid == null) return null;
    try {
      final res = await client.readStorageObjects(
        session: session,
        objectIds: [StorageObjectId(collection: _hintCollection, key: _hintQuestionKey, userId: uid)],
      );
      if (res.isEmpty) return null;
      final j = jsonDecode(res.first.value) as Map<String, dynamic>;
      return (question: (j['q'] as String?) ?? '', salt: (j['salt'] as String?) ?? '');
    } catch (_) {
      return null;
    }
  }

  // 비밀번호 찾기 2단계: 힌트 답변 해시 검증(서버 권위 RPC — 정답 해시는 클라가 읽을 수 없음).
  Future<void> verifyHintAnswer(String id, String hintAnswerHash) =>
      _rpc('rpc_auth_verify_hint', {'id': id, 'hint_answer_hash': hintAnswerHash});

  // 비밀번호 찾기 3단계: 답변 재검증 + 비밀번호 재설정(서버 권위 RPC — unlinkEmail/linkEmail 은 서버 런타임 전용).
  Future<void> resetPasswordWithHint(String id, String hintAnswerHash, String newPassword) =>
      _rpc('rpc_auth_reset_password', {
        'id': id,
        'hint_answer_hash': hintAnswerHash,
        'new_password': newPassword,
      });

  // 닉네임으로 ID 찾기 — 전역 디렉터리(가입 시 등록됨)에서 정확히 일치하는 닉네임 검색.
  Future<List<String>> findIdsByNickname(String nickname) async {
    final key = nickname.trim().toLowerCase();
    if (key.isEmpty) return const [];
    final dir = await listDirectory();
    return dir.where((e) => e.nickname.trim().toLowerCase() == key).map((e) => e.id).toList();
  }

  // ── 단일 세션(중복 접속 차단) ──
  // 같은 계정으로 동시에 두 곳에서 플레이하지 못하도록, 서버 스토리지에 "세션 락"을
  // 인스턴스ID+타임스탬프로 기록하고 8초마다 하트비트한다. 로그인 시 최근(20초) 락이
  // 다른 인스턴스 것이면 거부한다. 같은 프로세스의 재로그인은 같은 instanceId 라 허용.
  static const String _sessionCol = 'sessions';
  static const String _sessionKey = 'lock';
  String? _instanceId;
  Timer? _sessionTimer;

  String _genInstanceId() => '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(0x7FFFFFFF)}';

  Future<({String i, int t})?> _readSessionLock() async {
    final client = _client;
    final session = _session;
    if (client == null || session == null) return null;
    try {
      final res = await client.readStorageObjects(
        session: session,
        objectIds: [StorageObjectId(collection: _sessionCol, key: _sessionKey, userId: session.userId)],
      );
      if (res.isEmpty) return null;
      final j = jsonDecode(res.first.value) as Map<String, dynamic>;
      return (i: (j['i'] as String?) ?? '', t: (j['t'] as num?)?.toInt() ?? 0);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeSessionLock(int ts) async {
    final client = _client;
    final session = _session;
    if (client == null || session == null || _instanceId == null) return;
    try {
      await client.writeStorageObjects(
        session: session,
        objects: [
          StorageObjectWrite(
            collection: _sessionCol,
            key: _sessionKey,
            value: jsonEncode({'i': _instanceId, 't': ts}),
            permissionRead: StorageReadPermission.ownerRead,
            permissionWrite: StorageWritePermission.ownerWrite,
          ),
        ],
      );
    } catch (_) {/* 무시 */}
  }

  // 세션 점유 시도. true=점유 성공, false=이미 다른 인스턴스가 접속중. 오프라인이면 허용(true).
  Future<bool> claimSession() async {
    if (_client == null || _session == null) return true; // 검사 불가 → 허용(솔로)
    _instanceId ??= _genInstanceId();
    final now = DateTime.now().millisecondsSinceEpoch;

    final existing = await _readSessionLock();
    if (existing != null && existing.i != _instanceId && now - existing.t < 20000) {
      return false; // 다른 인스턴스 활성
    }
    await _writeSessionLock(now);
    // 동시 콜드스타트 타이브레이크(나중에 쓴 인스턴스가 승리).
    await Future.delayed(const Duration(milliseconds: 700));
    final after = await _readSessionLock();
    if (after != null && after.i != _instanceId) return false;

    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 8),
        (_) => _writeSessionLock(DateTime.now().millisecondsSinceEpoch));
    return true;
  }

  // 세션 해제(로그아웃/종료) — "내 락"일 때만 삭제(다른 인스턴스 락은 건드리지 않음).
  Future<void> releaseSession() async {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    final client = _client;
    final session = _session;
    if (client == null || session == null || _instanceId == null) return;
    try {
      final cur = await _readSessionLock();
      if (cur == null || cur.i != _instanceId) return; // 내 락이 아니면 보존
      await client.deleteStorageObjects(
        session: session,
        objectIds: [StorageObjectId(collection: _sessionCol, key: _sessionKey)],
      );
    } catch (_) {/* 무시 */}
  }

  // 현재 참가자가 있는 relayed 매치 탐색(같은 오픈월드에 합류하기 위함).
  // relayed 매치는 이름으로 찾을 수 없어 매치 목록 조회로 활성 매치를 찾는다.
  Future<List<Match>> listActiveMatches({int limit = 10}) async {
    final client = _client;
    final session = _session;
    if (client == null || session == null) return const [];
    try {
      return await client.listMatches(
        session: session,
        authoritative: false,
        limit: limit,
        minSize: 1,
      );
    } catch (_) {
      return const [];
    }
  }

  // ── 전역 디렉터리(스토리지) — 풀 온라인 친구검색/랭킹 ──
  // 각 유저가 자기 항목을 publicRead 로 기록하면, 어떤 클라이언트든 전체 목록을
  // 조회해 닉네임 부분검색·전역 랭킹을 만들 수 있다(기기 경계 없음).
  static const String _dirCollection = 'directory';
  static const String _dirKey = 'profile';
  static const String _presCollection = 'world_presence';
  static const String _presKey = 'p';

  String? get userId => _session?.userId;

  // 내 계정 정보를 전역 디렉터리에 기록(레벨/경험치 포함). best-effort.
  Future<void> publishDirectory({
    required String id,
    required String nickname,
    required int level,
    required int exp,
  }) async {
    final client = _client;
    final session = _session;
    if (client == null || session == null) return;
    try {
      await client.writeStorageObjects(
        session: session,
        objects: [
          StorageObjectWrite(
            collection: _dirCollection,
            key: _dirKey,
            value: jsonEncode({'id': id, 'nickname': nickname, 'level': level, 'exp': exp}),
            permissionRead: StorageReadPermission.publicRead,
            permissionWrite: StorageWritePermission.ownerWrite,
          ),
        ],
      );
    } catch (_) {/* 무시 — 로컬 기능은 계속 동작 */}
  }

  // 전역 디렉터리 전체 조회(공개 항목). {id, nickname, level, exp} 목록.
  // Nakama listStorageObjects 는 limit 이 1~100 으로 제한되어 있어(초과 시 서버가 거부) cursor 로 페이지를
  // 이어 모은다. maxResults 는 안전장치(무한 루프 방지)일 뿐 실제 가입자 수와 무관하게 충분히 크게 둔다.
  Future<List<({String id, String nickname, int level, int exp})>> listDirectory({int maxResults = 500}) async {
    final client = _client;
    final session = _session;
    if (client == null || session == null) return const [];
    final out = <({String id, String nickname, int level, int exp})>[];
    String? cursor;
    try {
      do {
        final res = await client.listStorageObjects(
          session: session,
          collection: _dirCollection,
          limit: 100,
          cursor: cursor,
        );
        for (final o in res.objects) {
          try {
            final j = jsonDecode(o.value) as Map<String, dynamic>;
            out.add((
              id: (j['id'] as String?) ?? '',
              nickname: (j['nickname'] as String?) ?? (j['id'] as String? ?? ''),
              level: (j['level'] as num?)?.toInt() ?? 1,
              exp: (j['exp'] as num?)?.toInt() ?? 0,
            ));
          } catch (_) {/* 잘못된 항목 무시 */}
        }
        cursor = res.cursor;
      } while (cursor != null && cursor.isNotEmpty && out.length < maxResults);
      return out;
    } catch (_) {
      return out; // 일부 페이지라도 모인 게 있으면 그것까지는 반환.
    }
  }

  // ── 월드 presence(스토리지) — 매치 합류 좌표 + 전역 맵 점 표시 ──
  Future<void> publishPresence({
    required String matchId,
    required String name,
    required int level,
    required double x,
    required double y,
  }) async {
    final client = _client;
    final session = _session;
    if (client == null || session == null) return;
    try {
      await client.writeStorageObjects(
        session: session,
        objects: [
          StorageObjectWrite(
            collection: _presCollection,
            key: _presKey,
            value: jsonEncode({
              'm': matchId,
              'n': name,
              'l': level,
              'x': x,
              'y': y,
              't': DateTime.now().millisecondsSinceEpoch,
            }),
            permissionRead: StorageReadPermission.publicRead,
            permissionWrite: StorageWritePermission.ownerWrite,
          ),
        ],
      );
    } catch (_) {/* 무시 */}
  }

  // 최근 활성 presence 목록(본인 제외 옵션). 오래된 항목은 호출부에서 ts 로 거른다.
  Future<List<({String userId, String matchId, String name, int level, double x, double y, int ts})>>
      listPresence({int limit = 100}) async {
    final client = _client;
    final session = _session;
    if (client == null || session == null) return const [];
    try {
      final res = await client.listStorageObjects(
        session: session,
        collection: _presCollection,
        limit: limit,
      );
      final out = <({String userId, String matchId, String name, int level, double x, double y, int ts})>[];
      for (final o in res.objects) {
        try {
          final j = jsonDecode(o.value) as Map<String, dynamic>;
          out.add((
            userId: o.userId ?? '',
            matchId: (j['m'] as String?) ?? '',
            name: (j['n'] as String?) ?? '플레이어',
            level: (j['l'] as num?)?.toInt() ?? 1,
            x: (j['x'] as num?)?.toDouble() ?? 0,
            y: (j['y'] as num?)?.toDouble() ?? 0,
            ts: (j['t'] as num?)?.toInt() ?? 0,
          ));
        } catch (_) {/* 무시 */}
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  // ── 친구 요청(Nakama 내장 친구 시스템) ──
  // 친구는 "로컬 목록 추가"가 아니라 서버 권위 요청/수락 흐름이다. 상대가 오프라인이어도
  // 서버에 보류되어 다음 로그인에 incomingRequest 로 전달된다.
  // appId = 로컬 계정 ID(=Nakama username, registerAccount/authenticateEmail 의 username 으로 설정됨).

  // 친구 요청 전송. 성공 시 true(상대에게 incomingRequest 로 도착).
  Future<bool> sendFriendRequest(String appId) async {
    final client = _client;
    final session = _session;
    if (client == null || session == null || appId.isEmpty) return false;
    try {
      await client.addFriends(session: session, ids: const [], usernames: [appId]);
      return true;
    } catch (_) {
      return false;
    }
  }

  // 수락 = 상호 addFriends(역방향 요청 존재 시 mutual 로 전환).
  Future<bool> acceptFriendRequest(String appId) => sendFriendRequest(appId);

  // 거절/삭제.
  Future<void> removeFriendNet(String appId) async {
    final client = _client;
    final session = _session;
    if (client == null || session == null || appId.isEmpty) return;
    try {
      await client.deleteFriends(session: session, ids: const [], usernames: [appId]);
    } catch (_) {/* 무시 */}
  }

  Future<List<({String id, String nickname})>> _friendsByState(FriendshipState state) async {
    final client = _client;
    final session = _session;
    if (client == null || session == null) return const [];
    try {
      final res = await client.listFriends(session: session, friendshipState: state, limit: 100);
      final out = <({String id, String nickname})>[];
      for (final f in res.friends ?? const []) {
        final u = f.user;
        final id = u.username ?? u.id;
        if (id.isEmpty) continue;
        out.add((id: id, nickname: (u.displayName != null && u.displayName!.isNotEmpty) ? u.displayName! : id));
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  // 받은 친구 요청(수락 대기).
  Future<List<({String id, String nickname})>> incomingFriendRequests() =>
      _friendsByState(FriendshipState.incomingRequest);

  // 보낸 친구 요청(상대 수락 대기) — "요청 보냄" 표시용.
  Future<List<({String id, String nickname})>> outgoingFriendRequests() =>
      _friendsByState(FriendshipState.outgoingRequest);

  // 수락된 친구.
  Future<List<({String id, String nickname})>> acceptedFriends() =>
      _friendsByState(FriendshipState.mutual);

  // 다른 기기에서 가입한 계정도 ID(=Nakama username)로 정확히 찾을 수 있게 조회.
  Future<({String id, String nickname})?> findUserById(String id) async {
    final client = _client;
    final session = _session;
    if (client == null || session == null || id.isEmpty) return null;
    try {
      final users = await client.getUsers(session: session, ids: const [], usernames: [id]);
      if (users.isEmpty) return null;
      final u = users.first;
      final nick = (u.displayName != null && u.displayName!.isNotEmpty) ? u.displayName! : (u.username ?? id);
      return (id: u.username ?? id, nickname: nick);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _rpc(String id, [Map<String, dynamic>? payload]) async {
    final client = _client;
    final session = _session;
    if (client == null || session == null) {
      throw NakamaRpcException('not connected', 'no_session');
    }
    final res = await client.rpc(
      session: session,
      id: id,
      payload: jsonEncode(payload ?? const {}),
    );
    final decoded = (res == null || res.isEmpty)
        ? <String, dynamic>{}
        : jsonDecode(res) as Map<String, dynamic>;
    if (decoded['ok'] == false) {
      throw NakamaRpcException(
        decoded['error']?.toString() ?? 'rpc error',
        decoded['code']?.toString(),
      );
    }
    return decoded;
  }

  // ── Phase 1 ──
  // 서버 권위 공유 오픈월드 매치 id(없으면 서버가 생성). 실패 시 null → 클라가 폴백.
  Future<String?> worldMatchId() async {
    try {
      final r = await _rpc('rpc_world_match');
      return r['match_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<GameInstance> createInstance({String biome = 'forest', int monsterCount = 12}) async {
    final r = await _rpc('rpc_create_instance', {'biome': biome, 'monster_count': monsterCount});
    return GameInstance.fromJson(r);
  }

  Future<DropResult> reportKill(int runSeed, int monsterIdx) async {
    final r = await _rpc('rpc_report_kill', {'run_seed': runSeed, 'monster_idx': monsterIdx});
    return DropResult.fromJson(r);
  }

  Future<Inventory> getInventory() async {
    final r = await _rpc('rpc_get_inventory');
    final inv = r['inventory'];
    return inv is Map<String, dynamic> ? Inventory.fromJson(inv) : Inventory.empty();
  }

  // ── Phase 2~3 (UI 골격에서 호출). 서버 함수는 구현돼 있음 ──
  Future<Map<String, dynamic>> enhanceItem(String itemId, String scrollTemplate) =>
      _rpc('rpc_enhance_item', {'item_id': itemId, 'scroll_template': scrollTemplate});

  Future<List<dynamic>> browseMarket({int limit = 50, int offset = 0}) async {
    final r = await _rpc('rpc_browse_market', {'limit': limit, 'offset': offset});
    return (r['listings'] as List?) ?? const [];
  }

  Future<Map<String, dynamic>> listItem(String itemId, int price) =>
      _rpc('rpc_list_item', {'item_id': itemId, 'price': price});

  Future<Map<String, dynamic>> buyListing(String listingId) =>
      _rpc('rpc_buy_listing', {'listing_id': listingId});

  Future<Map<String, dynamic>> cancelListing(String listingId) =>
      _rpc('rpc_cancel_listing', {'listing_id': listingId});
}
