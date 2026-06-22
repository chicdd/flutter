// rpc_get_inventory / rpc_browse_market (§6.1) — 읽기 전용 조회. Nakama 경유로 통일.

function rpcGetInventory(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  _payload: string,
): string {
  if (!ctx.userId) return errResponse('not authenticated', 'unauthenticated');

  // 프로필 보장 후 조회.
  supabaseRpc(ctx, nk, logger, 'ensure_profile', { p_user: ctx.userId, p_name: ctx.username || '' });
  const inv = supabaseRpc(ctx, nk, logger, 'get_inventory', { p_user: ctx.userId });
  return okResponse({ inventory: inv });
}

interface BrowseRequest {
  limit?: number;
  offset?: number;
}

function rpcBrowseMarket(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  payload: string,
): string {
  if (!ctx.userId) return errResponse('not authenticated', 'unauthenticated');
  const req = parsePayload<BrowseRequest>(payload);
  const listings = supabaseRpc(ctx, nk, logger, 'browse_market', {
    p_limit: req.limit || 50,
    p_offset: req.offset || 0,
  });
  return okResponse({ listings });
}
