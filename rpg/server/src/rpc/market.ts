// rpc_list_item / rpc_buy_listing / rpc_cancel_listing (§6.1, §8 마켓 플로우)
// 모든 변경은 PG SECURITY DEFINER 함수에서 원자적으로. 멱등키 전달(§3.3).

interface ListRequest {
  item_id: string;
  price: number;
  idempotency_key?: string;
}
interface BuyRequest {
  listing_id: string;
  idempotency_key?: string;
}
interface CancelRequest {
  listing_id: string;
  idempotency_key?: string;
}

function rpcListItem(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  payload: string,
): string {
  if (!ctx.userId) return errResponse('not authenticated', 'unauthenticated');
  const req = parsePayload<ListRequest>(payload);
  if (!req.item_id || !req.price || req.price <= 0) {
    return errResponse('item_id and positive price required', 'bad_request');
  }
  const res = supabaseRpc(ctx, nk, logger, 'create_listing', {
    p_seller: ctx.userId,
    p_item: req.item_id,
    p_price: req.price,
    p_idem: req.idempotency_key || `list:${nk.uuidv4()}`,
  });
  return okResponse({ result: res });
}

function rpcBuyListing(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  payload: string,
): string {
  if (!ctx.userId) return errResponse('not authenticated', 'unauthenticated');
  const req = parsePayload<BuyRequest>(payload);
  if (!req.listing_id) return errResponse('listing_id required', 'bad_request');
  const res = supabaseRpc(ctx, nk, logger, 'buy_listing', {
    p_buyer: ctx.userId,
    p_listing: req.listing_id,
    p_idem: req.idempotency_key || `buy:${nk.uuidv4()}`,
  });
  return okResponse({ result: res });
}

function rpcCancelListing(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  payload: string,
): string {
  if (!ctx.userId) return errResponse('not authenticated', 'unauthenticated');
  const req = parsePayload<CancelRequest>(payload);
  if (!req.listing_id) return errResponse('listing_id required', 'bad_request');
  const res = supabaseRpc(ctx, nk, logger, 'cancel_listing', {
    p_seller: ctx.userId,
    p_listing: req.listing_id,
    p_idem: req.idempotency_key || `cancel:${nk.uuidv4()}`,
  });
  return okResponse({ result: res });
}
