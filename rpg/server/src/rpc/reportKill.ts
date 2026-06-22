// rpc_report_kill (§6.1, §8 드랍 플로우) — 이중청구 차단 → 루트 롤(서버 RNG) → grant_drop.

interface ReportKillRequest {
  run_seed: number;
  monster_idx: number;
}

function rpcReportKill(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  payload: string,
): string {
  if (!ctx.userId) return errResponse('not authenticated', 'unauthenticated');

  // 레이트리밋 (베스트-에포트). 초당 과도한 킬 보고 차단.
  if (!allow(ctx.userId, 'report_kill', 20, 1000)) {
    return errResponse('rate limited', 'rate_limited');
  }

  const req = parsePayload<ReportKillRequest>(payload);
  if (req.run_seed == null || req.monster_idx == null) {
    return errResponse('run_seed and monster_idx required', 'bad_request');
  }

  // (seed, idx) → 몬스터 템플릿 서버 재도출(권위).
  const monster = monsterAt(req.run_seed, req.monster_idx);
  if (!monster) {
    return errResponse('invalid monster_idx', 'bad_request');
  }

  // 이중청구 차단 + 루트 테이블 조회(원자). 이미 처리됐으면 already_claimed.
  const claim = supabaseRpc(ctx, nk, logger, 'claim_kill', {
    p_seed: req.run_seed,
    p_idx: req.monster_idx,
    p_owner: ctx.userId,
    p_monster: monster.template_id,
  });

  if (!claim || claim.ok !== true) {
    return okResponse({ already_claimed: true, drop: null });
  }

  // 서버 RNG 로 드랍 롤.
  const entries = (claim.entries || []) as LootEntry[];
  const rolled = rollLoot(entries);
  if (!rolled) {
    return okResponse({ already_claimed: false, drop: null });
  }

  // grant_drop 멱등키: 킬 단위로 결정론적 → 재시도 안전(§3.3).
  const idem = `drop:${req.run_seed}:${req.monster_idx}:${ctx.userId}`;
  // NOTE(§3.3 엣지): claim 성공 후 grant 실패 시 재시도하면 claim 은 already_claimed 가 되어
  // 드랍이 누락될 수 있다. 운영에서는 claim+roll+grant 를 단일 PG 함수로 합치거나
  // claim 에 pending 상태를 두어 보완(Phase 5).
  const grant = supabaseRpc(ctx, nk, logger, 'grant_drop', {
    p_user: ctx.userId,
    p_template: rolled.template_id,
    p_qty: rolled.quantity,
    p_idem: idem,
  });

  logger.info('report_kill user=%s seed=%d idx=%d drop=%s x%d', ctx.userId,
    req.run_seed, req.monster_idx, rolled.template_id, rolled.quantity);

  return okResponse({
    already_claimed: false,
    drop: {
      template_id: rolled.template_id,
      quantity: rolled.quantity,
      item_id: grant ? grant.item_id : undefined,
    },
  });
}
