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

class ChatLine {
  final String name;
  final String text;
  final int level;
  final bool mine;
  ChatLine(this.name, this.text, this.level, this.mine);
}

// 서버 권위 몬스터 스냅샷(공유 인스턴스).
class NetMonster {
  final int id;
  final String t;
  double x;
  double y;
  int hp;
  int mhp;
  final int lv;
  final bool el;
  NetMonster(this.id, this.t, this.x, this.y, this.hp, this.mhp, this.lv, this.el);
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

  final NakamaService net;
  MultiplayerService(this.net);

  NakamaWebsocketClient? _socket;
  String? _matchId;
  String? _chatChannelId;
  bool _joining = false;

  // 서버 권위 모드(공유 몬스터). false 면 기존 relayed 폴백.
  bool authoritative = false;
  final Map<int, NetMonster> netMonsters = {};
  // 서버 지분 보상 수신 콜백(RpgGame 이 설정).
  void Function(int gold, int exp, bool loot, String templateId, bool elite, int lv)? onReward;

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

      // 1) (폴백) presence 스토리지에서 사람이 모여 있는 relayed 매치.
      if (match == null) {
        final target = await _discoverPopulatedMatch();
        if (target != null) {
          try {
            match = await _socket!.joinMatch(target);
          } catch (_) {/* 만료된 매치 — 아래로 폴백 */}
        }
      }
      // 2) (폴백) 활성 매치 목록.
      if (match == null) {
        try {
          final active = await net.listActiveMatches();
          if (active.isNotEmpty) match = await _socket!.joinMatch(active.first.matchId);
        } catch (_) {/* 무시 */}
      }
      // 3) 그래도 없으면 새 relayed 매치 생성.
      match ??= await _socket!.createMatch();

      _matchId = match.matchId;
      for (final p in match.presences) {
        players[p.sessionId] = RemotePlayerState(sessionId: p.sessionId, name: p.username);
      }

      // 전역 채팅 입장.
      await _joinChat();

      // presence 주기 발행(다른 클라이언트가 이 매치를 찾도록).
      await _writePresence();
      _presenceTimer = Timer.periodic(const Duration(seconds: 5), (_) => _writePresence());
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

  void _onChat(dynamic m) {
    try {
      final content = m.content as String; // api.ChannelMessage.content (JSON 문자열)
      final j = jsonDecode(content) as Map<String, dynamic>;
      final text = (j['text'] as String?) ?? '';
      if (text.isEmpty) return;
      final name = (j['name'] as String?) ?? (m.username as String);
      final level = int.tryParse((j['l'] as String?) ?? '') ?? 0;
      final mine = (m.senderId as String) == net.userId;
      chatLog.add(ChatLine(name, text, level, mine));
      if (chatLog.length > 100) chatLog.removeAt(0);
      chatVersion.value++;
    } catch (_) {/* 비-게임 메시지 무시 */}
  }

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

  void sendPosition({required double x, required double y, required int level, required String name}) {
    _lastX = x;
    _lastY = y;
    _lastLevel = level;
    _lastName = name;
    final socket = _socket;
    final matchId = _matchId;
    if (socket == null || matchId == null) return;
    try {
      socket.sendMatchData(
        matchId: matchId,
        opCode: authoritative ? wPosition : opPosition,
        data: utf8.encode(jsonEncode({'x': x, 'y': y, 'l': level, 'n': name})),
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
          // 몬스터 갱신(없어진 건 제거).
          final seen = <int>{};
          for (final raw in (j['m'] as List? ?? const [])) {
            final m = raw as Map<String, dynamic>;
            final id = (m['id'] as num).toInt();
            seen.add(id);
            final x = (m['x'] as num).toDouble();
            final y = (m['y'] as num).toDouble();
            final hp = (m['hp'] as num).toInt();
            final mhp = (m['mhp'] as num).toInt();
            final cur = netMonsters[id];
            if (cur == null) {
              netMonsters[id] = NetMonster(id, m['t'] as String, x, y, hp, mhp,
                  (m['lv'] as num).toInt(), m['el'] == true);
            } else {
              cur.x = x;
              cur.y = y;
              cur.hp = hp;
              cur.mhp = mhp;
            }
          }
          netMonsters.removeWhere((k, _) => !seen.contains(k));
          // 플레이어(원격) 갱신 — userId 를 sessionId 대용으로 사용, 본인 제외.
          final me = net.userId;
          final seenP = <String>{};
          for (final raw in (j['p'] as List? ?? const [])) {
            final pj = raw as Map<String, dynamic>;
            final uid = pj['u'] as String? ?? '';
            if (uid.isEmpty || uid == me) continue;
            seenP.add(uid);
            final st = players.putIfAbsent(uid, () => RemotePlayerState(sessionId: uid));
            st.x = (pj['x'] as num).toDouble();
            st.y = (pj['y'] as num).toDouble();
            st.level = (pj['l'] as num?)?.toInt() ?? st.level;
            st.name = (pj['n'] as String?) ?? st.name;
            st.lastSeen = DateTime.now();
          }
          players.removeWhere((k, _) => !seenP.contains(k));
          break;
        case wDeath:
          netMonsters.remove((j['id'] as num).toInt());
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
