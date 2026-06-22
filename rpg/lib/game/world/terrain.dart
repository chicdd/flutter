// 오픈월드 무한 지형 — 카메라 가시영역의 타일만 매 프레임 결정론적으로 그린다.
// 좌표(타일 col,row)별 노이즈로 색을 계산하므로 맵 경계 없이 무한히 생성된다(저장 불필요).
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';
import 'package:fast_noise/fast_noise.dart';

class TerrainComponent extends Component with HasGameReference<FlameGame> {
  final int seed;
  final double tileSize;

  late final PerlinNoise _noise;
  late final PerlinNoise _detail;

  TerrainComponent({required this.seed, this.tileSize = 22}) {
    priority = -10; // 항상 배경
  }

  @override
  Future<void> onLoad() async {
    // 타일이 작아진 만큼 주파수를 키워 촘촘한 도트 느낌을 유지.
    _noise = PerlinNoise(seed: seed & 0x7FFFFFFF, frequency: 0.06);
    _detail = PerlinNoise(seed: (seed ^ 0x5DEECE66) & 0x7FFFFFFF, frequency: 0.22);
  }

  Color _biomeColor(double n, double d) {
    Color base;
    if (n < -0.32) {
      base = const Color(0xFF1B4D6B); // 물
    } else if (n < -0.08) {
      base = const Color(0xFFC2B280); // 모래
    } else if (n < 0.42) {
      base = const Color(0xFF356B35); // 풀
    } else {
      base = const Color(0xFF5A6B5A); // 바위
    }
    // 디테일 노이즈로 미세 음영(타일 경계감 완화).
    final shade = (d * 14).clamp(-14.0, 14.0).toInt();
    return Color.fromARGB(
      255,
      (base.r * 255 + shade).clamp(0, 255).toInt(),
      (base.g * 255 + shade).clamp(0, 255).toInt(),
      (base.b * 255 + shade).clamp(0, 255).toInt(),
    );
  }

  @override
  void render(Canvas canvas) {
    final rect = game.camera.visibleWorldRect;
    final c0 = (rect.left / tileSize).floor() - 1;
    final c1 = (rect.right / tileSize).ceil() + 1;
    final r0 = (rect.top / tileSize).floor() - 1;
    final r1 = (rect.bottom / tileSize).ceil() + 1;

    final paint = Paint();
    for (var r = r0; r <= r1; r++) {
      for (var c = c0; c <= c1; c++) {
        final n = _noise.getNoise2(c.toDouble(), r.toDouble());
        final d = _detail.getNoise2(c.toDouble(), r.toDouble());
        paint.color = _biomeColor(n, d);
        canvas.drawRect(
          Rect.fromLTWH(c * tileSize, r * tileSize, tileSize + 0.5, tileSize + 0.5),
          paint,
        );
      }
    }
  }
}
