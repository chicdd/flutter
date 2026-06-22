// rpc_create_instance (§6.1) — 시드 생성, 몬스터 레이아웃 반환, 세션에 시드 기록.

interface CreateInstanceRequest {
  biome?: string;
  monster_count?: number;
}

function rpcCreateInstance(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  payload: string,
): string {
  if (!ctx.userId) return errResponse('not authenticated', 'unauthenticated');

  const req = parsePayload<CreateInstanceRequest>(payload);
  const biome = req.biome || 'forest';
  const count = Math.max(1, Math.min(req.monster_count || 12, 50));

  // 프로필 보장(FK 대비). 멱등.
  try {
    supabaseRpc(ctx, nk, logger, 'ensure_profile', {
      p_user: ctx.userId,
      p_name: ctx.username || '',
    });
  } catch (e) {
    logger.warn('ensure_profile failed (non-fatal): %s', String(e));
  }

  const seed = makeSeed();
  const monsters = generateMonsters(seed, count);

  // 시드를 세션 변수처럼 기록할 곳이 마땅치 않으므로(JS 런타임은 세션 토큰에 vars 주입은 auth 시점),
  // MVP 는 클라이언트가 run_seed 를 보유하고 reportKill 에 되돌려준다. 서버는 (seed, idx)로 재검증.
  const resp: CreateInstanceResponse = {
    run_seed: seed,
    biome,
    monsters,
  };
  logger.info('create_instance user=%s seed=%d biome=%s monsters=%d', ctx.userId, seed, biome, count);
  return okResponse(resp as unknown as Record<string, unknown>);
}
