// 전역 채팅 패널 — 접속한 모든 유저와 함께 대화(Nakama 채널).
import 'package:flutter/material.dart';

import '../net/multiplayer.dart';

class ChatPanel extends StatefulWidget {
  final MultiplayerService? mp;
  final VoidCallback onClose;

  const ChatPanel({super.key, required this.mp, required this.onClose});

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    widget.mp?.sendChat(t);
    _ctrl.clear();
    // 전송 후 잠시 뒤 스크롤(에코 메시지 수신 반영).
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  void _scrollToEnd() {
    if (_scroll.hasClients) {
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mp = widget.mp;
    return Container(
      width: 340,
      height: 320,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          // 헤더.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 6, 4),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble, color: Color(0xFF80CBC4), size: 18),
                const SizedBox(width: 8),
                const Text('전체 채팅', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (mp != null && !mp.chatReady)
                  const Text('연결 중…', style: TextStyle(color: Colors.white38, fontSize: 11)),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          // 메시지 목록.
          Expanded(
            child: mp == null
                ? const Center(child: Text('오프라인 — 채팅 불가', style: TextStyle(color: Colors.white38)))
                : ValueListenableBuilder<int>(
                    valueListenable: mp.chatVersion,
                    builder: (context, _, _) {
                      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
                      final log = mp.chatLog;
                      if (log.isEmpty) {
                        return const Center(
                            child: Text('아직 메시지가 없습니다.', style: TextStyle(color: Colors.white38)));
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
          // 입력.
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    enabled: mp != null,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: '메시지 입력…',
                      hintStyle: TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Color(0x33FFFFFF),
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF80CBC4)),
                  onPressed: mp == null ? null : _send,
                ),
              ],
            ),
          ),
        ],
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
                  color: l.mine ? const Color(0xFFFFD54F) : const Color(0xFF90CAF9),
                  fontWeight: FontWeight.bold),
            ),
            TextSpan(text: l.text, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
