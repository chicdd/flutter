// 2D 인스턴스 RPG — 클라이언트 진입점 (§9).
// 권위 불변식(§3): 클라이언트는 경제를 표시/입력만 한다. 모든 경제 변경은 서버 RPC 경유.
import 'package:flutter/material.dart';

import 'ui/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RpgApp());
}
