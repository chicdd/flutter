// 오프라인 폴백용 몬스터 생성 — 서버 src/util/instanceGen.ts 와 동일 로직.
// 서버 미연결 시 Phase 0(맵+이동)을 즉시 체험할 수 있게 한다.
// 주의(§3): 오프라인 인스턴스에서는 드랍이 발생하지 않는다(아이템 mint 는 서버 권위).
import '../../models/instance.dart';

class _Mulberry32 {
  int _a;
  _Mulberry32(int seed) : _a = seed & 0xFFFFFFFF;

  double next() {
    _a = (_a + 0x6D2B79F5) & 0xFFFFFFFF;
    int t = _a;
    t = (_imul(t ^ (t >>> 15), 1 | t)) & 0xFFFFFFFF;
    t = (t + (_imul(t ^ (t >>> 7), 61 | t)) & 0xFFFFFFFF) ^ t;
    return ((t ^ (t >>> 14)) & 0xFFFFFFFF) / 4294967296.0;
  }

  static int _imul(int a, int b) {
    // 32비트 곱셈 모사 (Math.imul).
    final aHi = (a >>> 16) & 0xFFFF;
    final aLo = a & 0xFFFF;
    final bHi = (b >>> 16) & 0xFFFF;
    final bLo = b & 0xFFFF;
    return (aLo * bLo + (((aHi * bLo + aLo * bHi) << 16) & 0xFFFFFFFF)) & 0xFFFFFFFF;
  }
}

class _PoolEntry {
  final String templateId;
  final int hp;
  final int weight;
  const _PoolEntry(this.templateId, this.hp, this.weight);
}

const List<_PoolEntry> _pool = [
  _PoolEntry('slime', 30, 50),
  _PoolEntry('goblin', 60, 35),
  _PoolEntry('skeleton', 90, 15),
];

const double worldW = 2000;
const double worldH = 2000;

int _fold32(int seed) {
  final lo = seed & 0xFFFFFFFF;
  final hi = (seed >>> 32) & 0xFFFFFFFF;
  return (lo ^ hi) & 0xFFFFFFFF;
}

List<InstanceMonster> generateMonstersOffline(int seed, {int count = 12}) {
  final rng = _Mulberry32(_fold32(seed));
  final out = <InstanceMonster>[];
  int total = 0;
  for (final p in _pool) {
    total += p.weight;
  }
  for (var i = 0; i < count; i++) {
    final r = rng.next();
    var acc = r * total;
    _PoolEntry pick = _pool.first;
    for (final p in _pool) {
      acc -= p.weight;
      if (acc <= 0) {
        pick = p;
        break;
      }
    }
    out.add(InstanceMonster(
      idx: i,
      templateId: pick.templateId,
      x: (rng.next() * worldW),
      y: (rng.next() * worldH),
      hp: pick.hp,
    ));
  }
  return out;
}
