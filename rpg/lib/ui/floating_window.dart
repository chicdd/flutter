// 플로팅 윈도우 — 드래그 이동 + 전체화면 토글. 배경을 어둡게 가리지 않는(비차단) 반투명 창.
// 게임플레이를 막지 않도록 화면 전체 배리어 없이 떠 있는다.
import 'package:flutter/material.dart';

class FloatingWindow extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback onClose;
  final VoidCallback? onFocus; // 드래그/탭 시 맨 앞으로
  final Offset initialOffset;
  final Size initialSize;

  const FloatingWindow({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    required this.onClose,
    this.onFocus,
    this.initialOffset = const Offset(80, 80),
    this.initialSize = const Size(360, 470),
  });

  @override
  State<FloatingWindow> createState() => _FloatingWindowState();
}

class _FloatingWindowState extends State<FloatingWindow> {
  late Offset _pos = widget.initialOffset;
  bool _full = false;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    if (_full) {
      return Positioned(left: 10, top: 10, right: 10, bottom: 10, child: _frame(context));
    }
    final w = widget.initialSize.width;
    final h = widget.initialSize.height;
    final left = _pos.dx.clamp(0.0, (screen.width - 80).clamp(0.0, double.infinity));
    final top = _pos.dy.clamp(0.0, (screen.height - 60).clamp(0.0, double.infinity));
    return Positioned(
      left: left,
      top: top,
      child: SizedBox(width: w, height: h.clamp(0.0, screen.height - top), child: _frame(context)),
    );
  }

  Widget _frame(BuildContext context) {
    return Listener(
      onPointerDown: (_) => widget.onFocus?.call(),
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          decoration: BoxDecoration(
            // 비차단 반투명 — 게임이 비쳐 보인다.
            color: const Color(0xB31C232C),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24, width: 1.2),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 14, offset: Offset(0, 6))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _titleBar(),
              Expanded(child: widget.child),
            ],
          ),
        ),
      ),
    );
  }

  Widget _titleBar() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => widget.onFocus?.call(),
      onPanUpdate: _full ? null : (d) => setState(() => _pos += d.delta),
      child: Container(
        height: 38,
        padding: const EdgeInsets.only(left: 12, right: 4),
        decoration: const BoxDecoration(
          color: Color(0x33FFFFFF),
          border: Border(bottom: BorderSide(color: Colors.white24)),
        ),
        child: Row(
          children: [
            Icon(widget.icon, size: 16, color: Colors.white70),
            const SizedBox(width: 8),
            Expanded(
              child: Text(widget.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: _full ? '창 모드' : '전체화면',
              icon: Icon(_full ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white70, size: 18),
              onPressed: () => setState(() => _full = !_full),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: '닫기',
              icon: const Icon(Icons.close, color: Colors.white70, size: 18),
              onPressed: widget.onClose,
            ),
          ],
        ),
      ),
    );
  }
}
