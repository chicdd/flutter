// 실시간 멀티플레이어 — Nakama relayed 매치로 같은 오픈월드를 공유 + 전역 채팅.
//
// 핵심(풀 온라인): relayed 매치는 이름으로 못 찾으므로, 각 클라이언트가 스토리지에
// "world_presence"(자기 matchId·좌표·레벨, publicRead)를 주기적으로 기록한다. 합류 시
// 이 presence 목록을 읽어 "가장 많은 사람이 모인 matchId"에 합류한다(없으면 새로 생성).
// → 서버 권위 매치 모듈 없이도 모두 한 월드에 수렴하고, 다른 플레이어가 맵에 보인다.
// 채팅은 Nakama 채널(room "openworld")로 전 유저가 함께 대화한다.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:nakama/nakama.dart';

import 'nakama_service.dart';

class RemotePlayerState {
  final String sessionId;
  String name;
  int level;
  double x;
  double y;
  double vx = 0; // px/s (보간/추측항법용)
  double vy = 0;
  int tick = 0; // 좌표의 서버 틱
  DateTime lastSeen;

  List<int>? avatarBytes; // 수신한 아바타 PNG
  int avatarVersion = 0; // 수신 버전(변경 감지)

  RemotePlayerState({
    required this.sessionId,
    this.name = '플레이어',
    this.level = 1,
    this.x = 0,
    this.y = 0,
  }) : lastSeen = DateTime.now();
}

// 대화 유형(채널). all=전체, party=파티, friend=친구.
enum ChatScope { all, party, friend }

class ChatLine {
  final String name;
  final String text;
  final int level;
  final bool mine;
  final ChatScope scope;
  ChatLine(this.name, this.text, this.level, this.mine, {this.scope = ChatScope.all});
}

// 서버 권위 몬스터 스냅샷(공유 인스턴스).
class NetMonster {
  final int id;
  final String t;
  double x;
  double y;
  double vx; // px/s
  double vy;
  int hp;
  int mhp;
  final int lv;
  final bool el;
  int tick; // 이 좌표의 서버 틱
  NetMonster(this.id, this.t, this.x, this.y, this.vx, this.vy, this.hp, this.mhp, this.lv, this.el, this.tick);
}

// 서버 권위 월드 드랍(소유권 없음) — 표시용 최소 정보.
class NetDrop {
  final String id;
  double x;
  double y;
  final int rarity; // 등급 index(표시 색)
  final String name;
  NetDrop(this.id, this.x, this.y, this.rarity, this.name);
}

class MultiplayerService {
  static const int opPosition = 1;
  static const int opAvatar = 2;
  static const String chatRoom = 'openworld';
  static const int _presenceFreshMs = 30000; // 30초 내 presence 만 유효

  // 서버 권위 월드 매치 op code(핸들러와 동일).
  static const int wSnapshot = 1;
  static const int wPosition = 2;
  static const int wHit = 3;
  static const int wReward = 4;
  static const int wDeath = 5;
  static const int wPlayerDmg = 6; // 몬스터가 플레이어에게 가한 피해(서버 권위, 전원 표시)
  static const int wItemDrop = 7; // 아이템 드랍(소유권 없음)
  static const int wItemPickup = 8; // 줍기 요청
  static const int wItemGrant = 9; // 줍기 성공(서버가 1명에게만)

  final NakamaService net;
  MultiplayerService(this.net);

  NakamaWebsocketClient? _socket;
  String? _matchId;
  String? _chatChannelId;
  bool _joining = false;

  // 서버 권위 모드(공유 몬스터). false 면 기존 relayed 폴백.
  bool authoritative = false;
  final Map<int, NetMonster> netMonsters = {};
  final Map<String, NetDrop> netDrops = {}; // 서버 권위 월드 드랍
  int latestServerTick = 0; // 클록 드리프트 보정용 최신 서버 틱
  ({double x, double y})? selfServer; // 본인 화해(reconciliation)용 서버 좌표
  // 서버 지분 보상 수신 콜백(RpgGame 이 설정).
  void Function(int gold, int exp, bool loot, String templateId, bool elite, int lv)? onReward;
  // 서버 권위 플레이어 피해 수신 콜백(본인=HP 적용, 타인=데미지 표시).
  void Function(String uid, int monsterId, int dmg, bool crit)? onPlayerDamage;
  // 줍기 성공 수신 콜백(서버가 1명에게만 지급) — 클라가 itemJson 으로 가방 추가.
  void Function(String itemJson)? onItemGrant;

  // 개인 인박스(파티 초대 / 귓속말) — 온라인 실시간.
  String myAppId = ''; // 내 계정 ID(인박스 채널 키)
  String? _inboxId;
  void Function(String fromId, String fromName, String kind, String text)? onInbox;

  final Map<String, RemotePlayerState> players = {};
  StreamSubscription<MatchData>? _dataSub;
  StreamSubscription<MatchPresenceEvent>? _presSub;
  // onChannelMessage 는 protobuf 타입(api.ChannelMessage)을 방출 — 동적으로 필드 접근.
  StreamSubscription<dynamic>? _chatSub;
  Timer? _presenceTimer;

  // 채팅 로그(전역). UI 는 chatVersion 으로 갱신.
  final List<ChatLine> chatLog = [];
  final ValueNotifier<int> chatVersion = ValueNotifier<int>(0);

  // presence 기록용 마지막 상태.
  double _lastX = 0;
  double _lastY = 0;
  int _lastLevel = 1;
  String _lastName = '플레이어';

  bool get connected => _matchId != null;
  bool get chatReady => _chatChannelId != null;

  // ── 진단(우측 하단 표시용) ──
  String? get matchId => _matchId;
  String get matchShort => _matchId == null ? '-' : _matchId!.substring(0, _matchId!.length < 8 ? _matchId!.length : 8);
  int get remoteCount => players.length; // 보이는 다른 플레이어 수
  String get mode => authoritative ? '권위' : 'relayed';

  Future<void> join({required String matchName}) async {
    if (_joining || connected) return;
    _joining = true;
    try {
      final session = net.session;
      if (session == null) return;

      _socket = NakamaWebsocketClient.init(
        host: NakamaService.host,
        port: NakamaService.httpPort,
        ssl: false,
        token: session.token,
      );

      _dataSub = _socket!.onMatchData.listen(_onData);
      _presSub = _socket!.onMatchPresence.listen(_onPresence);

      Match? match;

      // 0) 서버 권위 공유 월드 매치 우선(서버 모듈 배포 시). 몬스터를 서버가 소유.
      final worldId = await net.worldMatchId();
      if (worldId != null) {
        try {
          match = await _socket!.joinMatch(worldId);
          authoritative = true;
        } catch (_) {
          authoritative = false;
        }
      }

      // 1) (폴백) presence 로 이미 사람이 모인 매치를 찾아 합류(가장 확실한 수렴).
      if (match == null) {
        final target = await _discoverPopulatedMatch();
        if (target != null) {
          try {
            match = await _socket!.joinMatch(target);
          } catch (_) {/* 만료 — 아래로 */}
        }
      }
      // 2) 없으면 이름 있는 매치 — 같은 이름 'openworld' 이면 Nakama 가 동일 match id 반환.
      if (match == null) {
        try {
          match = await _socket!.createMatch(matchName);
        } catch (_) {/* 아래로 */}
      }
      // 3) 최후: 무명 매치 생성.
      match ??= await _socket!.createMatch();

      _matchId = match.matchId;
      for (final p in match.presences) {
        players[p.sessionId] = RemotePlayerState(sessionId: p.sessionId, name: p.username);
      }

      // 전역 채팅 + 개인 인박스 입장.
      await _joinChat();
      await _joinInbox();

      // presence 주기 발행 + (relayed) 단일 월드로 자동 수렴.
      await _writePresence();
      _presenceTimer = Timer.periodic(const Duration(seconds: 5), (_) => _heartbeat());
      // 합류 직후 빠른 1회 수렴(동시 접속으로 갈라졌을 때 곧바로 한 곳에 모음).
      if (!authoritative) Timer(const Duration(seconds: 2), () => _maybeConverge());
    } catch (_) {
      await _cleanup();
    } finally {
      _joining = false;
    }
  }

  Future<String?> _discoverPopulatedMatch() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final list = await net.listPresence();
    final counts = <String, int>{};
    for (final p in list) {
      if (p.userId == net.userId) continue;
      if (p.matchId.isEmpty) continue;
      if (now - p.ts > _presenceFreshMs) continue;
      counts[p.matchId] = (counts[p.matchId] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }

  Future<void> _writePresence() async {
    final id = _matchId;
    if (id == null) return;
    await net.publishPresence(matchId: id, name: _lastName, level: _lastLevel, x: _lastX, y: _lastY);
  }

  Future<void> _heartbeat() async {
    await _writePresence();
    if (!authoritative) await _maybeConverge();
  }

  // relayed 폴백에서 매치가 갈라졌을 때 단일 월드로 자동 수렴.
  // 결정론적 리더(가장 작은 userId)의 매치로 나머지가 이주한다 → 진동 없이 한 곳에 모임.
  Future<void> _maybeConverge() async {
    final socket = _socket;
    final myMatch = _matchId;
    final myId = net.userId;
    if (socket == null || myMatch == null || myId == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final list = await net.listPresence();

    var leaderId = myId;
    var leaderMatch = myMatch;
    for (final p in list) {
      if (p.matchId.isEmpty || now - p.ts > _presenceFreshMs) continue;
      if (p.userId.compareTo(leaderId) < 0) {
        leaderId = p.userId;
        leaderMatch = p.matchId;
      }
    }
    if (leaderId == myId || leaderMatch.isEmpty || leaderMatch == myMatch) return;

    // 리더 매치로 이주.
    try {
      await socket.leaveMatch(myMatch);
      final match = await socket.joinMatch(leaderMatch);
      _matchId = match.matchId;
      players.clear();
      for (final pr in match.presences) {
        players[pr.sessionId] = RemotePlayerState(sessionId: pr.sessionId, name: pr.username);
      }
      await _writePresence();
    } catch (_) {/* 실패 시 기존 매치 유지 */}
  }

  // 전역 presence(최근 활성) — 맵에서 전체 접속자 점 표시용.
  Future<List<({String name, int level, double x, double y})>> onlinePlayers() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final list = await net.listPresence();
    final out = <({String name, int level, double x, double y})>[];
    for (final p in list) {
      if (p.userId == net.userId) continue;
      if (now - p.ts > _presenceFreshMs) continue;
      out.add((name: p.name, level: p.level, x: p.x, y: p.y));
    }
    return out;
  }

  // ── 채팅 ──
  Future<void> _joinChat() async {
    final socket = _socket;
    if (socket == null) return;
    try {
      final channel = await socket.joinChannel(
        target: chatRoom,
        type: ChannelType.room,
        persistence: false,
        hidden: false,
      );
      _chatChannelId = channel.id;
      _chatSub = socket.onChannelMessage.listen(_onChat);
    } catch (_) {/* 채팅 불가 시 무시 */}
  }

  // 개인 인박스 입장(파티 초대/귓속말 수신).
  Future<void> _joinInbox() async {
    final socket = _socket;
    if (socket == null || myAppId.isEmpty) return;
    try {
      final channel = await socket.joinChannel(
        target: 'inbox-$myAppId',
        type: ChannelType.room,
        persistence: false,
        hidden: true,
      );
      _inboxId = channel.id;
    } catch (_) {/* 무시 */}
  }

  void _onChat(dynamic m) {
    try {
      final channelId = m.channelId as String;
      final content = m.content as String; // JSON 문자열
      final j = jsonDecode(content) as Map<String, dynamic>;

      // 내 인박스로 온 메시지(파티/친구 채팅 · 파티초대 · 귓속말).
      if (channelId == _inboxId) {
        final from = (j['from'] as String?) ?? '';
        if (from.isEmpty || from == myAppId) return;
        final kind = (j['kind'] as String?) ?? '';
        final fromName = (j['fromName'] as String?) ?? from;
        final text = (j['text'] as String?) ?? '';
        if (kind == 'chat') {
          // 파티/친구 채팅 — 채팅 로그에 스코프 태그로 적재.
          final scope = (j['scope'] == 'friend') ? ChatScope.friend : ChatScope.party;
          final level = int.tryParse((j['l'] as String?) ?? '') ?? 0;
          _appendChat(ChatLine(fromName, text, level, false, scope: scope));
        } else {
          onInbox?.call(from, fromName, kind, text);
        }
        return;
      }
      // 전역 채팅 외 다른 채널(내가 보낸 타겟 인박스 echo 등)은 무시.
      if (channelId != _chatChannelId) return;

      final text = (j['text'] as String?) ?? '';
      if (text.isEmpty) return;
      final name = (j['name'] as String?) ?? (m.username as String);
      final level = int.tryParse((j['l'] as String?) ?? '') ?? 0;
      final mine = (m.senderId as String) == net.userId;
      _appendChat(ChatLine(name, text, level, mine, scope: ChatScope.all));
    } catch (_) {/* 비-게임 메시지 무시 */}
  }

  void _appendChat(ChatLine line) {
    chatLog.add(line);
    if (chatLog.length > 120) chatLog.removeAt(0);
    chatVersion.value++;
  }

  // 내가 보낸 파티/친구 채팅은 에코가 없으므로 로컬에 직접 추가.
  void addLocalChat(String name, String text, int level, ChatScope scope) {
    _appendChat(ChatLine(name, text, level, true, scope: scope));
  }

  // 대상의 인박스로 메시지 전송(파티초대/귓속말/스코프채팅). extra 로 추가 필드 부착.
  Future<void> sendInbox(String targetAppId, String kind, String fromName,
      {String text = '', Map<String, String> extra = const {}}) async {
    final socket = _socket;
    if (socket == null || targetAppId.isEmpty) return;
    try {
      final ch = await socket.joinChannel(
        target: 'inbox-$targetAppId',
        type: ChannelType.room,
        persistence: false,
        hidden: true,
      );
      await socket.sendMessage(channelId: ch.id, content: {
        'kind': kind,
        'from': myAppId,
        'fromName': fromName,
        'text': text,
        ...extra,
      });
      await socket.leaveChannel(channelId: ch.id);
    } catch (_) {/* 무시 */}
  }

  // 파티/친구 채팅 — 대상 인박스로 chat 메시지 전송.
  Future<void> sendScopedChat(String targetAppId, String text, ChatScope scope) {
    return sendInbox(targetAppId, 'chat', _lastName,
        text: text, extra: {'scope': scope == ChatScope.friend ? 'friend' : 'party', 'l': '$_lastLevel'});
  }

  // 전체 채팅 — openworld 채널(접속한 모든 유저).
  void sendChat(String text) {
    final socket = _socket;
    final ch = _chatChannelId;
    final t = text.trim();
    if (socket == null || ch == null || t.isEmpty) return;
    try {
      socket.sendMessage(channelId: ch, content: {
        'text': t,
        'name': _lastName,
        'l': '$_lastLevel',
      });
    } catch (_) {/* 무시 */}
  }

  void sendPosition({
    required double x,
    required double y,
    required int level,
    required String name,
    double vx = 0,
    double vy = 0,
    double def = 0,
  }) {
    _lastX = x;
    _lastY = y;
    _lastLevel = level;
    _lastName = name;
    final socket = _socket;
    final matchId = _matchId;
    if (socket == null || matchId == null) return;
    try {
      final payload = authoritative
          ? {'x': x, 'y': y, 'vx': vx, 'vy': vy, 'l': level, 'n': name, 'df': def}
          : {'x': x, 'y': y, 'l': level, 'n': name};
      socket.sendMatchData(
        matchId: matchId,
        opCode: authoritative ? wPosition : opPosition,
        data: utf8.encode(jsonEncode(payload)),
      );
    } catch (_) {/* 무시 */}
  }

  // 서버 권위 몬스터에 가한 피해 보고(공격자=나). 서버가 기여도 누적·사망/보상 판정.
  void sendMonsterHit(int monsterId, int dmg) {
    final socket = _socket;
    final matchId = _matchId;
    if (socket == null || matchId == null || !authoritative) return;
    try {
      socket.sendMatchData(
        matchId: matchId,
        opCode: wHit,
        data: utf8.encode(jsonEncode({'id': monsterId, 'dmg': dmg})),
      );
    } catch (_) {/* 무시 */}
  }

  // 아이템 드랍(소유권 없음) 보고. 서버가 보관 → 전원 스냅샷에 노출.
  void sendItemDrop({
    required String item,
    required int rarity,
    required String name,
    required double x,
    required double y,
  }) {
    final socket = _socket;
    final matchId = _matchId;
    if (socket == null || matchId == null || !authoritative) return;
    try {
      socket.sendMatchData(
        matchId: matchId,
        opCode: wItemDrop,
        data: utf8.encode(jsonEncode({'item': item, 'r': rarity, 'n': name, 'x': x, 'y': y})),
      );
    } catch (_) {/* 무시 */}
  }

  // 줍기 요청. 서버가 원자적으로 1명에게만 ITEM_GRANT 로 응답(복제 방지).
  void sendItemPickup(String dropId) {
    final socket = _socket;
    final matchId = _matchId;
    if (socket == null || matchId == null || !authoritative) return;
    try {
      socket.sendMatchData(
        matchId: matchId,
        opCode: wItemPickup,
        data: utf8.encode(jsonEncode({'id': dropId})),
      );
    } catch (_) {/* 무시 */}
  }

  // 아바타 전송(PNG 바이트).
  void sendAvatar(List<int> png) {
    final socket = _socket;
    final matchId = _matchId;
    if (socket == null || matchId == null) return;
    try {
      socket.sendMatchData(matchId: matchId, opCode: opAvatar, data: png);
    } catch (_) {/* 무시 */}
  }

  void _onData(MatchData d) {
    if (authoritative) {
      _onWorldData(d);
      return;
    }
    final p = d.presence;
    if (p == null || d.data == null) return;

    if (d.opCode == opAvatar) {
      final st = players.putIfAbsent(
        p.sessionId,
        () => RemotePlayerState(sessionId: p.sessionId, name: p.username),
      );
      st.avatarBytes = d.data;
      st.avatarVersion++;
      return;
    }

    if (d.opCode != opPosition) return;
    try {
      final j = jsonDecode(utf8.decode(d.data!)) as Map<String, dynamic>;
      final st = players.putIfAbsent(
        p.sessionId,
        () => RemotePlayerState(sessionId: p.sessionId, name: p.username),
      );
      st.x = (j['x'] as num).toDouble();
      st.y = (j['y'] as num).toDouble();
      st.level = (j['l'] as num?)?.toInt() ?? st.level;
      st.name = (j['n'] as String?) ?? st.name;
      st.lastSeen = DateTime.now();
    } catch (_) {/* 잘못된 페이로드 무시 */}
  }

  // 서버 권위 월드 매치 수신: 몬스터 스냅샷 / 보상 / 사망.
  void _onWorldData(MatchData d) {
    if (d.data == null) return;
    try {
      final j = jsonDecode(utf8.decode(d.data!)) as Map<String, dynamic>;
      switch (d.opCode) {
        case wSnapshot:
          final tk = (j['tk'] as num?)?.toInt() ?? (latestServerTick + 1);
          if (tk > latestServerTick) latestServerTick = tk;
          // 몬스터 갱신(없어진 건 제거).
          final seen = <int>{};
          for (final raw in (j['m'] as List? ?? const [])) {
            final m = raw as Map<String, dynamic>;
            final id = (m['id'] as num).toInt();
            seen.add(id);
            final x = (m['x'] as num).toDouble();
            final y = (m['y'] as num).toDouble();
            final vx = (m['vx'] as num?)?.toDouble() ?? 0;
            final vy = (m['vy'] as num?)?.toDouble() ?? 0;
            final hp = (m['hp'] as num).toInt();
            final mhp = (m['mhp'] as num).toInt();
            final cur = netMonsters[id];
            if (cur == null) {
              netMonsters[id] = NetMonster(id, m['t'] as String, x, y, vx, vy, hp, mhp,
                  (m['lv'] as num).toInt(), m['el'] == true, tk);
            } else {
              cur.x = x;
              cur.y = y;
              cur.vx = vx;
              cur.vy = vy;
              cur.hp = hp;
              cur.mhp = mhp;
              cur.tick = tk;
            }
          }
          netMonsters.removeWhere((k, _) => !seen.contains(k));
          // 플레이어 갱신 — 본인은 화해용 좌표로, 나머지는 원격 보간용으로.
          final me = net.userId;
          final seenP = <String>{};
          for (final raw in (j['p'] as List? ?? const [])) {
            final pj = raw as Map<String, dynamic>;
            final uid = pj['u'] as String? ?? '';
            if (uid.isEmpty) continue;
            final px = (pj['x'] as num).toDouble();
            final py = (pj['y'] as num).toDouble();
            if (uid == me) {
              selfServer = (x: px, y: py); // 본인: reconciliation
              continue;
            }
            seenP.add(uid);
            final st = players.putIfAbsent(uid, () => RemotePlayerState(sessionId: uid));
            st.x = px;
            st.y = py;
            st.vx = (pj['vx'] as num?)?.toDouble() ?? 0;
            st.vy = (pj['vy'] as num?)?.toDouble() ?? 0;
            st.tick = tk;
            st.level = (pj['l'] as num?)?.toInt() ?? st.level;
            st.name = (pj['n'] as String?) ?? st.name;
            st.lastSeen = DateTime.now();
          }
          players.removeWhere((k, _) => !seenP.contains(k));
          // 드랍 아이템 갱신(스냅샷에서 빠지면 줍힘/만료 → 제거).
          final seenD = <String>{};
          for (final raw in (j['d'] as List? ?? const [])) {
            final dj = raw as Map<String, dynamic>;
            final id = dj['id'] as String? ?? '';
            if (id.isEmpty) continue;
            seenD.add(id);
            final dx = (dj['x'] as num).toDouble();
            final dy = (dj['y'] as num).toDouble();
            final cur = netDrops[id];
            if (cur == null) {
              netDrops[id] = NetDrop(id, dx, dy, (dj['r'] as num?)?.toInt() ?? 0, dj['n'] as String? ?? '아이템');
            } else {
              cur.x = dx;
              cur.y = dy;
            }
          }
          netDrops.removeWhere((k, _) => !seenD.contains(k));
          break;
        case wDeath:
          netMonsters.remove((j['id'] as num).toInt());
          break;
        case wPlayerDmg:
          onPlayerDamage?.call(
            (j['u'] as String?) ?? '',
            (j['mid'] as num?)?.toInt() ?? 0,
            (j['dmg'] as num?)?.toInt() ?? 0,
            j['crit'] == true,
          );
          break;
        case wReward:
          onReward?.call(
            (j['g'] as num?)?.toInt() ?? 0,
            (j['e'] as num?)?.toInt() ?? 0,
            j['loot'] == true,
            j['t'] as String? ?? 'slime',
            j['el'] == true,
            (j['lv'] as num?)?.toInt() ?? 1,
          );
          break;
        case wItemGrant:
          final granted = j['item'];
          if (granted is String && granted.isNotEmpty) onItemGrant?.call(granted);
          break;
      }
    } catch (_) {/* 무시 */}
  }

  void _onPresence(MatchPresenceEvent e) {
    if (authoritative) return; // 권위 모드: 플레이어는 스냅샷으로 갱신.
    for (final p in e.leaves) {
      players.remove(p.sessionId);
    }
    for (final p in e.joins) {
      players.putIfAbsent(
        p.sessionId,
        () => RemotePlayerState(sessionId: p.sessionId, name: p.username),
      );
    }
  }

  Future<void> _cleanup() async {
    _presenceTimer?.cancel();
    _presenceTimer = null;
    await _dataSub?.cancel();
    await _presSub?.cancel();
    await _chatSub?.cancel();
    _dataSub = null;
    _presSub = null;
    _chatSub = null;
    _matchId = null;
    _chatChannelId = null;
    _inboxId = null;
    players.clear();
  }

  Future<void> dispose() async {
    final socket = _socket;
    final matchId = _matchId;
    final ch = _chatChannelId;
    if (socket != null && ch != null) {
      try {
        await socket.leaveChannel(channelId: ch);
      } catch (_) {/* 무시 */}
    }
    if (socket != null && matchId != null) {
      try {
        await socket.leaveMatch(matchId);
      } catch (_) {/* 무시 */}
    }
    await _cleanup();
    chatVersion.dispose();
  }
}
