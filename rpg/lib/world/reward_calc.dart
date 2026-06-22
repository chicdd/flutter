// ── 서버측 지분제(기여도) 보상 연산(순수 로직) ──
// 몬스터에는 "소유권"이 없다. 각 유저가 입힌 누적 데미지 비중(지분)에 따라
// 골드/경험치를 "독립적으로" 산정한다(나눠 갖는 패널티가 아니라 기여 비례 분배).
// 일정 지분 미만은 드랍(루팅) 대상에서 제외한다.
// 멀티플레이어에서는 서버가 권위적으로 공유 몬스터의 ledger 를 들고, 사망 시
// distribute() 결과를 각 유저에게 브로드캐스트한다. (클라 권위 솔로에서는 단일 기여자 = 전액.)

class RewardShare {
  final String playerId;
  final double fraction; // 0~1 지분
  final int gold;
  final int exp;
  final bool lootEligible; // 드랍 획득 자격(최소 지분 충족)
  const RewardShare({
    required this.playerId,
    required this.fraction,
    required this.gold,
    required this.exp,
    required this.lootEligible,
  });
}

class ContributionLedger {
  final Map<String, double> _damage = {};
  double _total = 0;

  double get total => _total;
  bool get isEmpty => _total <= 0;

  // 한 번의 피해 기록(공격자 id별 누적).
  void record(String playerId, num damage) {
    if (damage <= 0) return;
    _damage[playerId] = (_damage[playerId] ?? 0) + damage.toDouble();
    _total += damage.toDouble();
  }

  // 사망 시 전체 분배(브로드캐스트용). 각 유저는 지분 비례 독립 보상.
  List<RewardShare> distribute({
    required int baseGold,
    required int baseExp,
    double minShareForLoot = 0.10,
  }) {
    if (_total <= 0) return const [];
    final out = <RewardShare>[];
    _damage.forEach((id, dmg) {
      final f = (dmg / _total).clamp(0.0, 1.0);
      out.add(RewardShare(
        playerId: id,
        fraction: f,
        gold: (baseGold * f).round(),
        exp: (baseExp * f).round(),
        lootEligible: f >= minShareForLoot,
      ));
    });
    return out;
  }

  // 특정 유저의 몫만(클라 권위 솔로 경로). 기여가 없으면 전액(폴백).
  RewardShare shareFor(String playerId, {required int baseGold, required int baseExp, double minShareForLoot = 0.10}) {
    if (_total <= 0) {
      return RewardShare(playerId: playerId, fraction: 1, gold: baseGold, exp: baseExp, lootEligible: true);
    }
    final f = ((_damage[playerId] ?? 0) / _total).clamp(0.0, 1.0);
    return RewardShare(
      playerId: playerId,
      fraction: f,
      gold: (baseGold * f).round(),
      exp: (baseExp * f).round(),
      lootEligible: f >= minShareForLoot,
    );
  }
}
