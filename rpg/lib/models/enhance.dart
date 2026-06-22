// 장비 강화(+1~+20) 밸런스 + 천장(실패 보정) 시스템 — 단일 출처.
// 규칙 요약:
//  - 성공확률: +1~+5 = 100%, 이후 부드러운 하향 곡선(+6~80%, +20~2%).
//  - 실패결과(실패 시 분배, 합 100%): 유지 / 하락(-1) / 파괴.
//      · +1~+5: 실패 없음.  +6~+9: 유지/하락(파괴 0%).  +10~+20: 유지/하락/파괴.
//      · 체크포인트: +10 도달 후엔 +10 미만으로 떨어지지 않음(하락 바닥=10). +6~+9 구간 바닥=5(안전구간 보존).
//  - 천장(Pity): 같은 단계 실패가 쌓일 때마다 다음 시도 성공확률에 step 만큼 누적.
//      성공하면 스택 0 초기화. step = (100 - 기본성공) / pityMax → pityMax 스택에서 100% 확정.
//  - 능력치: 성공 시 단계별 배수 factor(후반일수록 큼)를 누적 곱해 기본 능력치에 적용(복리 곡선).
import 'dart:math';

class EnhanceSystem {
  static const int maxLevel = 20;

  // index = 목표 단계(1~20). 0 은 더미.
  static const List<double> _base = [
    0, 100, 100, 100, 100, 100, // +1~+5
    80, 70, 62, 53, 45, // +6~+10
    40, 33, 27, 21, 15, // +11~+15
    10, 8, 6, 4, 2, // +16~+20
  ];
  static const List<int> _pityMax = [
    0, 0, 0, 0, 0, 0,
    8, 8, 10, 10, 12,
    15, 16, 18, 20, 22,
    30, 35, 40, 50, 60,
  ];
  // 실패 시 분배(조건부 %, 합 100): 유지 / 하락 / 파괴.
  static const List<int> _failKeep = [
    0, 0, 0, 0, 0, 0,
    80, 70, 60, 50, 99,
    68, 62, 55, 49, 42,
    35, 30, 26, 21, 15,
  ];
  static const List<int> _failDown = [
    0, 0, 0, 0, 0, 0,
    20, 30, 40, 50, 0,
    30, 35, 40, 45, 50,
    55, 58, 60, 62, 65,
  ];
  static const List<int> _failDestroy = [
    0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 1,
    2, 3, 5, 6, 8,
    10, 12, 14, 17, 20,
  ];
  // 단계별 능력치 배수(후반일수록 가파름). index = 단계(1~20), 0=1.0.
  static const List<double> _factor = [
    1.0, 1.04, 1.04, 1.04, 1.04, 1.04,
    1.06, 1.06, 1.06, 1.06, 1.06,
    1.09, 1.09, 1.09, 1.09, 1.09,
    1.13, 1.15, 1.17, 1.19, 1.22,
  ];

  static double baseSuccess(int target) => (target >= 1 && target <= maxLevel) ? _base[target] : 0;
  static int pityMax(int target) => (target >= 1 && target <= maxLevel) ? _pityMax[target] : 0;

  // 실패 1회당 보정 확률(%). pityMax 가 0(=1~5)이면 0.
  static double pityStep(int target) {
    final pm = pityMax(target);
    if (pm <= 0) return 0;
    return (100 - baseSuccess(target)) / pm;
  }

  // 스택 반영 유효 성공확률(%). pityMax 스택에서 100%.
  static double effectiveSuccess(int target, int stack) {
    final v = baseSuccess(target) + stack * pityStep(target);
    return v.clamp(0.0, 100.0);
  }

  static ({int keep, int down, int destroy}) failBranch(int target) {
    if (target < 1 || target > maxLevel) return (keep: 100, down: 0, destroy: 0);
    return (keep: _failKeep[target], down: _failDown[target], destroy: _failDestroy[target]);
  }

  // 하락 시 떨어지지 않는 바닥 단계(체크포인트). 10 이상=10, 그 외=5(안전구간 보존).
  static int downFloor(int currentLevel) => currentLevel >= 10 ? 10 : 5;

  // 단계별 능력치 배수(누적 곱). level 0 → 1.0.
  static double statMult(int level) {
    var m = 1.0;
    for (var k = 1; k <= level && k <= maxLevel; k++) {
      m *= _factor[k];
    }
    return m;
  }

  // 목표 단계 강화 비용(골드).
  static int cost(int target) => 40 + 6 * target * target;

  // 강화 판정(스택 반영). 결과만 반환 — 상태 적용은 호출부.
  static EnhanceResult roll(int target, int stack, Random rng) {
    final succ = effectiveSuccess(target, stack) / 100;
    if (rng.nextDouble() < succ) return EnhanceResult.success;
    final b = failBranch(target);
    final r = rng.nextDouble() * 100;
    if (r < b.destroy) return EnhanceResult.destroy;
    if (r < b.destroy + b.down) return EnhanceResult.downgrade;
    return EnhanceResult.keep;
  }

  // UI 표시용 정보(현재 단계/스택 기준 다음 시도).
  static EnhanceInfo infoFor(int currentLevel, int stack) {
    final target = currentLevel + 1;
    if (target > maxLevel) {
      return const EnhanceInfo(
        current: maxLevel, target: maxLevel, maxed: true,
        baseSuccess: 100, success: 100, fail: 0, downgrade: 0, destroy: 0, keep: 0,
        step: 0, stack: 0, pityMax: 0, pityRemaining: 0, cost: 0,
      );
    }
    final base = baseSuccess(target);
    final step = pityStep(target);
    final eff = effectiveSuccess(target, stack);
    final fail = 100 - eff;
    final b = failBranch(target);
    final destroyAbs = fail * b.destroy / 100;
    final downAbs = fail * b.down / 100;
    final keepAbs = fail * b.keep / 100;
    final pm = pityMax(target);
    final remaining = pm <= 0 ? 0 : max(0, pm - stack);
    return EnhanceInfo(
      current: currentLevel,
      target: target,
      maxed: false,
      baseSuccess: base,
      success: eff,
      fail: fail,
      downgrade: downAbs,
      destroy: destroyAbs,
      keep: keepAbs,
      step: step,
      stack: stack,
      pityMax: pm,
      pityRemaining: remaining,
      cost: cost(target),
    );
  }
}

enum EnhanceResult { success, keep, downgrade, destroy }

// UI 표시용(절대 확률 — 합 100). pityRemaining = 100% 확정까지 남은 실패 수.
class EnhanceInfo {
  final int current;
  final int target;
  final bool maxed;
  final double baseSuccess;
  final double success; // 천장 반영 성공확률
  final double fail;
  final double downgrade;
  final double destroy;
  final double keep;
  final double step; // 실패 1회당 보정%
  final int stack; // 현재 누적 스택
  final int pityMax;
  final int pityRemaining; // 확정까지 남은 실패
  final int cost;

  const EnhanceInfo({
    required this.current,
    required this.target,
    required this.maxed,
    required this.baseSuccess,
    required this.success,
    required this.fail,
    required this.downgrade,
    required this.destroy,
    required this.keep,
    required this.step,
    required this.stack,
    required this.pityMax,
    required this.pityRemaining,
    required this.cost,
  });
}
