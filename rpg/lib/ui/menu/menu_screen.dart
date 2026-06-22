// 메뉴 — 친구 / 레벨 랭킹 / 파티(경험치 공유) / 설정.
import 'package:flutter/material.dart';

import '../../models/account.dart';
import '../../net/social_service.dart';
import '../../state/player_profile.dart';
import '../../state/settings.dart';

class MenuScreen extends StatefulWidget {
  final Account account;
  final PlayerProfile profile;
  final SocialService social;
  final GameSettings settings;
  final void Function(String nickname)? onFollow;
  final int initialTab;

  const MenuScreen({
    super.key,
    required this.account,
    required this.profile,
    required this.social,
    required this.settings,
    this.onFollow,
    this.initialTab = 0,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  SocialService get social => widget.social;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      initialIndex: widget.initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('메뉴'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.group), text: '친구'),
              Tab(icon: Icon(Icons.leaderboard), text: '랭킹'),
              Tab(icon: Icon(Icons.diversity_3), text: '파티'),
              Tab(icon: Icon(Icons.settings), text: '설정'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _FriendsTab(social: social, onFollow: widget.onFollow),
            _RankingTab(social: social),
            _PartyTab(social: social),
            _SettingsTab(settings: widget.settings),
          ],
        ),
      ),
    );
  }
}

// ── 친구 ──
class _FriendsTab extends StatefulWidget {
  final SocialService social;
  final void Function(String nickname)? onFollow;
  const _FriendsTab({required this.social, this.onFollow});

  @override
  State<_FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<_FriendsTab> {
  final _idCtrl = TextEditingController();
  late Future<List<FriendInfo>> _future;
  List<FriendInfo> _results = [];
  bool _searched = false;
  String? _msg;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  void _reload() {
    final f = widget.social.friends();
    setState(() {
      _future = f;
    });
  }

  Future<void> _search() async {
    final r = await widget.social.searchAccounts(_idCtrl.text);
    if (!mounted) return;
    setState(() {
      _results = r;
      _searched = true;
      _msg = null;
    });
  }

  Future<void> _addById(String id) async {
    final err = await widget.social.addFriend(id);
    if (!mounted) return;
    setState(() {
      _msg = err ?? '친구를 추가했습니다.';
      if (err == null) {
        _idCtrl.clear();
        _results = [];
        _searched = false;
      }
    });
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _idCtrl,
                  onSubmitted: (_) => _search(),
                  decoration: const InputDecoration(
                    labelText: '닉네임 또는 ID 검색',
                    isDense: true,
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _search, child: const Text('검색')),
              const SizedBox(width: 6),
              OutlinedButton(onPressed: () => _addById(_idCtrl.text), child: const Text('추가')),
            ],
          ),
        ),
        if (_msg != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(alignment: Alignment.centerLeft, child: Text(_msg!, style: const TextStyle(color: Colors.white60))),
          ),
        if (_searched)
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: const Color(0xFF222222), borderRadius: BorderRadius.circular(8)),
            child: _results.isEmpty
                ? const Padding(padding: EdgeInsets.all(12), child: Text('검색 결과가 없습니다.', style: TextStyle(color: Colors.white54)))
                : ListView(
                    shrinkWrap: true,
                    children: _results
                        .map((r) => ListTile(
                              dense: true,
                              leading: CircleAvatar(radius: 14, child: Text(r.levelKnown ? '${r.level}' : '?', style: const TextStyle(fontSize: 11))),
                              title: Text(r.nickname),
                              subtitle: Text('ID: ${r.id} · Lv.${r.levelKnown ? r.level : '?'}'),
                              trailing: FilledButton(onPressed: () => _addById(r.id), child: const Text('추가')),
                            ))
                        .toList(),
                  ),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Align(alignment: Alignment.centerLeft, child: Text('내 친구', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold))),
        ),
        Expanded(
          child: FutureBuilder<List<FriendInfo>>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final list = snap.data!;
              if (list.isEmpty) return const Center(child: Text('아직 친구가 없습니다.'));
              return ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final f = list[i];
                  return ListTile(
                    leading: CircleAvatar(child: Text(f.levelKnown ? '${f.level}' : '?')),
                    title: Text(f.nickname),
                    subtitle: Text('ID: ${f.id} · Lv.${f.levelKnown ? f.level : '?'}${f.inParty ? ' · 파티중' : ''}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.onFollow != null)
                          IconButton(
                            tooltip: '따라가기',
                            icon: const Icon(Icons.my_location, color: Color(0xFF64B5F6)),
                            onPressed: () {
                              widget.onFollow!(f.nickname);
                              Navigator.of(context).pop();
                            },
                          ),
                        IconButton(
                          tooltip: '삭제',
                          icon: const Icon(Icons.person_remove, color: Colors.redAccent),
                          onPressed: () async {
                            await widget.social.removeFriend(f.id);
                            _reload();
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── 랭킹 ──
class _RankingTab extends StatefulWidget {
  final SocialService social;
  const _RankingTab({required this.social});

  @override
  State<_RankingTab> createState() => _RankingTabState();
}

class _RankingTabState extends State<_RankingTab> {
  late Future<List<RankEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.social.ranking();
  }

  Color _medal(int rank) => switch (rank) {
        1 => const Color(0xFFFFD54F),
        2 => const Color(0xFFB0BEC5),
        3 => const Color(0xFFD7A86E),
        _ => const Color(0xFF455A64),
      };

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RankEntry>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final list = snap.data!;
        if (list.isEmpty) return const Center(child: Text('랭킹 데이터가 없습니다.'));
        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final e = list[i];
            return Container(
              color: e.isMe ? const Color(0x332196F3) : null,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _medal(e.rank),
                  child: Text('${e.rank}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                ),
                title: Text('${e.nickname}${e.isMe ? ' (나)' : ''}',
                    style: TextStyle(fontWeight: e.isMe ? FontWeight.bold : FontWeight.normal)),
                subtitle: Text('ID: ${e.id}'),
                trailing: Text('Lv.${e.level}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
    );
  }
}

// ── 파티 ──
class _PartyTab extends StatefulWidget {
  final SocialService social;
  const _PartyTab({required this.social});

  @override
  State<_PartyTab> createState() => _PartyTabState();
}

class _PartyTabState extends State<_PartyTab> {
  late Future<List<FriendInfo>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final f = widget.social.friends();
    setState(() {
      _future = f;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.social;
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF26323F),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.diversity_3, color: Color(0xFF64B5F6)),
                  const SizedBox(width: 8),
                  Text('파티원 ${s.party.length}명',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '파티 중에는 처치 경험치의 ${(SocialService.shareRate * 100).round()}%가 파티원에게 분배되고, '
                '본인은 경험치 +${(SocialService.selfPartyBonus * 100).round()}% 보너스를 받습니다.',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('친구를 파티에 초대', style: TextStyle(color: Colors.white70)),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<FriendInfo>>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final list = snap.data!;
              if (list.isEmpty) {
                return const Center(child: Text('친구를 먼저 추가하세요.'));
              }
              return ListView(
                children: list.map((f) {
                  final inParty = s.party.contains(f.id);
                  return SwitchListTile(
                    secondary: CircleAvatar(child: Text('${f.level}')),
                    title: Text(f.nickname),
                    subtitle: Text('Lv.${f.level}'),
                    value: inParty,
                    onChanged: (v) {
                      v ? s.addToParty(f.id, f.level) : s.removeFromParty(f.id);
                      _reload();
                    },
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── 설정 ──
class _SettingsTab extends StatelessWidget {
  final GameSettings settings;
  const _SettingsTab({required this.settings});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => ListView(
        children: [
          SwitchListTile(
            title: const Text('데미지 숫자 표시'),
            subtitle: const Text('전투 중 떠오르는 데미지/회복 숫자'),
            value: settings.showDamageNumbers,
            onChanged: settings.setShowDamageNumbers,
          ),
          SwitchListTile(
            title: const Text('화면 흔들림 효과'),
            subtitle: const Text('타격 시 카메라 진동(연출)'),
            value: settings.cameraShake,
            onChanged: settings.setCameraShake,
          ),
          const Divider(),
          ListTile(
            title: const Text('효과음'),
            subtitle: Slider(
              value: settings.sfxVolume,
              onChanged: settings.setSfxVolume,
              label: '${(settings.sfxVolume * 100).round()}%',
              divisions: 10,
            ),
            trailing: Text('${(settings.sfxVolume * 100).round()}%'),
          ),
          ListTile(
            title: const Text('배경음'),
            subtitle: Slider(
              value: settings.bgmVolume,
              onChanged: settings.setBgmVolume,
              label: '${(settings.bgmVolume * 100).round()}%',
              divisions: 10,
            ),
            trailing: Text('${(settings.bgmVolume * 100).round()}%'),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('조작: 이동 WASD/화살표 · 공격 Ctrl · 물약 Q\n모바일: 좌측 조이스틱 · 우측 공격/물약 버튼',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
