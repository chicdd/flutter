import 'package:flutter/material.dart';

/// AutomaticKeepAliveClientMixin을 사용하여 탭 전환 시 상태를 유지하는 위젯
class KeptAliveWidget extends StatefulWidget {
  final Widget child;

  const KeptAliveWidget({
    super.key,
    required this.child,
  });

  @override
  State<KeptAliveWidget> createState() => _KeptAliveWidgetState();
}

class _KeptAliveWidgetState extends State<KeptAliveWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // 반드시 호출해야 함
    return widget.child;
  }
}
