// Nakama TS 런타임 진입점 (§6) — RPC/매치/훅 등록.
// 빌드: tsc(outFile, target es5). 파일 간 import/export 없이 전역 스코프로 연결된다
// (공식 nakama-project-template 방식). 모든 핸들러는 전역 named function 이어야 하며,
// 매치 핸들러는 registerMatch() 인자에 인라인 객체 리터럴로 넘긴다.

// 헬스체크용 hello RPC (§11 Phase 0 확인).
function rpcHello(
  _ctx: nkruntime.Context,
  _logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  payload: string,
): string {
  return JSON.stringify({ ok: true, msg: 'hello from nakama ts runtime', echo: payload });
}

// 인증 후 프로필 보장 (§4 identity = Nakama, 경제 row 는 user_id 키).
function ensureProfile(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
): void {
  if (!ctx.userId) return;
  try {
    supabaseRpc(ctx, nk, logger, 'ensure_profile', { p_user: ctx.userId, p_name: ctx.username || '' });
  } catch (e) {
    logger.warn('ensure_profile hook failed (non-fatal): %s', String(e));
  }
}

function afterAuthDevice(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  data: nkruntime.Session,
): nkruntime.Session {
  ensureProfile(ctx, logger, nk);
  return data;
}

function afterAuthEmail(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  data: nkruntime.Session,
): nkruntime.Session {
  ensureProfile(ctx, logger, nk);
  return data;
}

function afterAuthCustom(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  data: nkruntime.Session,
): nkruntime.Session {
  ensureProfile(ctx, logger, nk);
  return data;
}

function InitModule(
  _ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  initializer: nkruntime.Initializer,
): void {
  // ── RPC 등록 (§6.1) — 전부 전역 named 참조 ──
  initializer.registerRpc('rpc_create_instance', rpcCreateInstance);
  initializer.registerRpc('rpc_report_kill', rpcReportKill);
  initializer.registerRpc('rpc_enhance_item', rpcEnhanceItem);
  initializer.registerRpc('rpc_get_inventory', rpcGetInventory);
  initializer.registerRpc('rpc_browse_market', rpcBrowseMarket);
  initializer.registerRpc('rpc_list_item', rpcListItem);
  initializer.registerRpc('rpc_buy_listing', rpcBuyListing);
  initializer.registerRpc('rpc_cancel_listing', rpcCancelListing);
  initializer.registerRpc('rpc_hello', rpcHello);
  initializer.registerRpc('rpc_world_match', rpcWorldMatch);
  initializer.registerRpc('rpc_auth_verify_hint', rpcAuthVerifyHint);
  initializer.registerRpc('rpc_auth_reset_password', rpcAuthResetPassword);

  // ── 실시간 거래 매치 등록 (§6.2) — 인라인 객체 리터럴 + 전역 함수 ──
  initializer.registerMatch('trade', {
    matchInit,
    matchJoinAttempt,
    matchJoin,
    matchLeave,
    matchLoop,
    matchTerminate,
    matchSignal,
  });

  // ── 서버 권위 공유 오픈월드 매치(몬스터 인스턴스 공유) ──
  initializer.registerMatch('world', {
    matchInit: worldMatchInit,
    matchJoinAttempt: worldMatchJoinAttempt,
    matchJoin: worldMatchJoin,
    matchLeave: worldMatchLeave,
    matchLoop: worldMatchLoop,
    matchTerminate: worldMatchTerminate,
    matchSignal: worldMatchSignal,
  });

  // ── 인증 후 프로필 보장 훅 ──
  initializer.registerAfterAuthenticateDevice(afterAuthDevice);
  initializer.registerAfterAuthenticateEmail(afterAuthEmail);
  initializer.registerAfterAuthenticateCustom(afterAuthCustom);

  logger.info('RPG Nakama runtime initialized: RPCs + trade match + auth hooks');
}

// tsc 가 사용 안 한 InitModule 을 제거하지 않도록 참조(공식 패턴). Goja 가 전역 함수로 호출.
// eslint-disable-next-line @typescript-eslint/no-unused-expressions
!InitModule && InitModule.bind(null);
