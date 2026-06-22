// FLAME 게임 루트 (§9). 오픈월드 + 입력 + 전투 + 루팅 + 몬스터 리스폰 + 실시간 멀티플레이어.
// 전투 수치는 PlayerProfile(공유 상태)에서 읽고, 보상도 프로필에 기록한다.
// 다른 플레이어 위치는 MultiplayerService(릴레이 매치)로 주고받아 맵에 렌더한다.
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../models/combat_stats.dart';
import '../models/drop_result.dart';
import '../models/gear.dart';
import '../models/instance.dart';
import '../models/items.dart';
import '../models/loot.dart';
import '../models/skills.dart';
import '../net/audio_service.dart';
import '../net/multiplayer.dart';
import '../net/nakama_service.dart';
import '../state/player_profile.dart';
import '../state/settings.dart';
import 'components/attack_effect.dart';
import 'components/damage_text.dart';
import 'components/monster.dart';
import 'components/npc.dart';
import 'components/player.dart';
import 'components/projectile.dart';
import 'components/remote_player.dart';
import 'components/skill_effect.dart';
import 'world/environment_field.dart';
import 'world/terrain.dart';
import 'world/town.dart';
import 'world/zones.dart';

class RpgGame extends FlameGame with KeyboardEvents {
  final GameInstance instance;
  final bool online;
  final bool showTouchControls;
  final NakamaService net;
  final MultiplayerService? mp;
  final PlayerProfile profile;
  final GameSettings settings;
  final String playerName;
  final double Function() selfExpMultiplier; // 파티 보너스
  final void Function(int baseExp) onKillExp; // 파티 경험치 공유
  final void Function(String message, Color color) onLog; // 떠오르는 토스트 로그
  final void Function() onToggleInventory; // I 키
  final void Function(String type, String name) onNpc; // NPC 상호작용
  final void Function() onToggleMenuBar; // ESC/메뉴 슬라이드업
  final void Function() onToggleMap; // M 키 전체 맵
  final void Function() onToggleEquipment; // E 키 장비창
  final void Function() onToggleSkills; // K 키 스킬 정보

  // 비전투 마을(안전지대).
  static final Vector2 townCenter = Vector2(1000, 1000);
  static const double townRadius = 360;

  static const int maxMonsters = 14; // 동시 유지 몬스터 수
  static const double respawnInterval = 4.0; // 리스폰 점검 주기(s)
  static const double despawnRange = 1700; // 이 거리 밖 몬스터는 회수(플레이어 주변 유지)
  static const double spawnMinR = 620; // 리스폰 거리(플레이어 기준)
  static const double spawnMaxR = 1150;
  static const int _syntheticIdxBase = 100000; // 리스폰 몬스터 idx(서버 보고 제외)

  static const Color _dmgToMonster = Color(0xFFFFFFFF);
  static const Color _dmgCrit = Color(0xFFFFC107);
  static const Color _dmgToPlayer = Color(0xFFFF5252);

  // 토스트 로그 색(종류별 구분).
  static const Color logReward = Color(0xFFFFD54F); // 골드/처치 보상
  static const Color logExp = Color(0xFFB39DDB); // 경험치
  static const Color logLevel = Color(0xFF82B1FF); // 레벨업
  static const Color logHeal = Color(0xFF69F0AE); // 회복
  static const Color logInfo = Color(0xFF80CBC4); // 정보/서버
  static const Color logDanger = Color(0xFFFF5252); // 사망/위험

  final Random _rng = Random();

  late final PlayerComponent player;
  JoystickComponent? _joystick;

  final List<MonsterComponent> _monsters = [];
  final Map<String, RemotePlayerComponent> _remotes = {};
  final Map<int, MonsterComponent> _serverMonsters = {}; // 서버 권위 공유 몬스터
  int _spawnIdx = _syntheticIdxBase;

  // 좌표 표시용(스로틀 갱신).
  final ValueNotifier<Offset> playerPos = ValueNotifier<Offset>(Offset.zero);

  double _attackTimer = 0;
  double _respawnTimer = respawnInterval;
  double _posTimer = 0;
  double _netTimer = 0;
  double _avatarTimer = 0;
  bool _keyboardAttack = false;
  bool _buttonAttack = false;

  Uint8List? _avatarBytes; // 내 아바타 PNG(주기적으로 브로드캐스트)
  ui.Image? _avatarImage; // 디코드된 내 아바타(로드 전 보관 후 onLoad 에서 적용)

  RpgGame({
    required this.instance,
    required this.online,
    required this.showTouchControls,
    required this.net,
    required this.mp,
    required this.profile,
    required this.settings,
    required this.playerName,
    required this.selfExpMultiplier,
    required this.onKillExp,
    required this.onLog,
    required this.onToggleInventory,
    required this.onNpc,
    required this.onToggleMenuBar,
    required this.onToggleMap,
    required this.onToggleEquipment,
    required this.onToggleSkills,
  });

  // 스킬 쿨다운(키별).
  final Map<String, double> _skillCd = {for (final k in skillKeys) k: 0};
  final ValueNotifier<int> skillTick = ValueNotifier<int>(0);
  double _skillTickTimer = 0;

  WeaponType? get _weaponType => profile.equipped[EquipSlot.weapon]?.weaponType;

  // 지분제 보상에서 "나"를 식별하는 id(온라인이면 Nakama userId, 아니면 닉네임).
  String get _localId => net.userId ?? playerName;

  // 서버 권위 모드(공유 몬스터). 서버 모듈 미배포면 false → 로컬 스폰 폴백.
  bool get _authoritative => mp?.authoritative ?? false;

  bool _isElite(int seed, int idx) {
    var h = (seed ^ (idx * 0x9E3779B1)) & 0x7FFFFFFF;
    h = ((h ^ (h >> 13)) * 1274126177) & 0x7FFFFFFF;
    return (h % 100) < 20;
  }

  // 보로노이 월드의 모든 마을(안전지대)에서 안전 — 피해/스폰 차단에 사용.
  bool get inTown => WorldZones.inSafeZone(player.position.x, player.position.y);

  @override
  Future<void> onLoad() async {
    await world.add(TerrainComponent(seed: instance.runSeed));
    // 절차적 환경 에셋(나무/돌/건물) — 포아송 배치 + 위험도별 외형 + 뷰포트 GC.
    await world.add(EnvironmentField(seed: WorldZones.seed));
    await world.add(TownComponent(center: townCenter, radius: townRadius));
    _addNpcs();

    player = PlayerComponent(profile: profile)
      ..position = Vector2(profile.lastX, profile.lastY);
    player.avatar = _avatarImage; // 로드 전에 지정된 아바타 적용
    await world.add(player);

    for (final m in instance.monsters) {
      _addMonster(m, _isElite(instance.runSeed, m.idx));
    }

    camera.follow(player);
    camera.viewfinder.zoom = 1.2;

    if (showTouchControls) {
      _joystick = JoystickComponent(
        knob: CircleComponent(
          radius: 28,
          paint: Paint()..color = const Color(0x80FFFFFF),
        ),
        background: CircleComponent(
          radius: 64,
          paint: Paint()..color = const Color(0x33FFFFFF),
        ),
        margin: const EdgeInsets.only(left: 36, bottom: 48),
      );
      await camera.viewport.add(_joystick!);
    }

    // 실시간 매치 참가(온라인일 때만, best-effort) — 같은 월드에 수렴해 다른 플레이어가 보인다.
    if (mp != null) {
      mp!.onReward = _applyServerReward; // 서버 권위 지분 보상 수신.
      unawaited(mp!.join(matchName: 'openworld'));
    }
  }

  void _addNpcs() {
    final npcs = [
      (
        'merchant',
        '상인 토비',
        const Color(0xFF43A047),
        Vector2(townCenter.x - 110, townCenter.y - 40),
      ),
      (
        'blacksmith',
        '대장장이 군터',
        const Color(0xFF6D4C41),
        Vector2(townCenter.x + 120, townCenter.y - 30),
      ),
      (
        'villager',
        '마을 사람 리나',
        const Color(0xFF5C6BC0),
        Vector2(townCenter.x - 30, townCenter.y + 120),
      ),
    ];
    for (final n in npcs) {
      world.add(
        NpcComponent(
          npcType: n.$1,
          npcName: n.$2,
          color: n.$3,
          position: n.$4,
          onInteract: onNpc,
        ),
      );
    }
  }

  void teleportToTown() {
    player.position = townCenter.clone();
    profile.lastX = townCenter.x;
    profile.lastY = townCenter.y;
    onLog('마을로 귀환했습니다.', logInfo);
  }

  // 몬스터 레벨은 "스폰 위치의 섹터 존"으로 결정된다(플레이어 레벨과 무관, 전 클라이언트 동일).
  void _addMonster(InstanceMonster data, bool elite, {int? monsterLevel}) {
    final lv = monsterLevel ?? WorldZones.levelAt(data.x, data.y);
    final m = MonsterComponent(
      data: data,
      player: player,
      elite: elite,
      levelScale: WorldZones.scaleForLevel(lv),
      level: lv,
      onMelee: monsterAttackPlayer,
    );
    _monsters.add(m);
    world.add(m);
  }

  void _spawnMonsterNearPlayer() {
    // 마을(안전지대)을 피해 몇 번 재시도(어느 마을이든). 실패해도 진행은 보장.
    var pos = player.position.clone();
    for (var attempt = 0; attempt < 6; attempt++) {
      final angle = _rng.nextDouble() * pi * 2;
      final r = spawnMinR + _rng.nextDouble() * (spawnMaxR - spawnMinR);
      pos = player.position + Vector2(cos(angle), sin(angle)) * r;
      if (!WorldZones.inSafeZone(pos.x, pos.y)) break;
    }

    // 스폰 위치의 존 레벨대로 종류/체력 결정(섹터별 1~50 분포).
    final lvl = WorldZones.levelAt(pos.x, pos.y);
    final pick = WorldZones.pickMonster(lvl, _rng);
    final elite = _rng.nextDouble() < 0.18;
    _addMonster(
      InstanceMonster(
        idx: _spawnIdx++,
        templateId: pick.$1,
        x: pos.x,
        y: pos.y,
        hp: pick.$2,
      ),
      elite,
      monsterLevel: lvl,
    );
  }

  void _maintainMonsters() {
    // 너무 멀어졌거나(뷰포트/추적 범위 밖) 마을에 들어온 몬스터 회수(GC).
    _monsters.removeWhere((m) {
      if (m.position.distanceTo(player.position) > despawnRange ||
          WorldZones.inSafeZone(m.position.x, m.position.y)) {
        m.removeFromParent();
        return true;
      }
      return false;
    });
    // 마을 안에서는 몬스터를 채우지 않음(안전지대).
    if (inTown) return;
    while (_monsters.length < maxMonsters) {
      _spawnMonsterNearPlayer();
    }
  }

  // 서버 권위 공유 몬스터를 스냅샷에 맞춰 생성/갱신/제거.
  void _syncServerMonsters() {
    final svc = mp;
    if (svc == null) return;
    // 권위 전환 시 남아있던 로컬 몬스터 제거(서버 몬스터만 유지).
    _monsters.removeWhere((m) {
      if (!m.networked) {
        m.removeFromParent();
        return true;
      }
      return false;
    });

    final seen = <int>{};
    for (final nm in svc.netMonsters.values) {
      seen.add(nm.id);
      var m = _serverMonsters[nm.id];
      if (m == null) {
        m = MonsterComponent(
          data: InstanceMonster(idx: nm.id, templateId: nm.t, x: nm.x, y: nm.y, hp: nm.mhp),
          player: player,
          elite: nm.el,
          levelScale: WorldZones.scaleForLevel(nm.lv),
          level: nm.lv,
          onMelee: monsterAttackPlayer,
          networked: true,
          netId: nm.id,
        );
        _serverMonsters[nm.id] = m;
        _monsters.add(m);
        world.add(m);
      }
      m.applyNet(nm.x, nm.y, nm.hp, nm.mhp);
    }
    final gone = _serverMonsters.keys.where((k) => !seen.contains(k)).toList();
    for (final k in gone) {
      final m = _serverMonsters.remove(k);
      if (m != null) {
        _monsters.remove(m);
        m.removeFromParent();
      }
    }
  }

  // 서버에서 받은 지분 보상 적용(골드/경험치 권위, 아이템은 자격 시 로컬 롤).
  void _applyServerReward(int gold, int exp, bool loot, String templateId, bool elite, int lv) {
    if (!isLoaded) return;
    final prev = profile.level;
    if (gold > 0) {
      profile.addGold(gold);
      onLog('+$gold G', logReward);
    }
    final gained = (exp * selfExpMultiplier()).round();
    if (gained > 0) {
      profile.gainExp(gained);
      onLog('+$gained EXP', logExp);
    }
    if (loot) {
      final roll = LootSystem.roll(templateId: templateId, elite: elite, playerLevel: lv, rng: _rng);
      for (final BagItem g in roll.items) {
        if (profile.addItem(g)) onLog('획득: ${g.name}', Color(g.rarity.colorValue));
      }
    }
    if (profile.level > prev) {
      onLog('레벨업! Lv.${profile.level}', logLevel);
      AudioService.instance.play('level', settings.sfxVolume);
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    player.setMovement(keysPressed);
    _keyboardAttack =
        keysPressed.contains(LogicalKeyboardKey.controlLeft) ||
        keysPressed.contains(LogicalKeyboardKey.controlRight);

    if (event is KeyDownEvent) {
      final k = event.logicalKey;

      // 1. 일반 기능 키 매핑 (대소문자 구분 없음)
      final Map<LogicalKeyboardKey, Function> actionMap = {
        LogicalKeyboardKey.keyQ: _tryPotion,
        LogicalKeyboardKey.keyB: _tryTownScroll,
        LogicalKeyboardKey.keyI: onToggleInventory,
        LogicalKeyboardKey.keyE: onToggleEquipment,
        LogicalKeyboardKey.keyM: onToggleMap,
        LogicalKeyboardKey.keyK: onToggleSkills,
        LogicalKeyboardKey.escape: onToggleMenuBar,
      };

      // 2. 스킬 키 매핑 (대소문자 구분 없음)
      final Map<LogicalKeyboardKey, String> skillMap = {
        LogicalKeyboardKey.keyA: 'A',
        LogicalKeyboardKey.keyS: 'S',
        LogicalKeyboardKey.keyD: 'D',
        LogicalKeyboardKey.keyF: 'F',
        LogicalKeyboardKey.keyG: 'G',
        LogicalKeyboardKey.keyH: 'H',
      };

      // 3. 매핑된 키 실행
      if (actionMap.containsKey(k)) {
        actionMap[k]!();
      } else if (skillMap.containsKey(k)) {
        triggerSkill(skillMap[k]!);
      }
    }
    return KeyEventResult.handled;
  }

  // ── 스킬 ──
  void triggerSkill(String key) {
    if (!isLoaded || profile.isDead) return;
    final def = skillForKey(_weaponType, key);
    if (def == null) return;
    if ((_skillCd[key] ?? 0) > 0) return;
    _skillCd[key] = def.cooldown;
    player.triggerAttackAnim();
    _executeSkill(def.id);
  }

  List<({String key, SkillDef? def, double cd, double total})> skillStates() {
    final result = <({String key, SkillDef? def, double cd, double total})>[];
    for (final k in skillKeys) {
      final def = skillForKey(_weaponType, k);
      result.add((
        key: k,
        def: def,
        cd: _skillCd[k] ?? 0,
        total: def?.cooldown ?? 1,
      ));
    }
    return result;
  }

  List<SkillDef> currentSkills() => skillsForWeapon(_weaponType);

  void setButtonAttack(bool pressed) => _buttonAttack = pressed;
  void usePotionExternal() => _tryPotion();

  // 아바타 적용(본인 렌더 + 네트워크 브로드캐스트 대상).
  void setAvatar(Uint8List? pngBytes, ui.Image? image) {
    _avatarBytes = pngBytes;
    _avatarImage = image;
    if (isLoaded) player.avatar = image;
    if (mp != null && pngBytes != null) mp!.sendAvatar(pngBytes);
  }

  void _tryPotion() {
    if (!isLoaded) return;
    final hpBefore = profile.hp;
    final msg = profile.usePotion();
    if (msg != null && profile.hp > hpBefore) {
      _spawnDamageText(
        player.position.clone()..y -= player.size.y / 2,
        0,
        const Color(0xFF69F0AE),
        label: '+회복',
      );
      AudioService.instance.play('potion', settings.sfxVolume);
    }
    if (msg != null) onLog(msg, logHeal);
  }

  void _tryTownScroll() {
    if (!isLoaded) return;
    if (inTown) {
      onLog('이미 마을에 있습니다.', logInfo);
      return;
    }
    if (profile.consumeMisc(MiscKind.townScroll)) {
      teleportToTown();
    } else {
      onLog('마을 귀환 주문서가 없습니다. (단축키 B)', logInfo);
    }
  }

  void useTownScrollExternal() => _tryTownScroll();

  @override
  void update(double dt) {
    super.update(dt);
    if (_joystick != null) player.setJoystick(_joystick!.relativeDelta);

    _attackTimer -= dt;
    if ((_keyboardAttack || _buttonAttack) &&
        _attackTimer <= 0 &&
        !profile.isDead) {
      final wp = WeaponProfile.of(
        profile.equipped[EquipSlot.weapon]?.weaponType,
      );
      _attemptAttack(wp);
      _attackTimer = profile.attackInterval * wp.speedMult;
    }

    if (_authoritative) {
      // 서버 권위: 공유 몬스터를 스냅샷으로 동기화(로컬 스폰 안 함).
      _syncServerMonsters();
    } else {
      _respawnTimer -= dt;
      if (_respawnTimer <= 0) {
        _respawnTimer = respawnInterval;
        _maintainMonsters();
      }
    }

    _posTimer -= dt;
    if (_posTimer <= 0) {
      _posTimer = 0.15;
      playerPos.value = Offset(player.position.x, player.position.y);
      profile.lastX = player.position.x; // 재접속 복귀용
      profile.lastY = player.position.y;
    }

    // 스킬 쿨다운.
    for (final k in skillKeys) {
      if ((_skillCd[k] ?? 0) > 0)
        _skillCd[k] = (_skillCd[k]! - dt).clamp(0, 999);
    }
    _skillTickTimer -= dt;
    if (_skillTickTimer <= 0) {
      _skillTickTimer = 0.1;
      skillTick.value++;
    }

    if (mp != null) {
      _netTimer -= dt;
      if (_netTimer <= 0) {
        _netTimer = 0.12;
        mp!.sendPosition(
          x: player.position.x,
          y: player.position.y,
          level: profile.level,
          name: playerName,
        );
        _syncRemotes();
      }
      // 아바타 주기적 브로드캐스트(새로 들어온 플레이어도 받도록).
      _avatarTimer -= dt;
      if (_avatarTimer <= 0) {
        _avatarTimer = 3.0;
        // 권위 매치 핸들러는 아바타를 중계하지 않음(relayed 폴백에서만 전송).
        if (!_authoritative && _avatarBytes != null) mp!.sendAvatar(_avatarBytes!);
      }
    }
  }

  // 원격 플레이어 아바타 디코드(버전이 바뀌면 1회).
  void _decodeRemoteAvatar(RemotePlayerComponent rc, RemotePlayerState st) {
    final bytes = st.avatarBytes;
    if (bytes == null || rc.avatarVersion == st.avatarVersion) return;
    final version = st.avatarVersion;
    rc.avatarVersion = version; // 중복 디코드 방지
    ui.decodeImageFromList(Uint8List.fromList(bytes), (img) {
      rc.avatar = img;
    });
  }

  void _syncRemotes() {
    final svc = mp;
    if (svc == null) return;
    final seen = <String>{};
    for (final st in svc.players.values) {
      seen.add(st.sessionId);
      var rc = _remotes[st.sessionId];
      if (rc == null) {
        rc = RemotePlayerComponent(
          sessionId: st.sessionId,
          playerName: st.name,
          level: st.level,
          position: Vector2(st.x, st.y),
        );
        _remotes[st.sessionId] = rc;
        world.add(rc);
      } else {
        rc.setTarget(st.x, st.y, st.level, st.name);
      }
      _decodeRemoteAvatar(rc, st);
    }
    final gone = _remotes.keys.where((k) => !seen.contains(k)).toList();
    for (final k in gone) {
      _remotes[k]?.removeFromParent();
      _remotes.remove(k);
    }
  }

  // 바라보는 방향 기준 공격(자동 타겟 아님). 무기 종류에 따라 사거리/부채꼴/관통/원거리가 다르다.
  void _attemptAttack(WeaponProfile wp) {
    player.triggerAttackAnim();
    AudioService.instance.weaponAttack(_weaponType, settings.sfxVolume);
    final facing = player.facing;
    final cosLimit = cos(wp.halfAngleDeg * pi / 180);

    // 정면 부채꼴 안의 살아있는 몬스터 수집.
    final hits = <MapEntry<MonsterComponent, double>>[];
    for (final m in _monsters) {
      if (m.isDead) continue;
      final v = m.position - player.position;
      final d = v.length;
      if (d > wp.range) continue;
      if (d > 1) {
        final cosA = (v.x * facing.x + v.y * facing.y) / d;
        if (cosA < cosLimit) continue; // 시야 밖
      }
      hits.add(MapEntry(m, d));
    }
    hits.sort((a, b) => a.value.compareTo(b.value));

    if (wp.ranged) {
      // 원거리: 정면에서 가장 가까운 적 1체 + 투사체 시각효과.
      final magic =
          profile.equipped[EquipSlot.weapon]?.weaponType == WeaponType.staff;
      final aimDir = facing.clone()..normalize();
      final targetPos = hits.isNotEmpty
          ? hits.first.key.position.clone()
          : player.position + aimDir * wp.range;
      world.add(
        ProjectileComponent(
          start: player.position.clone(),
          target: targetPos,
          color: magic ? const Color(0xFFB388FF) : const Color(0xFFFFF59D),
          magic: magic,
        ),
      );
      if (hits.isNotEmpty) _playerAttackMonster(hits.first.key);
      return;
    }

    if (hits.isEmpty) return;
    if (wp.cleave) {
      for (final h in hits) {
        _playerAttackMonster(h.key);
      }
    } else {
      _playerAttackMonster(hits.first.key);
    }
  }

  // ── 전체 맵(M) 오버레이용 ──
  Vector2 get playerWorldPos => player.position;
  double get cameraZoom => camera.viewfinder.zoom;
  List<({double x, double y, int level, bool elite})> monsterMarkers() => [
        for (final m in _monsters)
          if (!m.isDead) (x: m.position.x, y: m.position.y, level: m.level, elite: m.elite),
      ];

  // 친구(닉네임)가 같은 맵에 접속해 있으면 그 옆으로 이동.
  bool followByName(String nickname) {
    for (final rc in _remotes.values) {
      if (rc.playerName == nickname) {
        player.position = rc.position + Vector2(40, 0);
        return true;
      }
    }
    return false;
  }

  // ── 스킬 실행 ──
  List<MonsterComponent> _coneMonsters(double range, double halfDeg) {
    final facing = player.facing;
    final cosLimit = cos(halfDeg * pi / 180);
    final out = <MonsterComponent>[];
    for (final m in _monsters) {
      if (m.isDead) continue;
      final v = m.position - player.position;
      final d = v.length;
      if (d > range) continue;
      if (d > 1 && (v.x * facing.x + v.y * facing.y) / d < cosLimit) continue;
      out.add(m);
    }
    return out;
  }

  List<MonsterComponent> _radiusMonsters(Vector2 center, double radius) =>
      _monsters
          .where((m) => !m.isDead && m.position.distanceTo(center) <= radius)
          .toList();

  MonsterComponent? _nearestInCone(double range, double halfDeg) {
    MonsterComponent? best;
    var bd = double.infinity;
    for (final m in _coneMonsters(range, halfDeg)) {
      final d = m.position.distanceTo(player.position);
      if (d < bd) {
        bd = d;
        best = m;
      }
    }
    return best;
  }

  void _skillHit(MonsterComponent m, double mult, Color color) {
    if (m.isDead) return;
    final res = resolveDamage(profile.total, m.stats, _rng);
    final dmg = (res.amount * mult).round();
    _spawnDamageText(
      m.position.clone()..y -= m.size.y / 2,
      dmg,
      res.crit ? _dmgCrit : color,
      crit: res.crit,
    );
    if (_authoritative && m.networked) {
      mp!.sendMonsterHit(m.netId!, dmg); // 서버가 권위적으로 적용·사망 판정.
    } else {
      m.takeDamage(dmg, by: _localId);
      if (m.isDead) _onMonsterKilled(m);
    }
  }

  void _executeSkill(SkillId id) {
    AudioService.instance.play('skill', settings.sfxVolume);
    final facing = player.facing;
    final fAngle = atan2(facing.y, facing.x);
    final aim = facing.clone()..normalize();

    void coneSkill(double range, double halfDeg, double mult, Color color) {
      for (final m in _coneMonsters(range, halfDeg)) {
        _skillHit(m, mult, color);
      }
      world.add(
        SkillEffect(
          position: player.position.clone(),
          color: color,
          maxRadius: range,
          kind: BurstKind.arc,
          facingAngle: fAngle,
          arcSpan: halfDeg * pi / 180,
        ),
      );
    }

    void radiusSkill(double radius, double mult, Color color, BurstKind kind) {
      for (final m in _radiusMonsters(player.position, radius)) {
        _skillHit(m, mult, color);
      }
      world.add(
        SkillEffect(
          position: player.position.clone(),
          color: color,
          maxRadius: radius,
          kind: kind,
        ),
      );
    }

    void bombAt(
      Vector2 target,
      double radius,
      double mult,
      Color color, {
      required bool magic,
    }) {
      world.add(
        ProjectileComponent(
          start: player.position.clone(),
          target: target,
          color: color,
          magic: magic,
        ),
      );
      for (final m in _radiusMonsters(target, radius)) {
        _skillHit(m, mult, color);
      }
      world.add(
        SkillEffect(
          position: target.clone(),
          color: color,
          maxRadius: radius,
          kind: BurstKind.explosion,
        ),
      );
    }

    switch (id) {
      case SkillId.basicSlash:
        coneSkill(120, 60, 1.5, const Color(0xFFFFFFFF));
        break;
      case SkillId.swordSwing:
        coneSkill(150, 90, 1.8, const Color(0xFFB3E5FC));
        break;
      case SkillId.swordWhirl:
        radiusSkill(135, 1.5, const Color(0xFF81D4FA), BurstKind.ring);
        break;
      case SkillId.spearThrust:
        coneSkill(280, 14, 2.2, const Color(0xFFFFE082));
        break;
      case SkillId.spearSweep:
        coneSkill(180, 70, 1.5, const Color(0xFFFFD54F));
        break;
      case SkillId.bowDouble:
        final targets = _coneMonsters(360, 30)
          ..sort(
            (a, b) => a.position
                .distanceTo(player.position)
                .compareTo(b.position.distanceTo(player.position)),
          );
        const c = Color(0xFFFFF59D);
        for (var i = 0; i < 2; i++) {
          final t = i < targets.length ? targets[i] : null;
          final tp = t?.position.clone() ?? player.position + aim * 360;
          world.add(
            ProjectileComponent(
              start: player.position.clone(),
              target: tp,
              color: c,
            ),
          );
          if (t != null) _skillHit(t, 1.3, c);
        }
        break;
      case SkillId.bowBomb:
        final t = _nearestInCone(360, 30);
        bombAt(
          t?.position.clone() ?? player.position + aim * 320,
          110,
          2.2,
          const Color(0xFFFFA726),
          magic: false,
        );
        break;
      case SkillId.axeSmash:
        coneSkill(125, 90, 2.6, const Color(0xFFFF8A65));
        break;
      case SkillId.axeWhirl:
        radiusSkill(155, 1.7, const Color(0xFFFFAB91), BurstKind.ring);
        break;
      case SkillId.staffFireball:
        final t = _nearestInCone(360, 24);
        bombAt(
          t?.position.clone() ?? player.position + aim * 320,
          95,
          2.2,
          const Color(0xFFB388FF),
          magic: true,
        );
        break;
      case SkillId.staffNova:
        radiusSkill(200, 1.9, const Color(0xFFB388FF), BurstKind.explosion);
        break;
    }
  }

  void _spawnDamageText(
    Vector2 at,
    int amount,
    Color color, {
    bool crit = false,
    String? label,
  }) {
    if (!settings.showDamageNumbers) return;
    world.add(
      DamageText(
        text: label ?? (crit ? '$amount!' : '$amount'),
        color: color,
        position: at,
        fontSize: crit ? 22 : 16,
      ),
    );
  }

  void _playerAttackMonster(MonsterComponent m) {
    if (m.isDead) return;
    final res = resolveDamage(profile.total, m.stats, _rng);
    world.add(
      AttackEffect(
        position: m.position.clone(),
        color: res.crit ? _dmgCrit : _dmgToMonster,
      ),
    );
    _spawnDamageText(
      m.position.clone()..y -= m.size.y / 2,
      res.amount,
      res.crit ? _dmgCrit : _dmgToMonster,
      crit: res.crit,
    );
    if (_authoritative && m.networked) {
      mp!.sendMonsterHit(m.netId!, res.amount); // 서버 권위 적용.
    } else {
      m.takeDamage(res.amount, by: _localId);
      if (m.isDead) _onMonsterKilled(m);
    }
  }

  void monsterAttackPlayer(MonsterComponent m) {
    if (profile.isDead || m.isDead) return;
    if (inTown || player.invuln > 0) return; // 안전지대/무적 중엔 피해 없음
    final res = resolveDamage(m.stats, profile.total, _rng);
    profile.damage(res.amount);
    player.invuln = 1.0; // 피격 후 1초 무적
    _spawnDamageText(
      player.position.clone()..y -= player.size.y / 2,
      res.amount,
      _dmgToPlayer,
      crit: res.crit,
    );
    if (profile.isDead) {
      profile.revive();
      teleportToTown(); // 사망 시 마을로 부활
      onLog('쓰러졌습니다 — 마을에서 부활합니다', logDanger);
    }
  }

  bool _reporting = false;

  Future<void> _onMonsterKilled(MonsterComponent m) async {
    _monsters.remove(m);
    m.removeFromParent();
    AudioService.instance.play('monster', settings.sfxVolume);

    final loot = LootSystem.roll(
      templateId: m.data.templateId,
      elite: m.elite,
      playerLevel: profile.level,
      rng: _rng,
    );
    // 지분제(기여도) 보상: 내 데미지 비중만큼 골드/경험치/루팅 자격을 산정한다.
    // (솔로/클라 권위에서는 단일 기여자이므로 전액. 서버 권위 공유몹이면 유저별 독립 분배.)
    final share = m.ledger.shareFor(_localId, baseGold: loot.gold, baseExp: loot.exp);

    final prevLevel = profile.level;
    profile.addGold(share.gold);
    final gainedExp = (share.exp * selfExpMultiplier()).round();
    profile.gainExp(gainedExp);
    onKillExp(share.exp); // 파티원 경험치 분배(누적)

    // 종류별 색 구분 토스트 로그(밑에서 위로 쌓임).
    if (m.elite) onLog('★ 엘리트 처치!', logReward);
    onLog('+${share.gold} G', logReward);
    onLog('+$gainedExp EXP', logExp);
    if (share.lootEligible) {
      for (final BagItem g in loot.items) {
        // 아이템은 희귀도 색으로 표시.
        if (profile.addItem(g)) onLog('획득: ${g.name}', Color(g.rarity.colorValue));
      }
    }
    if (profile.level > prevLevel) {
      onLog('레벨업! Lv.${profile.level}', logLevel);
      AudioService.instance.play('level', settings.sfxVolume);
    }

    // 온라인 + 원본 인스턴스 몬스터만 서버 경제 로그 기록.
    if (online && m.data.idx < _syntheticIdxBase && !_reporting) {
      _reporting = true;
      try {
        final DropResult drop = await net.reportKill(
          instance.runSeed,
          m.data.idx,
        );
        if (drop.hasDrop) {
          onLog('서버 드랍 기록: ${drop.templateId} x${drop.quantity}', logInfo);
        }
      } catch (_) {
        // 경제 로그 실패는 게임플레이에 영향 없음.
      } finally {
        _reporting = false;
      }
    }
  }

  @override
  void onRemove() {
    playerPos.dispose();
    skillTick.dispose();
    super.onRemove();
  }
}
