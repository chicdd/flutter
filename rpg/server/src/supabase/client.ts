// Nakama → Supabase 서버-투-서버 호출 (§6.3).
// service_role 키로 PostgREST RPC 엔드포인트(${SUPABASE_URL}/rest/v1/rpc/<fn>)를 호출한다.
// 이 키는 절대 클라이언트에 노출하지 않는다(서버 env 전용).

function supabaseRpc(
  ctx: nkruntime.Context,
  nk: nkruntime.Nakama,
  logger: nkruntime.Logger,
  fn: string,
  args: Record<string, unknown>,
): any {
  const url = ctx.env!['SUPABASE_URL'];
  const key = ctx.env!['SUPABASE_SERVICE_ROLE_KEY'];
  if (!url || !key) {
    logger.error('SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY env not configured');
    throw new Error('supabase env not configured');
  }

  const endpoint = `${url.replace(/\/+$/, '')}/rest/v1/rpc/${fn}`;
  const headers: { [k: string]: string } = {
    'Content-Type': 'application/json',
    'apikey': key,
    'Authorization': `Bearer ${key}`,
  };

  const res = nk.httpRequest(endpoint, 'post', headers, JSON.stringify(args));
  if (res.code < 200 || res.code >= 300) {
    logger.error('supabase rpc %s failed: code=%d body=%s', fn, res.code, res.body);
    throw new Error(`supabase rpc ${fn} failed (${res.code})`);
  }
  if (!res.body) return null;
  try {
    return JSON.parse(res.body);
  } catch (e) {
    logger.error('supabase rpc %s: invalid JSON body=%s', fn, res.body);
    throw new Error(`supabase rpc ${fn}: invalid json`);
  }
}
