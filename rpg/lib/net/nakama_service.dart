// Nakama 클라이언트 래퍼 (§9 net). RPC 호출 + 세션 관리.
// 경제 로직 없음: 모든 변경은 서버 RPC 로 위임하고 결과를 표시만 한다(§3).
import 'dart:convert';

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

  Future<void> connect({String deviceId = defaultDeviceId, String? username}) async {
    _client ??= getNakamaClient(
      host: host,
      serverKey: serverKey,
      httpPort: httpPort,
      grpcPort: grpcPort,
      ssl: false,
    );
    _session = await _client!.authenticateDevice(
      deviceId: deviceId,
      create: true,
      username: username,
    );
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

  // 친구 검색/추가가 기기를 넘어 동작하려면 로컬 계정 ID·닉네임을 Nakama
  // 계정(username/displayName)에 동기화해 서버를 "전역 디렉터리"로 사용한다.
  // (로컬 SharedPreferences 계정 목록은 이 기기에서 가입한 계정만 알기 때문.)
  Future<void> syncIdentity({required String id, required String nickname}) async {
    final client = _client;
    final session = _session;
    if (client == null || session == null) return;
    try {
      await client.updateAccount(session: session, username: id, displayName: nickname);
    } catch (_) {
      // username 이 이미 다른 Nakama 계정에 점유된 경우 등 — 무시(로컬 친구기능은 계속 동작).
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
  Future<List<({String id, String nickname, int level, int exp})>> listDirectory({int limit = 100}) async {
    final client = _client;
    final session = _session;
    if (client == null || session == null) return const [];
    try {
      final res = await client.listStorageObjects(
        session: session,
        collection: _dirCollection,
        limit: limit,
      );
      final out = <({String id, String nickname, int level, int exp})>[];
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
      return out;
    } catch (_) {
      return const [];
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
