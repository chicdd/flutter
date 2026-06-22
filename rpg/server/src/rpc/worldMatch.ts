// 공유 오픈월드 매치 진입점 RPC — 권위 매치('world') 싱글톤을 보장하고 matchId 를 돌려준다.
// 클라이언트는 이 id 로 joinMatch 해서 서버 권위 몬스터를 공유한다.
function rpcWorldMatch(
  _ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  _payload: string,
): string {
  let matchId: string | null = null;
  try {
    const found = nk.matchList(1, true, 'world', 0, 100, '');
    if (found && found.length > 0) matchId = found[0].matchId;
  } catch (e) {
    logger.warn('matchList(world) failed: %s', String(e));
  }
  if (!matchId) {
    matchId = nk.matchCreate('world', {});
  }
  return JSON.stringify({ ok: true, match_id: matchId });
}
