// 효과음 서비스 — flame_audio 래퍼. 무기/전투/UI 사운드(귀여운 컨셉).
// 볼륨은 GameSettings.sfxVolume 를 호출부에서 전달한다(0 이면 재생 안 함).
import 'package:flame_audio/flame_audio.dart';

import '../models/gear.dart';

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  static const List<String> _all = [
    'sword', 'spear', 'bow', 'axe', 'staff',
    'hit', 'monster', 'skill', 'level', 'coin', 'potion',
  ];

  bool _ready = false;

  Future<void> preload() async {
    if (_ready) return;
    _ready = true;
    try {
      await FlameAudio.audioCache.loadAll(_all.map((s) => '$s.wav').toList());
    } catch (_) {
      _ready = false; // 실패해도 게임은 진행
    }
  }

  void play(String name, double volume) {
    if (volume <= 0) return;
    try {
      FlameAudio.play('$name.wav', volume: volume.clamp(0.0, 1.0));
    } catch (_) {/* 무시 */}
  }

  void weaponAttack(WeaponType? t, double volume) {
    final name = switch (t) {
      WeaponType.sword => 'sword',
      WeaponType.spear => 'spear',
      WeaponType.bow => 'bow',
      WeaponType.axe => 'axe',
      WeaponType.staff => 'staff',
      null => 'sword',
    };
    play(name, volume);
  }
}
