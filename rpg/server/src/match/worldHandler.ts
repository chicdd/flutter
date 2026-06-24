// 서버 권위 오픈월드 매치(§6.2) — 몬스터 인스턴스를 서버가 소유/시뮬레이션해 모든 클라이언트가 공유.
//  - 플레이어 위치를 받아 그 주변에 몬스터를 스폰(보로노이 존 레벨로 종류/레벨 결정).
//  - 몬스터 HP/위치/AI 를 서버가 권위적으로 굴리고 주기적으로 스냅샷 브로드캐스트.
//  - 데미지(HIT)는 공격자(매치 sender)별로 기여도 장부에 누적(소유권 없음).
//  - 사망 시 기여 비중(지분)으로 골드/경험치를 독립 산정해 각 기여자에게 REWARD 전송.
//
// 규칙(공식 패턴): 핸들러는 전역 named function, registerMatch 에는 인라인 객체 리터럴로 모은다.
// 다른 매치(trade)와 전역 이름이 겹치면 안 되므로 모두 world* 접두사를 쓴다.

const WorldOp = {
  SNAPSHOT: 1, // server→clients: { tk, m:[몬스터(틱/좌표/속도/상태)], p:[플레이어] }
  POSITION: 2, // client→server: { x,y,vx,vy,l,n,df }
  HIT: 3, // client→server: { id, dmg }
  REWARD: 4, // server→one client: { g,e,loot,t,el,lv }
  DEATH: 5, // server→clients: { id }
  PLAYER_DMG: 6, // server→clients: { u, mid, dmg, crit } — 몬스터가 플레이어에게 가한 피해(전원에게 표시)
  ITEM_DROP: 7, // client→server: { item, r, n, x, y } — 아이템 드랍(소유권 없음)
  ITEM_PICKUP: 8, // client→server: { id } — 줍기 요청(서버가 원자적으로 1명에게만 지급)
  ITEM_GRANT: 9, // server→one client: { item } — 줍기 성공(클라가 가방에 추가)
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

// 레벨대별 몬스터 풀(클라 monster_catalog 의 id·스탯과 일치해야 함). 공격 스탯(atk/ap/cc/cm)은
// 클라 CombatStats 와 동일값 — 플레이어 피해를 서버가 권위적으로 산정하기 위함(클라 resolveDamage 와 일치).
interface WMonsterDef {
  id: string;
  hp: number;
  min: number;
  max: number;
  atk: number; // 공격력
  ap: number; // 방어구 관통
  cc: number; // 크리 확률
  cm: number; // 크리 배수
}
const W_POOL: WMonsterDef[] = [
  { id: 'slime', hp: 38, min: 1, max: 8, atk: 10, ap: 0, cc: 0.05, cm: 1.5 },
  { id: 'rat', hp: 30, min: 1, max: 7, atk: 9, ap: 0, cc: 0.08, cm: 1.5 },
  { id: 'goblin', hp: 65, min: 1, max: 9, atk: 16, ap: 2, cc: 0.10, cm: 1.6 },
  { id: 'kobold', hp: 50, min: 2, max: 10, atk: 13, ap: 1, cc: 0.10, cm: 1.6 },
  { id: 'bat', hp: 40, min: 2, max: 10, atk: 12, ap: 1, cc: 0.12, cm: 1.6 },
  { id: 'wolf', hp: 85, min: 4, max: 14, atk: 19, ap: 3, cc: 0.15, cm: 1.7 },
  { id: 'skeleton', hp: 100, min: 5, max: 16, atk: 22, ap: 5, cc: 0.12, cm: 1.7 },
  { id: 'zombie', hp: 110, min: 5, max: 15, atk: 20, ap: 2, cc: 0.06, cm: 1.5 },
  { id: 'lizardman', hp: 120, min: 6, max: 16, atk: 24, ap: 4, cc: 0.12, cm: 1.7 },
  { id: 'orc', hp: 150, min: 8, max: 20, atk: 28, ap: 6, cc: 0.10, cm: 1.8 },
  { id: 'ghoul', hp: 130, min: 8, max: 18, atk: 26, ap: 6, cc: 0.14, cm: 1.7 },
  { id: 'harpy', hp: 110, min: 9, max: 19, atk: 25, ap: 5, cc: 0.18, cm: 1.8 },
  { id: 'gargoyle', hp: 200, min: 10, max: 22, atk: 24, ap: 4, cc: 0.08, cm: 1.6 },
  { id: 'troll', hp: 280, min: 12, max: 24, atk: 34, ap: 5, cc: 0.10, cm: 1.8 },
  { id: 'ogre', hp: 320, min: 14, max: 26, atk: 40, ap: 6, cc: 0.10, cm: 1.9 },
  { id: 'minotaur', hp: 300, min: 15, max: 28, atk: 42, ap: 8, cc: 0.14, cm: 1.9 },
  { id: 'wraith', hp: 180, min: 16, max: 30, atk: 32, ap: 12, cc: 0.18, cm: 1.9 },
  { id: 'golem', hp: 360, min: 18, max: 32, atk: 30, ap: 4, cc: 0.06, cm: 1.6 },
  { id: 'lich', hp: 300, min: 24, max: 38, atk: 44, ap: 16, cc: 0.18, cm: 2.0 },
  { id: 'vampire', hp: 320, min: 25, max: 40, atk: 46, ap: 12, cc: 0.22, cm: 2.0 },
  { id: 'basilisk', hp: 340, min: 22, max: 38, atk: 42, ap: 10, cc: 0.16, cm: 1.9 },
  { id: 'chimera', hp: 520, min: 32, max: 46, atk: 54, ap: 12, cc: 0.18, cm: 2.1 },
  { id: 'griffin', hp: 480, min: 33, max: 48, atk: 52, ap: 14, cc: 0.20, cm: 2.0 },
  { id: 'wyvern', hp: 560, min: 35, max: 50, atk: 58, ap: 14, cc: 0.18, cm: 2.1 },
  { id: 'dragon', hp: 800, min: 38, max: 50, atk: 68, ap: 16, cc: 0.20, cm: 2.2 },
];
const W_POOL_BY_ID: { [id: string]: WMonsterDef } = {};
for (let _i = 0; _i < W_POOL.length; _i++) W_POOL_BY_ID[W_POOL[_i].id] = W_POOL[_i];

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
  vx: number;
  vy: number;
  level: number;
  name: string;
  def: number; // 방어력(클라가 POSITION 으로 보고 — 서버 피해 산정용)
  invulnUntil: number; // 이 ms 까지 무적(피격 후 1초)
}
interface WMonster {
  id: number;
  t: string;
  x: number;
  y: number;
  vx: number; // px/s (추측 항법용)
  vy: number;
  hp: number;
  mhp: number;
  lv: number;
  el: boolean;
  st: number; // 0=대기 1=이동
  ledger: { [userId: string]: number };
}
// 월드에 떨어진 아이템(소유권 없음). item=클라 직렬화 JSON(서버는 불투명 보관), r/n=표시용 등급/이름.
interface WDrop {
  id: string;
  item: string;
  r: number; // rarity index(표시 색)
  n: string; // 이름(표시)
  x: number;
  y: number;
  ts: number;
}
interface WorldState {
  players: { [userId: string]: WPlayer };
  monsters: { [id: string]: WMonster };
  drops: { [id: string]: WDrop };
  nextId: number;
  nextDropId: number;
  tick: number; // 고정 틱 카운터(루프마다 +1)
}

const W_TICK = 30; // 고정 30Hz(33ms 주기). ★클라 NetClock.tickRate 와 반드시 일치★ (불일치 시 버벅임)
const W_PER_PLAYER = 8; // 플레이어당 유지 몬스터
const W_TOTAL_CAP = 60;
const W_SPAWN_MIN = 620;
const W_SPAWN_MAX = 1150;
const W_DESPAWN = 1700;
const W_AGGRO = 280;
const W_MELEE = 40; // 근접 공격 사거리(클라 meleeRange 38 + 보간지연 여유)
const W_INVULN_MS = 1000; // 피격 후 무적(초당 1회 피해)

function worldMatchInit(
  _ctx: nkruntime.Context,
  _logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  _params: { [key: string]: string },
): { state: WorldState; tickRate: number; label: string } {
  const state: WorldState = { players: {}, monsters: {}, drops: {}, nextId: 1, nextDropId: 1, tick: 0 };
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
      vx: 0,
      vy: 0,
      level: 1,
      name: p.username || '플레이어',
      def: 6,
      invulnUntil: 0,
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
  state.monsters[id] = { id, t: def.id, x, y, vx: 0, vy: 0, hp: mhp, mhp, lv, el: elite, st: 0, ledger: {} };
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

// 1마리당 처치 EXP(기획 표, 클라 Leveling 과 동일 앵커·선형보간).
const W_EXP_PTS: number[][] = [[1, 10], [10, 25], [13, 30], [30, 75], [50, 150], [70, 300], [90, 600], [99, 800]];
function wMonsterExp(lv: number): number {
  const pts = W_EXP_PTS;
  if (lv <= pts[0][0]) return pts[0][1];
  if (lv >= pts[pts.length - 1][0]) return pts[pts.length - 1][1];
  for (let i = 0; i < pts.length - 1; i++) {
    const a = pts[i];
    const b = pts[i + 1];
    if (lv >= a[0] && lv <= b[0]) {
      const t = (lv - a[0]) / (b[0] - a[0]);
      return Math.round(a[1] + (b[1] - a[1]) * t);
    }
  }
  return pts[pts.length - 1][1];
}
const W_BOSS: { [id: string]: boolean } = { chimera: true, griffin: true, wyvern: true, dragon: true };

// 사망 처리: 기여 비중으로 보상 산정 후 각 기여자에게 전송(경험치는 기여자별 레벨차 페널티 적용).
function worldKill(dispatcher: nkruntime.MatchDispatcher, state: WorldState, m: WMonster): void {
  let total = 0;
  for (const uid in m.ledger) total += m.ledger[uid];
  const boss = W_BOSS[m.t] === true;
  const baseGold = worldBaseGold(m.lv) * (boss ? 10 : (m.el ? 4 : 1));
  const expTypeMult = boss ? 10 : (m.el ? 5 : 1); // 보스 ×10, 엘리트 ×5
  const baseExp = wMonsterExp(m.lv) * expTypeMult;
  if (total > 0) {
    for (const uid in m.ledger) {
      const p = state.players[uid];
      if (!p) continue;
      const frac = m.ledger[uid] / total;
      // 레벨차 페널티: |내레벨-몬레벨| 10 이하=1.0, 20 이상=0.0.
      const diff = Math.abs(p.level - m.lv);
      const diffMult = Math.max(0, Math.min(1, (20 - diff) / 10));
      const reward = {
        g: Math.round(baseGold * frac),
        e: Math.round(baseExp * diffMult * frac),
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

// 몬스터→플레이어 피해 산정(클라 resolveDamage 와 동일 공식).
// 몬스터 공격/관통은 레벨·엘리트 배수로 스케일(클라 stats.scaled(scaleForLevel(lv) * (elite?1.8:1))).
function wPlayerDamage(m: WMonster, p: WPlayer): { amount: number; crit: boolean } {
  const def = W_POOL_BY_ID[m.t];
  const base = def || { atk: 12, ap: 0, cc: 0.05, cm: 1.5, id: '', hp: 0, min: 0, max: 0 };
  const scale = (1 + (m.lv - 1) * 0.14) * (m.el ? 1.8 : 1.0);
  const atk = base.atk * scale;
  const ap = base.ap * scale;
  const effDef = Math.max(0, p.def - ap);
  let raw = atk - effDef;
  if (raw < 1) raw = 1;
  const crit = Math.random() < base.cc;
  if (crit) raw *= base.cm <= 0 ? 1.5 : base.cm;
  return { amount: Math.round(raw), crit: crit };
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
      // 유저 입력 즉시 접수 → 다음 틱 브로드캐스트에 반영.
      const p = state.players[uid];
      if (p) {
        p.x = Number(data.x) || p.x;
        p.y = Number(data.y) || p.y;
        p.vx = Number(data.vx) || 0;
        p.vy = Number(data.vy) || 0;
        p.level = Number(data.l) || p.level;
        if (data.df != null) p.def = Number(data.df) || 0;
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
    } else if (msg.opCode === WorldOp.ITEM_DROP) {
      // 소유권 없는 월드 드랍(서버가 보관 → 전원이 스냅샷으로 봄).
      const did = 'd' + state.nextDropId++;
      state.drops[did] = {
        id: did,
        item: String(data.item || ''),
        r: Number(data.r) || 0,
        n: String(data.n || '아이템'),
        x: Number(data.x) || 0,
        y: Number(data.y) || 0,
        ts: Date.now(),
      };
    } else if (msg.opCode === WorldOp.ITEM_PICKUP) {
      // 원자적 줍기: 서버 루프가 메시지를 순차 처리하므로 동시 요청 중 첫 1명만 성공(복제 불가).
      const d = state.drops[String(data.id)];
      if (d) {
        delete state.drops[String(data.id)];
        dispatcher.broadcastMessage(WorldOp.ITEM_GRANT, JSON.stringify({ item: d.item }), [msg.sender], null, true);
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
      const spd = 90; // px/s
      m.vx = ((np.x - m.x) / d) * spd;
      m.vy = ((np.y - m.y) / d) * spd;
      m.x += m.vx / W_TICK; // px/tick
      m.y += m.vy / W_TICK;
      m.st = 1;
    } else {
      m.vx = 0;
      m.vy = 0;
      m.st = 0;
    }
  }

  // 2.5) 몬스터→플레이어 근접 피해(서버 권위). 무적/안전지대가 아니면 사거리 안 몬스터 1체가
  //      초당 1회 피해를 가하고, 그 피해를 전원에게 브로드캐스트(모든 클라가 데미지·피격 표시).
  const nowMs = Date.now();
  for (const uid in state.players) {
    const p = state.players[uid];
    if (wInSafe(p.x, p.y) || nowMs < p.invulnUntil) continue;
    for (const k in state.monsters) {
      const mo = state.monsters[k];
      if (worldDist(mo.x, mo.y, p.x, p.y) <= W_MELEE) {
        const hit = wPlayerDamage(mo, p);
        p.invulnUntil = nowMs + W_INVULN_MS;
        dispatcher.broadcastMessage(
          WorldOp.PLAYER_DMG,
          JSON.stringify({ u: uid, mid: mo.id, dmg: hit.amount, crit: hit.crit }),
          null,
          null,
          true,
        );
        break; // 한 틱에 한 번만 피해
      }
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

  // 4) 고정 틱마다 스냅샷 브로드캐스트(50ms = 20Hz). 위치는 비신뢰(unreliable) 전송.
  state.tick++;
  const m: any[] = [];
  for (const k in state.monsters) {
    const mo = state.monsters[k];
    m.push({
      id: mo.id, t: mo.t,
      x: Math.round(mo.x), y: Math.round(mo.y),
      vx: Math.round(mo.vx), vy: Math.round(mo.vy),
      hp: mo.hp, mhp: mo.mhp, lv: mo.lv, el: mo.el, st: mo.st,
    });
  }
  const pl: any[] = [];
  for (const uid in state.players) {
    const p = state.players[uid];
    pl.push({
      u: uid, x: Math.round(p.x), y: Math.round(p.y),
      vx: Math.round(p.vx), vy: Math.round(p.vy), l: p.level, n: p.name,
    });
  }
  // 드랍 아이템(소유권 없음) — 오래된 것 회수 후 표시용 최소 정보만 브로드캐스트.
  const dropNow = Date.now();
  const dr: any[] = [];
  for (const k in state.drops) {
    const o = state.drops[k];
    if (dropNow - o.ts > 180000) {
      delete state.drops[k];
      continue;
    }
    dr.push({ id: o.id, x: o.x, y: o.y, r: o.r, n: o.n });
  }
  dispatcher.broadcastMessage(WorldOp.SNAPSHOT, JSON.stringify({ tk: state.tick, m: m, p: pl, d: dr }), null, null, false);

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
