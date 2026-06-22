// 게임 일반 설정 (ChangeNotifier + SharedPreferences 영속).
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameSettings extends ChangeNotifier {
  bool showDamageNumbers = true;
  bool cameraShake = true; // 예약(연출)
  double sfxVolume = 0.7;
  double bgmVolume = 0.5;

  static const _kDmg = 'set_show_damage';
  static const _kShake = 'set_camera_shake';
  static const _kSfx = 'set_sfx';
  static const _kBgm = 'set_bgm';

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    showDamageNumbers = sp.getBool(_kDmg) ?? true;
    cameraShake = sp.getBool(_kShake) ?? true;
    sfxVolume = sp.getDouble(_kSfx) ?? 0.7;
    bgmVolume = sp.getDouble(_kBgm) ?? 0.5;
    notifyListeners();
  }

  Future<void> _sp(void Function(SharedPreferences) f) async {
    final sp = await SharedPreferences.getInstance();
    f(sp);
    notifyListeners();
  }

  void setShowDamageNumbers(bool v) {
    showDamageNumbers = v;
    _sp((sp) => sp.setBool(_kDmg, v));
  }

  void setCameraShake(bool v) {
    cameraShake = v;
    _sp((sp) => sp.setBool(_kShake, v));
  }

  void setSfxVolume(double v) {
    sfxVolume = v;
    _sp((sp) => sp.setDouble(_kSfx, v));
  }

  void setBgmVolume(double v) {
    bgmVolume = v;
    _sp((sp) => sp.setDouble(_kBgm, v));
  }
}
