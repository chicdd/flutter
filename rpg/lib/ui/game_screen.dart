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
import '../models/instance.dart';
import '../models/skills.dart';
import '../net/audio_service.dart';
import '../net/multiplayer.dart';
import '../net/nakama_service.dart';
import '../net/auth_service.dart';
import '../net/profile_store.dart';
import '../net/social_service.dart';
import '../state/player_profile.dart';
import '../state/settings.dart';
import '../util/avatar.dart';
import 'auth/login_screen.dart';
import 'character_panel.dart';
import 'chat_panel.dart';
import 'enhance_screen.dart';
import 'floating_window.dart';
import 'game_log.dart';
import 'inventory_panel.dart';
import 'menu/menu_screen.dart';
import 'minimap.dart';
import 'shop_screen.dart';
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
  bool _loading = true;
  bool _online = false;
  // 열린 창들의 스택(연 순서). ESC 는 맨 위(마지막에 연 창)부터 닫고, 비면 메뉴를 연다.
  // id: 'inv' 인벤토리 / 'equip' 내정보 / 'map' 지도 / 'chat' 채팅 / 'menu' 메뉴.
  final List<String> _openStack = [];
  String _status = '서버 연결 중...';
  final GameLogController _logCtrl = GameLogController();

  bool _isOpen(String id) => _openStack.contains(id);

  void _openWindow(String id) => setState(() {
        _openStack
          ..remove(id)
          ..add(id);
      });

  void _closeWindow(String id) => setState(() => _openStack.remove(id));

  void _toggleWindow(String id) => _isOpen(id) ? _closeWindow(id) : _openWindow(id);

  // 드래그/탭 시 맨 앞으로.
  void _focusWindow(String id) {
    if (_openStack.isNotEmpty && _openStack.last != id && _isOpen(id)) {
      setState(() => _openStack
        ..remove(id)
        ..add(id));
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
    _persist();
    _mp?.dispose();
    _logCtrl.dispose();
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

  Future<void> _boot() async {
    // 설정 로드 + 저장된 진행상황 복원.
    await _settings.load();
    AudioService.instance.preload();
    final saved = await ProfileStore.loadRaw(widget.account.id);
    if (saved != null) _profile.loadJson(saved);

    GameInstance instance;
    bool online;
    try {
      // 계정별 고유 디바이스 ID → 계정마다 별개의 Nakama 신원(멀티플레이어 식별 개선).
      await NakamaService.instance.connect(
        deviceId: 'rpg-acct-${widget.account.id}',
      );
      // 친구 검색/추가가 기기를 넘어 동작하도록 ID·닉네임을 서버 계정에 동기화(best-effort).
      unawaited(
        NakamaService.instance.syncIdentity(
          id: widget.account.id,
          nickname: widget.account.nickname,
        ),
      );
      instance = await NakamaService.instance.createInstance();
      online = true;
    } catch (e) {
      final seed = Random().nextInt(0x7FFFFFFF);
      instance = GameInstance(
        runSeed: seed,
        biome: 'forest',
        monsters: generateMonstersOffline(seed),
      );
      online = false;
    }

    final mp = online ? MultiplayerService(NakamaService.instance) : null;
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
      onToggleSkills: _showSkillInfo,
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
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ShopScreen(profile: _profile, title: name),
        ),
      );
    } else if (type == 'blacksmith') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EnhanceScreen(profile: _profile, title: '$name · 장비 강화'),
        ),
      );
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
          initialTab: tab,
        ),
      ),
    );
  }

  void _useSkill(String key) => _game?.triggerSkill(key);

  void _showSkillInfo() {
    final skills = _game?.currentSkills() ?? [];
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('스킬 정보'),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: skills.isEmpty
                ? [const Text('무기를 장착하면 스킬을 사용할 수 있습니다.')]
                : skills
                      .map(
                        (s) => ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            child: Text(
                              s.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            '${s.name}  (쿨 ${s.cooldown.toStringAsFixed(0)}초)',
                          ),
                          subtitle: Text(s.desc),
                        ),
                      )
                      .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

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
      body: Stack(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 미니맵(5배 축소 · 몬스터/플레이어/마을/접속자).
                    ListenableBuilder(
                      listenable: _profile,
                      builder: (context, _) => Minimap(
                        game: _game!,
                        mp: _mp,
                        playerLevel: _profile.level,
                      ),
                    ),
                  ],
                ),
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
                onInfo: _showSkillInfo,
              ),
            ),
          ),

          // 우측 하단 떠오르는 토스트 로그(배경 없음, 밑에서 위로, 5초 후 사라짐).
          Positioned(
            right: 16,
            bottom: 124,
            child: IgnorePointer(
              child: GameLogView(controller: _logCtrl),
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
                  if (_isOpen('chat'))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ChatPanel(mp: _mp, onClose: () => _closeWindow('chat')),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _iconBtn(Icons.menu, '메뉴', 'ESC', const Color(0xFF455A64), () => _toggleWindow('menu')),
                      const SizedBox(width: 10),
                      _iconBtn(Icons.map, '지도', 'M', const Color(0xFF2E7D9A), () => _toggleWindow('map')),
                      const SizedBox(width: 10),
                      _iconBtn(Icons.backpack, '인벤토리', 'I', const Color(0xFF6D4C41), () => _toggleWindow('inv')),
                      const SizedBox(width: 10),
                      _iconBtn(Icons.person, '내정보', 'E', const Color(0xFF5E60CE), () => _toggleWindow('equip')),
                      const SizedBox(width: 10),
                      _iconBtn(Icons.auto_awesome, '스킬', 'K', const Color(0xFF8E44AD), _showSkillInfo),
                      const SizedBox(width: 10),
                      _iconBtn(Icons.chat_bubble_outline, '채팅', '', const Color(0xFF00897B), () => _toggleWindow('chat')),
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
                child: InventoryPanel(
                  profile: _profile,
                  onUseTownScroll: () {
                    _closeWindow('inv');
                    _game?.useTownScrollExternal();
                  },
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
                child: CharacterPanel(
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
        ],
      ),
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

  Widget _slot(({String key, SkillDef? def, double cd, double total}) st) {
    final has = st.def != null;
    final onCd = st.cd > 0;
    return GestureDetector(
      onTap: has && !onCd ? () => onUse(st.key) : null,
      child: Container(
        width: 46,
        height: 52,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: has ? const Color(0xFF2A3240) : const Color(0x33000000),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onCd
                ? Colors.white24
                : (has ? const Color(0xFF7E9CD8) : Colors.white10),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
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
            if (has)
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 16, 2, 2),
                child: Center(
                  child: Text(
                    st.def!.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      height: 1.05,
                    ),
                  ),
                ),
              )
            else
              const Center(
                child: Text('—', style: TextStyle(color: Colors.white24)),
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
