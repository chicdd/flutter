// 떠오르는 토스트 로그 — 우측 하단, 배경 없는 글자. 밑에서 쌓여 위로 5초 뒤 사라진다.
// 골드/아이템(희귀도)/레벨업 등 종류별 색은 호출부(RpgGame)가 정해 전달한다.
import 'dart:async';

import 'package:flutter/material.dart';

class GameLogEntry {
  final String text;
  final Color color;
  final DateTime born;
  GameLogEntry(this.text, this.color) : born = DateTime.now();
}

class GameLogController extends ChangeNotifier {
  final List<GameLogEntry> entries = [];

  void add(String text, Color color) {
    if (text.trim().isEmpty) return;
    entries.add(GameLogEntry(text, color));
    if (entries.length > 40) entries.removeAt(0);
    notifyListeners();
  }
}

class GameLogView extends StatefulWidget {
  final GameLogController controller;
  const GameLogView({super.key, required this.controller});

  @override
  State<GameLogView> createState() => _GameLogViewState();
}

class _GameLogViewState extends State<GameLogView> {
  static const Duration _lifetime = Duration(seconds: 5);
  static const int _fadeMs = 700;
  static const int _maxShown = 9;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      // 수명이 지난 항목 제거(위에서부터 사라짐).
      widget.controller.entries.removeWhere(
        (e) => DateTime.now().difference(e.born) > _lifetime,
      );
      setState(() {});
    });
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final all = widget.controller.entries;
    // 최근 N개만(오래된 것=위, 최신=아래).
    final shown = all.length > _maxShown ? all.sublist(all.length - _maxShown) : all;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final e in shown) _line(e, now),
      ],
    );
  }

  Widget _line(GameLogEntry e, DateTime now) {
    final ageMs = now.difference(e.born).inMilliseconds;
    final lifeMs = _lifetime.inMilliseconds;
    double opacity = 1.0;
    if (ageMs > lifeMs - _fadeMs) {
      opacity = ((lifeMs - ageMs) / _fadeMs).clamp(0.0, 1.0);
    } else if (ageMs < 150) {
      opacity = (ageMs / 150).clamp(0.0, 1.0);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Opacity(
        opacity: opacity,
        child: Text(
          e.text,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: e.color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            shadows: const [
              Shadow(color: Color(0xCC000000), blurRadius: 3),
              Shadow(color: Color(0x99000000), blurRadius: 6),
            ],
          ),
        ),
      ),
    );
  }
}
