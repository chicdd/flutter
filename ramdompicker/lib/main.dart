import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:io';
import 'dart:math';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:reorderables/reorderables.dart';
import 'database/database_helper.dart';
import 'package:desktop_window/desktop_window.dart';
import 'models/member.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DesktopWindow.setWindowSize(Size(400, 600)); // 가로 사이즈, 세로 사이즈 기본 사이즈 부여
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const TeamPickerScreen(),
    );
  }
}

class TeamPickerScreen extends StatefulWidget {
  const TeamPickerScreen({super.key});

  @override
  State<TeamPickerScreen> createState() => _TeamPickerScreenState();
}

class _TeamPickerScreenState extends State<TeamPickerScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TextEditingController _nameController = TextEditingController();

  List<Member> _allMembers = [];
  final Set<int> _selectedMemberIds = {};
  List<Member> _team1 = [];
  List<Member> _team2 = [];
  bool _hasDrawn = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    final members = await _dbHelper.getAllMembers();
    setState(() {
      _allMembers = members;
    });
  }

  Future<void> _addMember() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이름을 입력해주세요')));
      return;
    }

    final newMember = Member(name: _nameController.text.trim());
    await _dbHelper.insertMember(newMember);
    _nameController.clear();
    await _loadMembers();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('멤버가 추가되었습니다')));
    }
  }

  void _toggleMemberSelection(int memberId) {
    if (_hasDrawn) return;

    setState(() {
      if (_selectedMemberIds.contains(memberId)) {
        _selectedMemberIds.remove(memberId);
      } else {
        _selectedMemberIds.add(memberId);
      }
    });
  }

  Future<void> _showEditDeleteDialog(Member member) async {
    final editController = TextEditingController(text: member.name);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('멤버 수정/삭제'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editController,
              decoration: const InputDecoration(
                labelText: '이름',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (editController.text.trim().isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('이름을 입력해주세요')));
                return;
              }

              final updatedMember = member.copyWith(
                name: editController.text.trim(),
              );
              await _dbHelper.updateMember(updatedMember);
              await _loadMembers();

              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('멤버가 수정되었습니다')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('변경'),
          ),
          ElevatedButton(
            onPressed: () async {
              final confirmDelete = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('삭제 확인'),
                  content: Text('${member.name}님을 삭제하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('삭제'),
                    ),
                  ],
                ),
              );

              if (confirmDelete == true && member.id != null) {
                await _dbHelper.deleteMember(member.id!);
                _selectedMemberIds.remove(member.id);
                await _loadMembers();

                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${member.name}님이 삭제되었습니다')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    editController.dispose();
  }

  void _drawTeams() {
    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('멤버를 선택해주세요')));
      return;
    }

    if (_selectedMemberIds.length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('최소 2명 이상 선택해주세요')));
      return;
    }

    final selectedMembers = _allMembers
        .where((member) => _selectedMemberIds.contains(member.id))
        .toList();

    final shuffled = List<Member>.from(selectedMembers)..shuffle(Random());
    final midPoint = (shuffled.length / 2).ceil();

    setState(() {
      _team1 = shuffled.sublist(0, midPoint);
      _team2 = shuffled.sublist(midPoint);
      _hasDrawn = true;
    });
  }

  void _reset() {
    setState(() {
      _team1 = [];
      _team2 = [];
      _hasDrawn = false;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedMemberIds.clear();
      _team1 = [];
      _team2 = [];
      _hasDrawn = false;
    });
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      final member = _allMembers.removeAt(oldIndex);
      _allMembers.insert(newIndex, member);
    });

    await _dbHelper.updateMembersOrder(_allMembers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '멤버 이름',
                      border: OutlineInputBorder(),
                      hintText: '이름을 입력하세요',
                    ),
                    onSubmitted: (_) => _addMember(),
                  ),
                ),
                const SizedBox(width: 8),

                ElevatedButton(
                  onPressed: _addMember,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 30,
                    ),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('추가', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              '멤버 선택',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _allMembers.isEmpty
                  ? const Center(child: Text('멤버를 추가해주세요'))
                  : SingleChildScrollView(
                      child: ReorderableWrap(
                        spacing: 8,
                        runSpacing: 8,
                        onReorder: _onReorder,
                        children: _allMembers.map((member) {
                          final isSelected = _selectedMemberIds.contains(
                            member.id,
                          );
                          return Listener(
                            key: ValueKey(member.id),
                            onPointerDown: (PointerDownEvent event) {
                              if (event.kind == PointerDeviceKind.mouse &&
                                  event.buttons == kSecondaryMouseButton) {
                                _showEditDeleteDialog(member);
                              }
                            },
                            child: FilterChip(
                              label: Text(member.name),
                              selected: isSelected,
                              onSelected: _hasDrawn
                                  ? null
                                  : (_) {
                                      _toggleMemberSelection(member.id!);
                                    },
                              selectedColor: Colors.blue.shade300,
                              checkmarkColor: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            if (_hasDrawn) ...[
              const Text(
                '추첨 결과',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '1팀 (${_team1.length}명)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._team1.map(
                            (member) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text('• ${member.name}'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '2팀 (${_team2.length}명)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._team2.map(
                            (member) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text('• ${member.name}'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _hasDrawn ? null : _drawTeams,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('추첨', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: !_hasDrawn ? null : _reset,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('다시하기', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clearSelection,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('초기화', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
