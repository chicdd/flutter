// 서버 권위 오픈월드 매치(§6.2) — 몬스터 인스턴스를 서버가 소유/시뮬레이션해 모든 클라이언트가 공유.
//  - 플레이어 위치를 받아 그 주변에 몬스터를 스폰(보로노이 존 레벨로 종류/레벨 결정).
//  - 몬스터 HP/위치/AI 를 서버가 권위적으로 굴리고 주기적으로 스냅샷 브로드캐스트.
//  - 데미지(HIT)는 공격자(매치 sender)별로 기여도 장부에 누적(소유권 없음).
//  - 사망 시 기여 비중(지분)으로 골드/경험치를 독립 산정해 각 기여자에게 REWARD 전송.
//
// 규칙(공식 패턴): 핸들러는 전역 named function, registerMatch 에는 인라인 객체 리터럴로 모은다.
// 다른 매치(trade)와 전역 이름이 겹치면 안 되므로 모두 world* 접두사를 쓴다.

const WorldOp = {
  SNAPSHOT: 1, // server→clients: { m:[몬스터], p:[플레이어] }
  POSITION: 2, // client→server: { x,y,l,n }
  HIT: 3, // client→server: { id, dmg }
  REWARD: 4, // server→one client: { g,e,loot,t,el,lv }
  DEATH: 5, // server→clients: { id }
} as const;

// ── 존(보로노이) — 클라이언트 WorldGen 과 동일 상수로 결정론 일치 ──
const W_CELL = 6400;
const W_HOMEX = 1000;
const W_HOMEY = 1000;
const W_TOWNR = 360;
const W_MAXLVR = 6400 * 0.55; // 3520
const W_MAXLV = 50;
const W_JIT = 0.3;

function wHash(gx: number, gy: number): number {
  let h = (0x5a0e ^ (gx * 73856093) ^ (gy * 19349663)) | 0;
  h = (h ^ (h >> 13)) * 1274126177;
  return h & 0x7fffffff;
}

function wTownXY(gx: number, gy: number): { x: number; y: number } {
  if (gx === 0 && gy === 0) return { x: W_HOMEX, y: W_HOMEY };
  const h = wHash(gx, gy);
  const jx = ((h & 0xffff) / 65535 - 0.5) * W_CELL * W_JIT * 2;
  const jy = (((h >> 16) & 0xffff) / 65535 - 0.5) * W_CELL * W_JIT * 2;
  return { x: W_HOMEX + gx * W_CELL + jx, y: W_HOMEY + gy * W_CELL + jy };
}

function wNearestTownDist(x: number, y: number): number {
  const cgx = Math.round((x - W_HOMEX) / W_CELL);
  const cgy = Math.round((y - W_HOMEY) / W_CELL);
  let best = Infinity;
  for (let dy = -1; dy <= 1; dy++) {
    for (let dx = -1; dx <= 1; dx++) {
      const t = wTownXY(cgx + dx, cgy + dy);
      const d = Math.sqrt((t.x - x) * (t.x - x) + (t.y - y) * (t.y - y));
      if (d < best) best = d;
    }
  }
  return best;
}

function wValueNoise(x: number, y: number): number {
  // 저렴한 해시 기반 변동(-1..1). (클라 Perlin 과 완전 동일하진 않으나 권위는 서버.)
  const ix = Math.floor(x / 700);
  const iy = Math.floor(y / 700);
  const h = wHash(ix * 911, iy * 877);
  return (h % 1000) / 500 - 1;
}

function wSmooth(t: number): number {
  if (t < 0) t = 0;
  if (t > 1) t = 1;
  return t * t * (3 - 2 * t);
}

function wInSafe(x: number, y: number): boolean {
  return wNearestTownDist(x, y) <= W_TOWNR;
}

function wLevelAt(x: number, y: number): number {
  const d = wNearestTownDist(x, y);
  if (d <= W_TOWNR) return 1;
  const ramp = (d - W_TOWNR) / (W_MAXLVR - W_TOWNR);
  let lv = 1 + (W_MAXLV - 1) * wSmooth(ramp);
  lv += wValueNoise(x, y) * W_MAXLV * 0.12;
  lv = Math.round(lv);
  if (lv < 1) lv = 1;
  if (lv > W_MAXLV) lv = W_MAXLV;
  return lv;
}

// 레벨대별 몬스터 풀(클라 monster_catalog 의 id 와 일치해야 렌더됨). (id, baseHp, minLv, maxLv)
interface WMonsterDef {
  id: string;
  hp: number;
  min: number;
  max: number;
}
const W_POOL: WMonsterDef[] = [
  { id: 'slime', hp: 38, min: 1, max: 8 },
  { id: 'rat', hp: 30, min: 1, max: 7 },
  { id: 'goblin', hp: 65, min: 1, max: 9 },
  { id: 'kobold', hp: 50, min: 2, max: 10 },
  { id: 'bat', hp: 40, min: 2, max: 10 },
  { id: 'wolf', hp: 85, min: 4, max: 14 },
  { id: 'skeleton', hp: 100, min: 5, max: 16 },
  { id: 'zombie', hp: 110, min: 5, max: 15 },
  { id: 'lizardman', hp: 120, min: 6, max: 16 },
  { id: 'orc', hp: 150, min: 8, max: 20 },
  { id: 'ghoul', hp: 130, min: 8, max: 18 },
  { id: 'harpy', hp: 110, min: 9, max: 19 },
  { id: 'gargoyle', hp: 200, min: 10, max: 22 },
  { id: 'troll', hp: 280, min: 12, max: 24 },
  { id: 'ogre', hp: 320, min: 14, max: 26 },
  { id: 'minotaur', hp: 300, min: 15, max: 28 },
  { id: 'wraith', hp: 180, min: 16, max: 30 },
  { id: 'golem', hp: 360, min: 18, max: 32 },
  { id: 'lich', hp: 300, min: 24, max: 38 },
  { id: 'vampire', hp: 320, min: 25, max: 40 },
  { id: 'basilisk', hp: 340, min: 22, max: 38 },
  { id: 'chimera', hp: 520, min: 32, max: 46 },
  { id: 'griffin', hp: 480, min: 33, max: 48 },
  { id: 'wyvern', hp: 560, min: 35, max: 50 },
  { id: 'dragon', hp: 800, min: 38, max: 50 },
];

function wPickMonster(level: number): WMonsterDef {
  const cands = W_POOL.filter((m) => level >= m.min && level <= m.max);
  const pool = cands.length > 0 ? cands : W_POOL.filter((m) => level >= m.min);
  const list = pool.length > 0 ? pool : [W_POOL[0]];
  return list[Math.floor(Math.random() * list.length)];
}

// ── 매치 상태 ──
interface WPlayer {
  presence: nkruntime.Presence;
  x: number;
  y: number;
  level: number;
  name: string;
}
interface WMonster {
  id: number;
  t: string;
  x: number;
  y: number;
  hp: number;
  mhp: number;
  lv: number;
  el: boolean;
  ledger: { [userId: string]: number };
}
interface WorldState {
  players: { [userId: string]: WPlayer };
  monsters: { [id: string]: WMonster };
  nextId: number;
  snapTick: number;
}

const W_TICK = 8;
const W_PER_PLAYER = 8; // 플레이어당 유지 몬스터
const W_TOTAL_CAP = 60;
const W_SPAWN_MIN = 620;
const W_SPAWN_MAX = 1150;
const W_DESPAWN = 1700;
const W_AGGRO = 280;

function worldMatchInit(
  _ctx: nkruntime.Context,
  _logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  _params: { [key: string]: string },
): { state: WorldState; tickRate: number; label: string } {
  const state: WorldState = { players: {}, monsters: {}, nextId: 1, snapTick: 0 };
  return { state, tickRate: W_TICK, label: 'world' };
}

function worldMatchJoinAttempt(
  _ctx: nkruntime.Context,
  _logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  _dispatcher: nkruntime.MatchDispatcher,
  _tick: number,
  state: WorldState,
  _presence: nkruntime.Presence,
): { state: WorldState; accept: boolean } {
  return { state, accept: true };
}

function worldMatchJoin(
  _ctx: nkruntime.Context,
  _logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  _dispatcher: nkruntime.MatchDispatcher,
  _tick: number,
  state: WorldState,
  presences: nkruntime.Presence[],
): { state: WorldState } {
  for (const p of presences) {
    state.players[p.userId] = {
      presence: p,
      x: W_HOMEX,
      y: W_HOMEY,
      level: 1,
      name: p.username || '플레이어',
    };
  }
  return { state };
}

function worldMatchLeave(
  _ctx: nkruntime.Context,
  _logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  _dispatcher: nkruntime.MatchDispatcher,
  _tick: number,
  state: WorldState,
  presences: nkruntime.Presence[],
): { state: WorldState } {
  for (const p of presences) {
    delete state.players[p.userId];
  }
  return { state };
}

function worldDist(ax: number, ay: number, bx: number, by: number): number {
  return Math.sqrt((ax - bx) * (ax - bx) + (ay - by) * (ay - by));
}

function worldNearestPlayer(state: WorldState, x: number, y: number): WPlayer | null {
  let best: WPlayer | null = null;
  let bd = Infinity;
  for (const uid in state.players) {
    const p = state.players[uid];
    const d = worldDist(x, y, p.x, p.y);
    if (d < bd) {
      bd = d;
      best = p;
    }
  }
  return best;
}

function worldSpawnNear(state: WorldState, p: WPlayer): void {
  let x = p.x;
  let y = p.y;
  for (let i = 0; i < 6; i++) {
    const ang = Math.random() * Math.PI * 2;
    const r = W_SPAWN_MIN + Math.random() * (W_SPAWN_MAX - W_SPAWN_MIN);
    x = p.x + Math.cos(ang) * r;
    y = p.y + Math.sin(ang) * r;
    if (!wInSafe(x, y)) break;
  }
  const lv = wLevelAt(x, y);
  const def = wPickMonster(lv);
  const elite = Math.random() < 0.18;
  const scale = 1 + (lv - 1) * 0.14;
  const mhp = Math.round(def.hp * scale * (elite ? 2.6 : 1.0));
  const id = state.nextId++;
  state.monsters[id] = { id, t: def.id, x, y, hp: mhp, mhp, lv, el: elite, ledger: {} };
}

function worldCountNear(state: WorldState, p: WPlayer): number {
  let n = 0;
  for (const k in state.monsters) {
    const m = state.monsters[k];
    if (worldDist(m.x, m.y, p.x, p.y) <= W_DESPAWN) n++;
  }
  return n;
}

function worldBaseGold(lv: number): number {
  return Math.round(6 + lv * 4 + Math.random() * (lv + 4));
}
function worldBaseExp(lv: number): number {
  return Math.round(14 + lv * 6);
}

// 사망 처리: 기여 비중으로 보상 산정 후 각 기여자에게 전송.
function worldKill(dispatcher: nkruntime.MatchDispatcher, state: WorldState, m: WMonster): void {
  let total = 0;
  for (const uid in m.ledger) total += m.ledger[uid];
  const baseGold = worldBaseGold(m.lv) * (m.el ? 4 : 1);
  const baseExp = worldBaseExp(m.lv) * (m.el ? 3 : 1);
  if (total > 0) {
    for (const uid in m.ledger) {
      const p = state.players[uid];
      if (!p) continue;
      const frac = m.ledger[uid] / total;
      const reward = {
        g: Math.round(baseGold * frac),
        e: Math.round(baseExp * frac),
        loot: frac >= 0.1,
        t: m.t,
        el: m.el,
        lv: m.lv,
      };
      dispatcher.broadcastMessage(WorldOp.REWARD, JSON.stringify(reward), [p.presence], null, true);
    }
  }
  dispatcher.broadcastMessage(WorldOp.DEATH, JSON.stringify({ id: m.id }), null, null, true);
  delete state.monsters[m.id];
}

function worldMatchLoop(
  _ctx: nkruntime.Context,
  _logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  dispatcher: nkruntime.MatchDispatcher,
  _tick: number,
  state: WorldState,
  messages: nkruntime.MatchMessage[],
): { state: WorldState } | null {
  // 1) 메시지 처리.
  for (const msg of messages) {
    const uid = msg.sender.userId;
    let data: any = {};
    try {
      data = msg.data ? JSON.parse(nk.binaryToString(msg.data)) : {};
    } catch (e) {
      continue;
    }
    if (msg.opCode === WorldOp.POSITION) {
      const p = state.players[uid];
      if (p) {
        p.x = Number(data.x) || p.x;
        p.y = Number(data.y) || p.y;
        p.level = Number(data.l) || p.level;
        if (data.n) p.name = String(data.n);
      }
    } else if (msg.opCode === WorldOp.HIT) {
      const m = state.monsters[Number(data.id)];
      const dmg = Number(data.dmg) || 0;
      if (m && dmg > 0) {
        m.hp -= dmg;
        m.ledger[uid] = (m.ledger[uid] || 0) + dmg;
        if (m.hp <= 0) worldKill(dispatcher, state, m);
      }
    }
  }

  // 2) 몬스터 회수(모든 플레이어에게서 멀거나 안전지대) + AI 추격.
  const ids = Object.keys(state.monsters);
  for (const k of ids) {
    const m = state.monsters[k];
    const np = worldNearestPlayer(state, m.x, m.y);
    if (!np || worldDist(m.x, m.y, np.x, np.y) > W_DESPAWN || wInSafe(m.x, m.y)) {
      delete state.monsters[m.id];
      continue;
    }
    const d = worldDist(m.x, m.y, np.x, np.y);
    if (d <= W_AGGRO && d > 36) {
      const speed = 90 / W_TICK; // px/tick (대략)
      m.x += ((np.x - m.x) / d) * speed;
      m.y += ((np.y - m.y) / d) * speed;
    }
  }

  // 3) 플레이어별 스폰 보충(전체 캡 내).
  let totalMonsters = Object.keys(state.monsters).length;
  for (const uid in state.players) {
    const p = state.players[uid];
    if (wInSafe(p.x, p.y)) continue;
    let near = worldCountNear(state, p);
    while (near < W_PER_PLAYER && totalMonsters < W_TOTAL_CAP) {
      worldSpawnNear(state, p);
      near++;
      totalMonsters++;
    }
  }

  // 4) 스냅샷 브로드캐스트(2틱마다 ≈ 초당 4회).
  state.snapTick++;
  if (state.snapTick % 2 === 0) {
    const m: any[] = [];
    for (const k in state.monsters) {
      const mo = state.monsters[k];
      m.push({ id: mo.id, t: mo.t, x: Math.round(mo.x), y: Math.round(mo.y), hp: mo.hp, mhp: mo.mhp, lv: mo.lv, el: mo.el });
    }
    const pl: any[] = [];
    for (const uid in state.players) {
      const p = state.players[uid];
      pl.push({ u: uid, x: Math.round(p.x), y: Math.round(p.y), l: p.level, n: p.name });
    }
    dispatcher.broadcastMessage(WorldOp.SNAPSHOT, JSON.stringify({ m: m, p: pl }), null, null, false);
  }

  return { state };
}

function worldMatchTerminate(
  _ctx: nkruntime.Context,
  _logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  _dispatcher: nkruntime.MatchDispatcher,
  _tick: number,
  state: WorldState,
  _graceSeconds: number,
): { state: WorldState } | null {
  return { state };
}

function worldMatchSignal(
  _ctx: nkruntime.Context,
  _logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  _dispatcher: nkruntime.MatchDispatcher,
  _tick: number,
  state: WorldState,
  _data: string,
): { state: WorldState; data?: string } {
  return { state };
}
