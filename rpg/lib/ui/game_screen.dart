// 게임 화면 (§9 UI). GameWidget + HUD 오버레이.
// PlayerProfile 을 소유해 게임/HUD/인벤토리가 공유한다. 온라인이면 실시간 매치에 접속한다.
import 'dart:async';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../game/rpg_game.dart';
import '../game/world/offline_gen.dart';
import '../models/account.dart';
import '../models/gear.dart';
import '../models/instance.dart';
import '../models/items.dart';
import '../models/job_skills.dart';
import '../net/audio_service.dart';
import '../net/multiplayer.dart';
import '../net/nakama_service.dart';
import '../net/notification_center.dart';
import '../net/auth_service.dart';
import '../net/profile_store.dart';
import '../net/social_service.dart';
import '../state/player_profile.dart';
import '../state/settings.dart';
import '../util/avatar.dart';
import 'auth/login_screen.dart';
import 'character_info.dart';
import 'character_panel.dart';
import 'chat_panel.dart';
import 'enhance_screen.dart';
import 'floating_window.dart';
import 'game_log.dart';
import 'notification_panel.dart';
import 'server_status_bar.dart';
import 'inventory_panel.dart';
import 'menu/menu_screen.dart';
import 'minimap.dart';
import 'shop_screen.dart';
import 'skill_screen.dart';
import 'widgets/item_icon.dart';
import 'world_map_overlay.dart';

class GameScreen extends StatefulWidget {
  final Account account;
  const GameScreen({super.key, required this.account});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final PlayerProfile _profile = PlayerProfile();
  final GameSettings _settings = GameSettings();
  late final SocialService _social = SocialService(
    widget.account.id,
    net: NakamaService.instance,
  );
  RpgGame? _game;
  MultiplayerService? _mp;
  Timer? _saveTimer;
  Timer? _notifTimer;
  final NotificationCenter _notif = NotificationCenter();
  List<String> _friendIds = []; // 친구 채팅 수신자 캐시
  String? _bootError; // 중복 접속 등 부팅 실패 메시지
  bool _loading = true;
  bool _online = false;
  // 열린 창들의 스택(연 순서). ESC 는 맨 위(마지막에 연 창)부터 닫고, 비면 메뉴를 연다.
  // id: 'inv' 인벤토리 / 'equip' 내정보 / 'map' 지도 / 'chat' 채팅 / 'menu' 메뉴.
  final List<String> _openStack = [];
  String _status = '서버 연결 중...';
  final GameLogController _logCtrl = GameLogController();

  // 인벤토리 드래그(클릭-투-무브): 들고 있는 아이템 + 커서 위치 + 드롭 hit-test 키.
  final Map<EquipSlot, GlobalKey> _slotKeys = {
    for (final s in EquipSlot.values) s: GlobalKey(),
  };
  final List<GlobalKey> _bagKeys = List.generate(
    PlayerProfile.bagCapacity,
    (_) => GlobalKey(),
  );
  BagItem? _held; // 들고 있는 아이템(null=없음)
  int? _heldFrom; // 집어든 가방 인덱스
  Offset _cursor = Offset.zero; // 화면(global) 커서 위치
  final GlobalKey _invAreaKey = GlobalKey(); // 인벤 창 영역(여백 드롭=드랍 취소)
  final GlobalKey _equipAreaKey = GlobalKey(); // 장비 창 영역

  bool _isOpen(String id) => _openStack.contains(id);

  void _openWindow(String id) => setState(() {
    _openStack
      ..remove(id)
      ..add(id);
  });

  void _closeWindow(String id) => setState(() => _openStack.remove(id));

  void _toggleWindow(String id) =>
      _isOpen(id) ? _closeWindow(id) : _openWindow(id);

  // 드래그/탭 시 맨 앞으로.
  void _focusWindow(String id) {
    if (_openStack.isNotEmpty && _openStack.last != id && _isOpen(id)) {
      setState(
        () => _openStack
          ..remove(id)
          ..add(id),
      );
    }
  }

  // ESC: 열린 창이 있으면 마지막 것을 닫고, 모두 닫혔으면 메뉴를 연다.
  void _onEsc() {
    if (_openStack.isEmpty) {
      _openWindow('menu');
    } else {
      _closeWindow(_openStack.last);
    }
  }

  bool get _isMobile =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _notifTimer?.cancel();
    if (_bootError == null) _persist();
    _mp?.dispose();
    NakamaService.instance.releaseSession(); // 세션 락 해제(즉시 재로그인 가능)
    _logCtrl.dispose();
    _notif.dispose();
    super.dispose();
  }

  // 진행상황 저장 + 파티 분배 반영 + 전역 디렉터리 갱신(랭킹/친구검색 동기화).
  void _persist() {
    ProfileStore.save(widget.account.id, _profile);
    _social.flush();
    if (_online) {
      NakamaService.instance.publishDirectory(
        id: widget.account.id,
        nickname: widget.account.nickname,
        level: _profile.level,
        exp: _profile.exp,
      );
    }
  }

  GameInstance _offlineInstance() {
    final seed = Random().nextInt(0x7FFFFFFF);
    return GameInstance(
      runSeed: seed,
      biome: 'forest',
      monsters: generateMonstersOffline(seed),
    );
  }

  Future<void> _boot() async {
    // 설정 로드 + 저장된 진행상황 복원.
    await _settings.load();
    AudioService.instance.preload();
    final saved = await ProfileStore.loadRaw(widget.account.id);
    if (saved != null) _profile.loadJson(saved);

    // 온라인 여부는 "Nakama 연결 성공"으로만 판단한다. 경제 인스턴스(createInstance) 실패가
    // 멀티플레이어/채팅을 통째로 끄지 않도록 분리(이게 '다른 유저가 안 보이던' 핵심 원인).
    // 로그인 단계(AuthService)에서 이미 이 계정의 Nakama 세션이 확립돼 있다 — 여기서 새로
    // connect() 하지 않는다(예전엔 'rpg-acct-<id>' 디바이스ID로 별도 신원을 또 만들었는데,
    // 이제 로그인 계정 자체가 Nakama 계정이라 username 이 충돌해 실패한다).
    bool online = NakamaService.instance.isConnected;
    if (online) {
      try {
        // 단일 세션 보장 — 이미 다른 곳에서 접속중이면 거부.
        final sessionOk = await NakamaService.instance.claimSession();
        if (!sessionOk) {
          await AuthService.instance.logout();
          if (!mounted) return;
          setState(() {
            _loading = false;
            _bootError = '현재 접속중입니다. 다시 시도해주세요.';
          });
          return;
        }
      } catch (e) {
        online = false;
      }
    }

    // 초기 인스턴스 몬스터: 온라인이면 서버 시도, 실패하면 오프라인 생성으로 대체(온라인 유지).
    GameInstance instance;
    try {
      instance = online
          ? await NakamaService.instance.createInstance()
          : _offlineInstance();
    } catch (_) {
      instance = _offlineInstance();
    }

    final mp = online ? MultiplayerService(NakamaService.instance) : null;
    if (mp != null) {
      mp.myAppId = widget.account.id; // 인박스 채널 키
      mp.onInbox = _onInbox; // 파티초대/귓속말 수신
    }
    final game = RpgGame(
      instance: instance,
      online: online,
      showTouchControls: _isMobile,
      net: NakamaService.instance,
      mp: mp,
      profile: _profile,
      settings: _settings,
      playerName: widget.account.nickname,
      selfExpMultiplier: () {
        _social.setMyLevel(_profile.level);
        return _social.selfExpMultiplier;
      },
      onKillExp: (base) => _social.shareExp(base),
      onLog: (msg, color) => _logCtrl.add(msg, color),
      onToggleInventory: () => _toggleWindow('inv'),
      onNpc: _onNpc,
      onToggleMenuBar: _onEsc,
      onToggleMap: () => _toggleWindow('map'),
      onToggleEquipment: () => _toggleWindow('equip'),
      onToggleSkills: _openSkills,
      onToggleCharInfo: () => _toggleWindow('charinfo'),
    );

    if (!mounted) return;
    setState(() {
      _game = game;
      _mp = mp;
      _online = online;
      _loading = false;
      _status = online ? '온라인 · 오픈월드' : '오프라인 · 오픈월드';
    });

    // 저장된 아바타 적용.
    _applyAvatar();

    // 부팅 즉시 디렉터리/저장 1회 반영(랭킹·친구검색에 바로 노출).
    _persist();

    // 주기적 저장 + 파티 분배 반영 + 디렉터리 갱신.
    _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) => _persist());

    // 받은 친구요청 알림(로그인 즉시 + 주기적 갱신). 오프라인 동안 보류분도 채워짐.
    if (online) {
      _refreshNotifications();
      _notifTimer = Timer.periodic(
        const Duration(seconds: 15),
        (_) => _refreshNotifications(),
      );
    }
  }

  Future<void> _refreshNotifications() async {
    final reqs = await _social.incomingRequests();
    if (mounted) _notif.setFriendRequests(reqs);
    // 친구 채팅 수신자 목록 캐시.
    final fr = await _social.friends();
    if (mounted) _friendIds = [for (final f in fr) f.id];
  }

  // 채팅 전송 라우팅: 전체=openworld(접속 전원), 파티/친구=대상 인박스.
  void _sendChat(ChatScope scope, String text) {
    final mp = _mp;
    if (mp == null) return;
    switch (scope) {
      case ChatScope.all:
        mp.sendChat(text); // 본인 메시지는 채널 에코로 표시됨
        break;
      case ChatScope.party:
        for (final id in _social.party) {
          mp.sendScopedChat(id, text, ChatScope.party);
        }
        mp.addLocalChat(
          widget.account.nickname,
          text,
          _profile.level,
          ChatScope.party,
        );
        break;
      case ChatScope.friend:
        for (final id in _friendIds) {
          mp.sendScopedChat(id, text, ChatScope.friend);
        }
        mp.addLocalChat(
          widget.account.nickname,
          text,
          _profile.level,
          ChatScope.friend,
        );
        break;
    }
  }

  // 인박스 수신(파티 초대 / 귓속말).
  void _onInbox(String fromId, String fromName, String kind, String text) {
    if (kind == 'party') {
      _notif.addPartyInvite(fromId, fromName, int.tryParse(text) ?? 1);
    } else if (kind == 'whisper') {
      _notif.addWhisper(fromId, fromName, text);
    }
  }

  Future<void> _acceptFriendReq(String id) async {
    await _social.acceptRequest(id);
    _notif.removeFriendRequest(id);
    _refreshNotifications();
  }

  void _declineFriendReq(String id) {
    _social.declineRequest(id);
    _notif.removeFriendRequest(id);
  }

  void _acceptParty(PartyInvite inv) {
    _social.addToParty(inv.id, inv.level);
    _notif.removePartyInvite(inv.id);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${inv.nickname}님과 파티를 맺었습니다.')));
    }
  }

  // 친구에게 파티 초대 / 귓속말 보내기(메뉴 친구탭에서 호출).
  void _sendPartyInvite(String id, String name) {
    _mp?.sendInbox(
      id,
      'party',
      widget.account.nickname,
      text: '${_profile.level}',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_mp != null ? '$name님에게 파티 초대를 보냈습니다.' : '오프라인 상태입니다.'),
        ),
      );
    }
  }

  void _sendWhisper(String id, String name, String text) {
    if (text.trim().isEmpty) return;
    _mp?.sendInbox(id, 'whisper', widget.account.nickname, text: text.trim());
  }

  Future<void> _promptWhisper(String id, String name) async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$name 님에게 귓속말'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: '메시지 입력…'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('보내기'),
          ),
        ],
      ),
    );
    if (text != null && text.trim().isNotEmpty) {
      _sendWhisper(id, name, text);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$name님에게 귓속말을 보냈습니다.')));
      }
    }
  }

  Future<void> _applyAvatar() async {
    final b64 = _profile.avatarBase64;
    if (b64 == null) {
      _game?.setAvatar(null, null);
      return;
    }
    final data = await decodeAvatar(b64);
    if (!mounted || data == null) return;
    _game?.setAvatar(data.pngBytes, data.image);
  }

  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    _persist();
    await AuthService.instance.logout();
    if (!mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _onNpc(String type, String name) {
    if (!mounted) return;
    if (type == 'merchant') {
      _openWindow('shop'); // 전체화면 대신 비차단 플로팅 창
    } else if (type == 'blacksmith') {
      _openWindow('blacksmith');
    } else {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(name),
          content: const Text('평화 마을에 온 걸 환영해요. 여긴 몬스터가 못 들어와 안전하답니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('닫기'),
            ),
          ],
        ),
      );
    }
  }

  // ── 인벤토리 드래그(클릭-투-무브) ──
  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), duration: const Duration(milliseconds: 1100)),
    );
  }

  // 단일클릭=집기.
  void _pickUpBag(int index) {
    if (index < 0 || index >= _profile.bag.length) return;
    setState(() {
      _held = _profile.bag[index];
      _heldFrom = index;
    });
  }

  void _clearHeld() => setState(() {
    _held = null;
    _heldFrom = null;
  });

  Rect? _keyRect(GlobalKey k) {
    final box = k.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  // 들고 있을 때 클릭한 지점을 판정: 장비 슬롯=장착 / 인벤 칸=재배치 / 그 외=월드 드랍.
  void _onDropAt(Offset g) {
    final held = _held;
    if (held == null) return;
    for (final e in _slotKeys.entries) {
      final r = _keyRect(e.value);
      if (r != null && r.contains(g)) {
        _dropOnSlot(e.key, held);
        _clearHeld();
        return;
      }
    }
    for (var i = 0; i < _bagKeys.length; i++) {
      final r = _keyRect(_bagKeys[i]);
      if (r != null && r.contains(g)) {
        if (_heldFrom != null) _profile.moveBagItem(_heldFrom!, i);
        _clearHeld();
        return;
      }
    }
    // 인벤/장비 창 영역 안의 여백(칸·슬롯 아님)에 놓으면 드랍하지 않고 원위치.
    for (final k in [_invAreaKey, _equipAreaKey]) {
      final r = _keyRect(k);
      if (r != null && r.contains(g)) {
        _clearHeld();
        return;
      }
    }
    // 창 밖 → 캐릭터 밑에 드랍(소유권 없음 → 누구나 줍기).
    if (_profile.removeFromBag(held)) _game?.dropItemAtPlayer(held);
    _clearHeld();
  }

  // 특정 슬롯에 장착 시도(종류/레벨 검증). 실패면 가방에 그대로 남는다.
  void _dropOnSlot(EquipSlot slot, BagItem held) {
    if (held is! GearItem) {
      _toast('장비만 착용할 수 있습니다.');
      return;
    }
    switch (_profile.equipToSlot(slot, held)) {
      case EquipOutcome.equipped:
        break;
      case EquipOutcome.wrongSlot:
        _toast('${slot.label} 칸에는 착용할 수 없습니다.');
      case EquipOutcome.levelLocked:
        _toast('Lv.${held.itemLevel} 이상이어야 착용할 수 있습니다.');
    }
  }

  // 더블클릭=착용(자동 슬롯). 레벨 미달이면 거부.
  void _equipFromBag(GearItem g) {
    if (!_profile.equip(g)) _toast('Lv.${g.itemLevel} 이상이어야 착용할 수 있습니다.');
  }

  // 더블클릭=사용(소비 아이템).
  void _useMiscItem(MiscItem m) {
    if (m.kind.isTownScroll) {
      _closeWindow('inv');
      _game?.useTownScrollExternal();
    } else if (m.kind.usableHeal) {
      final msg = _profile.usePotion();
      if (msg != null) _toast(msg);
    } else if (m.kind.isSkillReset) {
      if (_profile.resetSkillPoints()) {
        _profile.consumeMisc(MiscKind.skillReset);
        _toast('스킬을 초기화했습니다. (SP ${_profile.skillPoints})');
      } else {
        _toast('초기화할 스킬이 없습니다.');
      }
    } else if (m.kind.isSkillRefund) {
      _refundSkillDialog();
    } else {
      _toast('사용할 수 없는 아이템입니다.');
    }
  }

  // 스킬 되돌리기 — 현재 직업 스킬(Lv>0) 중 하나를 골라 1레벨 내린다.
  Future<void> _refundSkillDialog() async {
    final job = _profile.jobClass;
    if (job == JobClass.none) return _toast('전직 후 사용할 수 있습니다.');
    final candidates = skillsForJob(
      job,
    ).where((s) => _profile.skillLevel(s.id) > 0).toList();
    if (candidates.isEmpty) return _toast('되돌릴 스킬이 없습니다.');
    final picked = await showDialog<JobSkillId>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('되돌릴 스킬 선택'),
        children: [
          for (final s in candidates)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, s.id),
              child: Text(
                '${s.name}  (Lv ${_profile.skillLevel(s.id)} → ${_profile.skillLevel(s.id) - 1})',
              ),
            ),
        ],
      ),
    );
    if (picked != null && _profile.refundSkill(picked)) {
      _profile.consumeMisc(MiscKind.skillRefund);
      _toast('스킬을 1레벨 되돌렸습니다. (SP ${_profile.skillPoints})');
    }
  }

  // 우클릭=컨텍스트 메뉴(판매 / 잠금). 잠긴 아이템은 판매 항목 비활성.
  Future<void> _itemContextMenu(BagItem item, Offset pos) async {
    final price = item is GearItem
        ? item.sellPrice
        : (item as MiscItem).sellPrice;
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(pos.dx, pos.dy, pos.dx, pos.dy),
      items: [
        PopupMenuItem<String>(
          value: 'sell',
          enabled: !item.locked,
          child: Row(
            children: [
              const Icon(Icons.sell, size: 16, color: Color(0xFFFFD54F)),
              const SizedBox(width: 8),
              Text('아이템 판매 (${price}G)'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'lock',
          child: Row(
            children: [
              Icon(item.locked ? Icons.lock_open : Icons.lock, size: 16),
              const SizedBox(width: 8),
              Text(item.locked ? '잠금 해제' : '아이템 잠금'),
            ],
          ),
        ),
      ],
    );
    if (selected == 'sell') {
      _profile.sell(item);
      _toast('판매 +${price}G');
    } else if (selected == 'lock') {
      _profile.toggleLock(item);
    }
  }

  // 장비창 더블클릭=장착 해제(가방으로).
  void _unequipSlot(EquipSlot slot) {
    if (!_profile.unequip(slot)) _toast('가방이 가득 찼습니다.');
  }

  // 장비창 우클릭=메뉴(장착 해제 / 버리기=월드 드랍).
  Future<void> _equipSlotMenu(EquipSlot slot, GearItem gear, Offset pos) async {
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(pos.dx, pos.dy, pos.dx, pos.dy),
      items: const [
        PopupMenuItem<String>(
          value: 'unequip',
          child: Row(
            children: [
              Icon(Icons.remove_circle_outline, size: 16),
              SizedBox(width: 8),
              Text('장착 해제'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'drop',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF9A9A)),
              SizedBox(width: 8),
              Text('버리기'),
            ],
          ),
        ),
      ],
    );
    if (selected == 'unequip') {
      if (!_profile.unequip(slot)) _toast('가방이 가득 찼습니다.');
    } else if (selected == 'drop') {
      final removed = _profile.removeEquipped(slot);
      if (removed != null) _game?.dropItemAtPlayer(removed);
    }
  }

  void _openMenu([int tab = 0]) {
    _persist(); // 랭킹/파티 분배 반영 후 열기
    _closeWindow('menu');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          account: widget.account,
          profile: _profile,
          social: _social,
          settings: _settings,
          onFollow: _followFriend,
          onPartyInvite: _sendPartyInvite,
          onWhisper: _promptWhisper,
          initialTab: tab,
        ),
      ),
    );
  }

  void _useSkill(String key) => _game?.triggerSkill(key);

  // K키 / 스킬바 정보 버튼 → 스킬 창(전직 + 스킬 투자).
  void _openSkills() => _toggleWindow('skills');

  void _followFriend(String nickname) {
    final ok = _game?.followByName(nickname) ?? false;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? '$nickname 님에게 이동했습니다.' : '$nickname 님이 현재 접속 중이 아닙니다.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_bootError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_person,
                  color: Color(0xFFEF5350),
                  size: 56,
                ),
                const SizedBox(height: 16),
                Text(
                  _bootError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  ),
                  child: const Text('로그인 화면으로'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_loading || _game == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(_status),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: MouseRegion(
        onHover: (e) {
          if (_held != null) setState(() => _cursor = e.position);
        },
        child: Stack(
          children: [
            GameWidget(game: _game!),

            // 좌측 상단: 캐릭터 상태 + 좌표.
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      ListenableBuilder(
                        listenable: _profile,
                        builder: (context, _) => _StatusPanel(
                          profile: _profile,
                          online: _online,
                          status: _status,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _CoordBadge(posListenable: _game!.playerPos),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start),
                ),
              ),
            ),
            // 우측 하단: 물약 + 공격 버튼(모바일).
            if (_isMobile)
              Positioned(
                right: 28,
                bottom: 48,
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ListenableBuilder(
                        listenable: _profile,
                        builder: (context, _) => _RoundButton(
                          size: 56,
                          color: const Color(0xFF388E3C),
                          icon: Icons.local_drink,
                          label: '${_profile.potions}',
                          onTap: () => _game!.usePotionExternal(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _AttackButton(
                        onDown: () => _game!.setButtonAttack(true),
                        onUp: () => _game!.setButtonAttack(false),
                      ),
                    ],
                  ),
                ),
              ),

            // 스킬 쿨타임 바(하단 중앙).
            Positioned(
              left: 0,
              right: 0,
              bottom: 56,
              child: Center(
                child: _SkillBar(
                  game: _game!,
                  onUse: _useSkill,
                  onInfo: _openSkills,
                ),
              ),
            ),

            // 우측 하단 떠오르는 토스트 로그(배경 없음, 밑에서 위로, 5초 후 사라짐).
            Positioned(
              right: 16,
              bottom: 124,
              child: IgnorePointer(child: GameLogView(controller: _logCtrl)),
            ),

            // 우측 하단 서버/접속 진단(서버명·온라인·매치·접속자 수). 탭하면 상세.
            Positioned(
              right: 14,
              bottom: 12,
              child: SafeArea(
                child: ServerStatusBar(online: _online, mp: _mp),
              ),
            ),

            // 우하단: 채팅 패널(열렸을 때) + 아이콘 버튼들.
            Positioned(
              right: 14,
              bottom: 56,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_isOpen('notif'))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: NotificationPanel(
                          center: _notif,
                          onClose: () => _closeWindow('notif'),
                          onAcceptFriend: _acceptFriendReq,
                          onDeclineFriend: _declineFriendReq,
                          onAcceptParty: _acceptParty,
                          onDeclineParty: _notif.removePartyInvite,
                        ),
                      ),
                    if (_isOpen('chat'))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ChatPanel(
                          mp: _mp,
                          onClose: () => _closeWindow('chat'),
                          onSend: _sendChat,
                        ),
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _iconBtn(
                          Icons.menu,
                          '메뉴',
                          'ESC',
                          const Color(0xFF455A64),
                          () => _toggleWindow('menu'),
                        ),
                        const SizedBox(width: 10),
                        _iconBtn(
                          Icons.map,
                          '지도',
                          'M',
                          const Color(0xFF2E7D9A),
                          () => _toggleWindow('map'),
                        ),
                        const SizedBox(width: 10),
                        _iconBtn(
                          Icons.backpack,
                          '인벤토리',
                          'I',
                          const Color(0xFF6D4C41),
                          () => _toggleWindow('inv'),
                        ),
                        const SizedBox(width: 10),
                        _iconBtn(
                          Icons.person,
                          '내정보',
                          'E',
                          const Color(0xFF5E60CE),
                          () => _toggleWindow('equip'),
                        ),
                        const SizedBox(width: 10),
                        _iconBtn(
                          Icons.auto_awesome,
                          '스킬',
                          'K',
                          const Color(0xFF8E44AD),
                          _openSkills,
                        ),
                        const SizedBox(width: 10),
                        _iconBtn(
                          Icons.assignment_ind,
                          '캐릭터 정보',
                          'N',
                          const Color(0xFF3949AB),
                          () => _toggleWindow('charinfo'),
                        ),
                        const SizedBox(width: 10),
                        _iconBtn(
                          Icons.chat_bubble_outline,
                          '채팅',
                          '',
                          const Color(0xFF00897B),
                          () => _toggleWindow('chat'),
                        ),
                        const SizedBox(width: 10),
                        _notifButton(),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 플로팅 윈도우(인벤/내정보) — 연 순서대로 쌓여 z순서가 된다. 비차단·드래그·전체화면.
            for (final id in _openStack)
              if (id == 'inv')
                FloatingWindow(
                  key: const ValueKey('win_inv'),
                  title: '인벤토리',
                  icon: Icons.backpack,
                  initialOffset: const Offset(60, 70),
                  initialSize: const Size(380, 480),
                  onFocus: () => _focusWindow('inv'),
                  onClose: () {
                    _closeWindow('inv');
                    _applyAvatar();
                  },
                  child: KeyedSubtree(
                    key: _invAreaKey,
                    child: InventoryPanel(
                      profile: _profile,
                      cellKeys: _bagKeys,
                      hiddenIndex: _heldFrom, // 집어든 칸은 비어 보이게
                      onPickCell: _pickUpBag,
                      onEquipItem: _equipFromBag,
                      onUseItem: _useMiscItem,
                      onItemMenu: _itemContextMenu,
                      onUseTownScroll: () {
                        _closeWindow('inv');
                        _game?.useTownScrollExternal();
                      },
                    ),
                  ),
                )
              else if (id == 'equip')
                FloatingWindow(
                  key: const ValueKey('win_equip'),
                  title: '내정보 / 장비',
                  icon: Icons.person,
                  initialOffset: const Offset(130, 50),
                  initialSize: const Size(380, 580),
                  onFocus: () => _focusWindow('equip'),
                  onClose: () => _closeWindow('equip'),
                  child: KeyedSubtree(
                    key: _equipAreaKey,
                    child: CharacterPanel(
                      profile: _profile,
                      playerName: widget.account.nickname,
                      slotKeys: _slotKeys,
                      onUnequip: _unequipSlot,
                      onSlotMenu: _equipSlotMenu,
                    ),
                  ),
                )
              else if (id == 'shop')
                FloatingWindow(
                  key: const ValueKey('win_shop'),
                  title: '상점',
                  icon: Icons.storefront,
                  initialOffset: const Offset(100, 60),
                  initialSize: const Size(400, 560),
                  onFocus: () => _focusWindow('shop'),
                  onClose: () => _closeWindow('shop'),
                  child: ShopView(profile: _profile),
                )
              else if (id == 'blacksmith')
                FloatingWindow(
                  key: const ValueKey('win_blacksmith'),
                  title: '대장간 · 장비 강화',
                  icon: Icons.hardware,
                  initialOffset: const Offset(120, 50),
                  initialSize: const Size(450, 600),
                  onFocus: () => _focusWindow('blacksmith'),
                  onClose: () => _closeWindow('blacksmith'),
                  child: EnhanceView(profile: _profile),
                )
              else if (id == 'skills')
                FloatingWindow(
                  key: const ValueKey('win_skills'),
                  title: '스킬',
                  icon: Icons.auto_awesome,
                  initialOffset: const Offset(140, 60),
                  initialSize: const Size(420, 560),
                  onFocus: () => _focusWindow('skills'),
                  onClose: () => _closeWindow('skills'),
                  child: SkillScreen(profile: _profile),
                )
              else if (id == 'charinfo')
                FloatingWindow(
                  key: const ValueKey('win_charinfo'),
                  title: '캐릭터 정보',
                  icon: Icons.assignment_ind,
                  initialOffset: const Offset(150, 70),
                  initialSize: const Size(360, 480),
                  onFocus: () => _focusWindow('charinfo'),
                  onClose: () => _closeWindow('charinfo'),
                  child: CharacterInfoPanel(
                    profile: _profile,
                    playerName: widget.account.nickname,
                  ),
                ),

            // 메뉴 슬라이드업(아래→위) — 친구/파티/랭킹/설정. (배경을 가리지 않음)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                ignoring: !_isOpen('menu'),
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  offset: _isOpen('menu') ? Offset.zero : const Offset(0, 1),
                  child: _menuSheet(),
                ),
              ),
            ),

            // 전체 맵(M).
            if (_isOpen('map'))
              WorldMapOverlay(
                game: _game!,
                mp: _mp,
                playerLevel: _profile.level,
                playerName: widget.account.nickname,
                onClose: () => _closeWindow('map'),
              ),

            // 드래그 중: 클릭을 가로채 놓기/드랍 라우팅 + 커서를 따라다니는 아이템 아이콘.
            if (_held != null) ...[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => _onDropAt(d.globalPosition),
                ),
              ),
              Positioned(
                left: _cursor.dx - 22,
                top: _cursor.dy - 22,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.85,
                    child: ItemIcon.forItem(_held!, size: 44),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 알림 종 버튼 — 우상단에 알림 개수 빨간 뱃지.
  Widget _notifButton() {
    return ListenableBuilder(
      listenable: _notif,
      builder: (context, _) {
        final n = _notif.count;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _iconBtn(
              Icons.notifications,
              '알림',
              '',
              const Color(0xFFB8860B),
              () => _toggleWindow('notif'),
            ),
            if (n > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    n > 99 ? '99+' : '$n',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // 좌측 하단 아이콘 버튼 — hover 시 "라벨(키)" 흰색 둥근 툴팁.
  Widget _iconBtn(
    IconData icon,
    String label,
    String keyHint,
    Color color,
    VoidCallback onTap,
  ) {
    final tip = keyHint.isEmpty ? label : '$label($keyHint)';
    return Tooltip(
      message: tip,
      preferBelow: false,
      verticalOffset: 34,
      waitDuration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
      ),
      textStyle: const TextStyle(
        color: Color(0xFF1A1A1A),
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 1.5),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  // 아래에서 위로 올라오는 메뉴 시트.
  Widget _menuSheet() {
    Widget item(
      IconData icon,
      String label,
      VoidCallback onTap, {
      Color? color,
    }) => ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF90CAF9)),
      title: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white38),
      onTap: onTap,
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Material(
          color: const Color(0xFF1E222A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 6),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    '메뉴',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                item(Icons.group, '친구', () => _openMenu(0)),
                item(Icons.diversity_3, '파티', () => _openMenu(2)),
                item(Icons.leaderboard, '랭킹', () => _openMenu(1)),
                item(Icons.settings, '설정', () => _openMenu(3)),
                const Divider(height: 1),
                item(
                  Icons.logout,
                  '로그아웃',
                  _logout,
                  color: const Color(0xFFEF9A9A),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 스킬 쿨타임 바 — 6칸(A~H) + 정보 버튼. skillTick 으로 갱신.
class _SkillBar extends StatelessWidget {
  final RpgGame game;
  final void Function(String key) onUse;
  final VoidCallback onInfo;
  const _SkillBar({
    required this.game,
    required this.onUse,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.skillTick,
      builder: (context, _, _) {
        final states = game.skillStates();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: '스킬 정보',
                icon: const Icon(
                  Icons.help_outline,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: onInfo,
              ),
              ...states.map((st) => _slot(st)),
            ],
          ),
        );
      },
    );
  }

  Widget _slot(SkillSlot st) {
    final active = st.usable; // 발동 가능(직업: Lv>0)
    final onCd = st.cd > 0;
    return GestureDetector(
      onTap: active && !onCd ? () => onUse(st.key) : null,
      child: Container(
        width: 52,
        height: 52,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2A3240) : const Color(0x33000000),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onCd
                ? Colors.white24
                : (active ? const Color(0xFF7E9CD8) : Colors.white10),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            // 발동 키.
            Positioned(
              left: 3,
              top: 1,
              child: Text(
                st.key,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // 직업 스킬 레벨(우상단). 무기 스킬(level<0)은 표시 안 함.
            if (st.level >= 0)
              Positioned(
                right: 3,
                top: 1,
                child: Text(
                  'Lv${st.level}',
                  style: TextStyle(
                    color: active ? const Color(0xFF9CCC65) : Colors.white38,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            // 이름(미습득=회색).
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 16, 2, 2),
              child: Center(
                child: Text(
                  st.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.white38,
                    fontSize: 8.5,
                    height: 1.05,
                  ),
                ),
              ),
            ),
            if (onCd)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: (st.cd / st.total).clamp(0.0, 1.0),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ),
            if (onCd)
              Center(
                child: Text(
                  st.cd.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// 좌표 뱃지(스로틀된 위치 표시).
class _CoordBadge extends StatelessWidget {
  final ValueListenable<Offset> posListenable;
  const _CoordBadge({required this.posListenable});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: ValueListenableBuilder<Offset>(
        valueListenable: posListenable,
        builder: (context, p, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.my_location,
              size: 13,
              color: Colors.lightBlueAccent,
            ),
            const SizedBox(width: 5),
            // 1 블럭(32px) = 좌표 1.
            Text(
              'X ${(p.dx / 32).round()}   Y ${(p.dy / 32).round()}',
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final PlayerProfile profile;
  final bool online;
  final String status;

  const _StatusPanel({
    required this.profile,
    required this.online,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final s = profile.total;
    final hpRatio = profile.maxHp == 0
        ? 0.0
        : (profile.hp / profile.maxHp).clamp(0.0, 1.0);
    return Container(
      width: 216,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield, color: Colors.amberAccent, size: 16),
              const SizedBox(width: 6),
              Text(
                'Lv.${profile.level}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.monetization_on,
                color: Color(0xFFFFD54F),
                size: 14,
              ),
              const SizedBox(width: 3),
              Text(
                '${profile.gold}',
                style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 12),
              ),
              const SizedBox(width: 8),
              Icon(
                online ? Icons.cloud_done : Icons.cloud_off,
                color: online ? Colors.greenAccent : Colors.orangeAccent,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _bar(
            'HP  ${profile.hp} / ${profile.maxHp}',
            hpRatio,
            const [Color(0xFFEF5350), Color(0xFFFF8A65)],
            const Color(0x66B71C1C),
          ),
          const SizedBox(height: 5),
          _bar(
            'EXP ${profile.exp} / ${profile.expToNext}',
            profile.expRatio,
            const [Color(0xFF7E57C2), Color(0xFFB39DDB)],
            const Color(0x664527A0),
            height: 9,
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 9,
            runSpacing: 2,
            children: [
              _chip(
                Icons.gavel,
                'ATK ${s.attack.round()}',
                Colors.orangeAccent,
              ),
              _chip(
                Icons.security,
                'DEF ${s.defense.round()}',
                Colors.lightBlueAccent,
              ),
              _chip(
                Icons.flash_on,
                '관통 ${s.armorPen.round()}',
                Colors.amberAccent,
              ),
              _chip(
                Icons.star,
                '치명 ${(s.critChance * 100).round()}%',
                Colors.redAccent,
              ),
              _chip(
                Icons.speed,
                '공속 ${s.attackSpeed.toStringAsFixed(2)}',
                Colors.greenAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bar(
    String label,
    double ratio,
    List<Color> fill,
    Color bg, {
    double height = 14,
  }) {
    return Stack(
      children: [
        Container(
          height: height,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
        FractionallySizedBox(
          widthFactor: ratio,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: fill),
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String value, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 2),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 10)),
    ],
  );
}

class _RoundButton extends StatelessWidget {
  final double size;
  final Color color;
  final IconData icon;
  final String? label;
  final VoidCallback onTap;

  const _RoundButton({
    required this.size,
    required this.color,
    required this.icon,
    required this.onTap,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: 0.5,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              if (label != null)
                Text(
                  label!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttackButton extends StatefulWidget {
  final VoidCallback onDown;
  final VoidCallback onUp;

  const _AttackButton({required this.onDown, required this.onUp});

  @override
  State<_AttackButton> createState() => _AttackButtonState();
}

class _AttackButtonState extends State<_AttackButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        widget.onDown();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onUp();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        widget.onUp();
      },
      child: Opacity(
        opacity: _pressed ? 0.75 : 0.5,
        child: Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.shade700,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.gps_fixed, color: Colors.white, size: 30),
              SizedBox(height: 2),
              Text(
                '공격',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
