// 실시간 P2P 거래 match handler (§6.2) — 2인 권위 세션. 거래창 상태머신을 서버가 소유.
//
// 주의: Nakama JS 런타임은 registerMatch 에 넘긴 핸들러의 각 메서드에서 함수 식별자를 추출한다.
//       메서드 축약형({ matchInit(){} })은 식별자 추출 실패로 panic 한다.
//       → 각 핸들러를 named function 으로 정의하고 객체에 property shorthand 로 모은다(공식 패턴).
//
// 상태 흐름(§6.2):
//   open ─(add/remove)→ open
//   open ─(양쪽 lock)→ locked
//   locked ─(내용 변경)→ open (lock 리셋)
//   locked ─(양쪽 confirm)→ confirmed → execute_trade() 원자 스왑 → completed
//   어느 단계든 (cancel / 연결끊김) → cancelled (에스크로 전량 복귀)
//
// 범위 메모(Phase 4): 본 핸들러는 상태머신/메시징 골격이다. 에스크로 진입/복귀 PG 함수와
//   execute_trade() 와이어링은 Phase 4 에서 채운다(양쪽 confirm 지점에 표시).

// 클라이언트 ↔ 매치 op code.
const TradeOp = {
  STATE: 1, // 서버→클라: 현재 거래 상태 브로드캐스트
  ADD_ITEM: 2, // 클라→서버: 아이템 추가
  REMOVE_ITEM: 3, // 클라→서버: 아이템 제거
  SET_GOLD: 4, // 클라→서버: 골드 설정
  LOCK: 5, // 클라→서버: 잠금
  CONFIRM: 6, // 클라→서버: 확정
  CANCEL: 7, // 클라→서버: 취소
  COMPLETED: 8, // 서버→클라: 완료 통지
  ERROR: 9, // 서버→클라: 에러
} as const;

interface Side {
  userId: string;
  presence?: nkruntime.Presence;
  items: string[];
  gold: number;
  locked: boolean;
  confirmed: boolean;
}

interface TradeState {
  state: 'open' | 'locked' | 'confirmed' | 'completed' | 'cancelled';
  a: Side;
  b: Side;
  emptyTicks: number;
}

const TICK_RATE = 4; // 초당 루프 횟수

function emptySide(userId: string): Side {
  return { userId, items: [], gold: 0, locked: false, confirmed: false };
}

function sideFor(s: TradeState, userId: string): Side | null {
  if (s.a.userId === userId) return s.a;
  if (s.b.userId === userId) return s.b;
  return null;
}

// 내용이 바뀌면 lock/confirm 리셋하고 open 으로(§6.2).
function resetLocks(s: TradeState): void {
  s.a.locked = false;
  s.b.locked = false;
  s.a.confirmed = false;
  s.b.confirmed = false;
  s.state = 'open';
}

function broadcastState(dispatcher: nkruntime.MatchDispatcher, s: TradeState): void {
  const snapshot = {
    state: s.state,
    a: { userId: s.a.userId, items: s.a.items, gold: s.a.gold, locked: s.a.locked, confirmed: s.a.confirmed },
    b: { userId: s.b.userId, items: s.b.items, gold: s.b.gold, locked: s.b.locked, confirmed: s.b.confirmed },
  };
  dispatcher.broadcastMessage(TradeOp.STATE, JSON.stringify(snapshot), null, null);
}

function matchInit(
  _ctx: nkruntime.Context,
  _logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  params: { [key: string]: string },
): { state: TradeState; tickRate: number; label: string } {
  const aId = (params['a_id'] as string) || '';
  const bId = (params['b_id'] as string) || '';
  const state: TradeState = {
    state: 'open',
    a: emptySide(aId),
    b: emptySide(bId),
    emptyTicks: 0,
  };
  return { state, tickRate: TICK_RATE, label: 'trade' };
}

function matchJoinAttempt(
  _ctx: nkruntime.Context,
  _logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  _dispatcher: nkruntime.MatchDispatcher,
  _tick: number,
  state: TradeState,
  presence: nkruntime.Presence,
): { state: TradeState; accept: boolean } {
  // 미리 지정된 두 당사자만 입장 허용.
  const accept = presence.userId === state.a.userId || presence.userId === state.b.userId;
  return { state, accept };
}

function matchJoin(
  _ctx: nkruntime.Context,
  _logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  dispatcher: nkruntime.MatchDispatcher,
  _tick: number,
  state: TradeState,
  presences: nkruntime.Presence[],
): { state: TradeState } {
  for (const p of presences) {
    const side = sideFor(state, p.userId);
    if (side) side.presence = p;
  }
  broadcastState(dispatcher, state);
  return { state };
}

function matchLeave(
  _ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  _dispatcher: nkruntime.MatchDispatcher,
  _tick: number,
  state: TradeState,
  _presences: nkruntime.Presence[],
): { state: TradeState } | null {
  // 한쪽이라도 나가면 거래 취소 + 에스크로 복귀(§6.2).
  if (state.state !== 'completed') {
    state.state = 'cancelled';
    // TODO(Phase 4): trade_unlock_items() 로 양측 에스크로 복귀.
    logger.info('trade cancelled by leave');
  }
  return null; // 매치 종료
}

function matchLoop(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  dispatcher: nkruntime.MatchDispatcher,
  _tick: number,
  state: TradeState,
  messages: nkruntime.MatchMessage[],
): { state: TradeState } | null {
  for (const msg of messages) {
    const side = sideFor(state, msg.sender.userId);
    if (!side) continue;
    const data = msg.data ? JSON.parse(nk.binaryToString(msg.data)) : {};

    switch (msg.opCode) {
      case TradeOp.ADD_ITEM:
        if (state.state === 'confirmed') break;
        if (data.item_id && side.items.indexOf(data.item_id) < 0) {
          // TODO(Phase 4): trade_lock_item(user, item_id) → location='trade_escrow' 검증/이동.
          side.items.push(data.item_id);
          resetLocks(state);
        }
        break;
      case TradeOp.REMOVE_ITEM:
        if (state.state === 'confirmed') break;
        side.items = side.items.filter((i) => i !== data.item_id);
        resetLocks(state);
        break;
      case TradeOp.SET_GOLD:
        if (state.state === 'confirmed') break;
        side.gold = Math.max(0, Number(data.gold) || 0);
        resetLocks(state);
        break;
      case TradeOp.LOCK:
        side.locked = true;
        if (state.a.locked && state.b.locked) state.state = 'locked';
        break;
      case TradeOp.CONFIRM:
        if (state.state !== 'locked') break;
        side.confirmed = true;
        if (state.a.confirmed && state.b.confirmed) {
          state.state = 'confirmed';
          // ── 양쪽 confirm 도달: 원자 스왑 실행 지점(§6.2) ──
          try {
            // TODO(Phase 4): execute_trade 전에 trades 행을 confirmed 로 upsert 하고
            //   에스크로 무결성을 보장해야 한다. (supabaseRpc 로 execute_trade 호출)
            state.state = 'completed';
            dispatcher.broadcastMessage(TradeOp.COMPLETED, JSON.stringify({ ok: true }), null, null);
          } catch (e) {
            logger.error('execute_trade failed: %s', String(e));
            dispatcher.broadcastMessage(TradeOp.ERROR, JSON.stringify({ error: 'execute_failed' }), null, null);
            state.state = 'locked';
            state.a.confirmed = false;
            state.b.confirmed = false;
          }
        }
        break;
      case TradeOp.CANCEL:
        state.state = 'cancelled';
        // TODO(Phase 4): trade_unlock_items() 에스크로 복귀.
        dispatcher.broadcastMessage(TradeOp.COMPLETED, JSON.stringify({ ok: false, cancelled: true }), null, null);
        return null;
    }
  }

  broadcastState(dispatcher, state);

  if (state.state === 'completed' || state.state === 'cancelled') {
    return null; // 매치 종료
  }
  return { state };
}

function matchTerminate(
  _ctx: nkruntime.Context,
  _logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  _dispatcher: nkruntime.MatchDispatcher,
  _tick: number,
  _state: TradeState,
  _graceSeconds: number,
): { state: TradeState } | null {
  return null;
}

function matchSignal(
  _ctx: nkruntime.Context,
  _logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  _dispatcher: nkruntime.MatchDispatcher,
  _tick: number,
  state: TradeState,
  _data: string,
): { state: TradeState; data?: string } {
  return { state };
}

// 주의: 매치 핸들러 객체는 main.ts 의 registerMatch() 인자에 "인라인 객체 리터럴"로 직접 넘긴다.
// Nakama AST 분석기는 const/let 로 분리한 핸들러 객체를 DeclarationList 에서 못 찾아 panic 하므로
// (DeclarationList 는 var/함수선언만 포함), 객체를 별도 export 하지 않고 위 7개 함수만 export 한다.
