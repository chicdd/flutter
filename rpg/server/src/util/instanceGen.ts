// 인스턴스 몬스터 레이아웃 결정론적 생성.
// 서버 권위: 클라이언트는 createInstance 가 돌려준 좌표/몬스터를 그대로 렌더링한다.
// reportKill 은 영속 저장 없이 (seed, idx) 로 몬스터 템플릿을 재도출해야 하므로
// 이 함수는 서버 내부에서 결정론적이어야 한다(같은 seed → 같은 배치).
//
// MONSTER_POOL 의 hp 는 db/seed/0001_seed.sql 의 monster_templates 와 일치시킬 것.

interface GenMonster {
  idx: number;
  template_id: string;
  x: number;
  y: number;
  hp: number;
}

const MONSTER_POOL: { template_id: string; hp: number; weight: number }[] = [
  { template_id: 'slime', hp: 30, weight: 50 },
  { template_id: 'goblin', hp: 60, weight: 35 },
  { template_id: 'skeleton', hp: 90, weight: 15 },
];

const WORLD_W = 2000;
const WORLD_H = 2000;
const DEFAULT_COUNT = 12;

// 32비트 결정론적 PRNG (mulberry32).
function mulberry32(a: number) {
  return function () {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// 큰 시드(최대 2^52)를 32비트로 폴딩.
function fold32(seed: number): number {
  const lo = seed >>> 0;
  const hi = Math.floor(seed / 0x100000000) >>> 0;
  return (lo ^ hi) >>> 0;
}

function pickFromPool(r: number): { template_id: string; hp: number } {
  let total = 0;
  for (const m of MONSTER_POOL) total += m.weight;
  let acc = r * total;
  for (const m of MONSTER_POOL) {
    acc -= m.weight;
    if (acc <= 0) return { template_id: m.template_id, hp: m.hp };
  }
  return { template_id: MONSTER_POOL[0].template_id, hp: MONSTER_POOL[0].hp };
}

function generateMonsters(seed: number, count: number = DEFAULT_COUNT): GenMonster[] {
  const rng = mulberry32(fold32(seed));
  const out: GenMonster[] = [];
  for (let i = 0; i < count; i++) {
    const pick = pickFromPool(rng());
    out.push({
      idx: i,
      template_id: pick.template_id,
      x: Math.floor(rng() * WORLD_W),
      y: Math.floor(rng() * WORLD_H),
      hp: pick.hp,
    });
  }
  return out;
}

// (seed, idx) → 해당 몬스터. 범위 밖이면 null.
function monsterAt(seed: number, idx: number, count: number = DEFAULT_COUNT): GenMonster | null {
  if (idx < 0 || idx >= count) return null;
  return generateMonsters(seed, count)[idx];
}
