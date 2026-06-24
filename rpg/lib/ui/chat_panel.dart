// 채팅창 — 전체/파티/친구 대화유형 전환(Tab 또는 드롭다운). 전체채팅은 접속한 모든 유저에게 전달.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../net/multiplayer.dart';

class ChatPanel extends StatefulWidget {
  final MultiplayerService? mp;
  final VoidCallback onClose;
  // 전송 라우팅(전체=openworld, 파티/친구=인박스). GameScreen 이 수신자 목록을 안다.
  final void Function(ChatScope scope, String text)? onSend;

  const ChatPanel({super.key, required this.mp, required this.onClose, this.onSend});

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  ChatScope _scope = ChatScope.all;

  static String _label(ChatScope s) => switch (s) {
        ChatScope.all => '전체채팅',
        ChatScope.party => '파티채팅',
        ChatScope.friend => '친구채팅',
      };
  static Color _color(ChatScope s) => switch (s) {
        ChatScope.all => const Color(0xFF80CBC4),
        ChatScope.party => const Color(0xFFBA68C8),
        ChatScope.friend => const Color(0xFF64B5F6),
      };

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _cycleScope() {
    setState(() {
      _scope = ChatScope.values[(_scope.index + 1) % ChatScope.values.length];
    });
  }

  void _send() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    widget.onSend?.call(_scope, t);
    _ctrl.clear();
    _focus.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  void _scrollToEnd() {
    if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    final mp = widget.mp;
    // Tab 키로 대화유형 전환.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.tab): _cycleScope,
      },
      child: Container(
        width: 340,
        height: 330,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          children: [
            // 헤더: 채팅창.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 6, 4),
              child: Row(children: [
                const Icon(Icons.forum, color: Color(0xFF80CBC4), size: 18),
                const SizedBox(width: 8),
                const Text('채팅창', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (mp != null && !mp.chatReady)
                  const Text('연결 중…', style: TextStyle(color: Colors.white38, fontSize: 11)),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                  onPressed: widget.onClose,
                ),
              ]),
            ),
            const Divider(height: 1, color: Colors.white12),
            // 메시지(선택한 대화유형만).
            Expanded(
              child: mp == null
                  ? const Center(child: Text('오프라인 — 채팅 불가', style: TextStyle(color: Colors.white38)))
                  : ValueListenableBuilder<int>(
                      valueListenable: mp.chatVersion,
                      builder: (context, _, _) {
                        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
                        final log = mp.chatLog.where((l) => l.scope == _scope).toList();
                        if (log.isEmpty) {
                          return Center(
                              child: Text('${_label(_scope)} 메시지가 없습니다.',
                                  style: const TextStyle(color: Colors.white38)));
                        }
                        return ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          itemCount: log.length,
                          itemBuilder: (context, i) => _line(log[i]),
                        );
                      },
                    ),
            ),
            // 대화유형 + 채팅바.
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  _scopeSelector(),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      enabled: mp != null,
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: '메시지 입력… (Tab=유형전환)',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                        filled: true,
                        fillColor: Color(0x33FFFFFF),
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: _color(_scope)),
                    onPressed: mp == null ? null : _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 대화유형 드롭다운(전체/파티/친구).
  Widget _scopeSelector() {
    return PopupMenuButton<ChatScope>(
      tooltip: '대화유형',
      initialValue: _scope,
      onSelected: (s) => setState(() => _scope = s),
      itemBuilder: (context) => [
        for (final s in ChatScope.values)
          PopupMenuItem(value: s, child: Text(_label(s))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color: _color(_scope).withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _color(_scope).withValues(alpha: 0.6)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(_label(_scope), style: TextStyle(color: _color(_scope), fontWeight: FontWeight.bold, fontSize: 12)),
          Icon(Icons.arrow_drop_down, color: _color(_scope), size: 18),
        ]),
      ),
    );
  }

  Widget _line(ChatLine l) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13),
          children: [
            TextSpan(
              text: '${l.name}${l.level > 0 ? ' (Lv.${l.level})' : ''}: ',
              style: TextStyle(
                  color: l.mine ? const Color(0xFFFFD54F) : _color(l.scope), fontWeight: FontWeight.bold),
            ),
            TextSpan(text: l.text, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
