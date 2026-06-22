// rpc_enhance_item (§6.1, §8 강화 플로우) — 소유/재료 검증은 PG 함수, 성공여부는 서버 RNG.

interface EnhanceRequest {
  item_id: string;
  scroll_template: string;
  idempotency_key?: string;
}

// 주문서별 성공률. db/seed 의 item_templates.base_stats.success_rate 와 일치시킬 것.
// TODO(Phase 2): DB 에서 success_rate 를 조회해 단일 소스화.
const SCROLL_RATES: { [tpl: string]: number } = {
  scroll_enhance_t1: 0.7,
  scroll_enhance_t2: 0.5,
};

function rpcEnhanceItem(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  payload: string,
): string {
  if (!ctx.userId) return errResponse('not authenticated', 'unauthenticated');

  const req = parsePayload<EnhanceRequest>(payload);
  if (!req.item_id || !req.scroll_template) {
    return errResponse('item_id and scroll_template required', 'bad_request');
  }

  const rate = SCROLL_RATES[req.scroll_template];
  if (rate == null) return errResponse('unknown scroll template', 'bad_request');

  // 서버 권위 RNG (§3.5).
  const success = rollSuccess(rate);
  const idem = req.idempotency_key || `enhance:${nk.uuidv4()}`;

  const res = supabaseRpc(ctx, nk, logger, 'enhance_item', {
    p_user: ctx.userId,
    p_item: req.item_id,
    p_scroll_template: req.scroll_template,
    p_success: success,
    p_idem: idem,
  });

  return okResponse({ result: res });
}
