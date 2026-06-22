// 서버 권위 RNG (§3.5). 드랍 가중 추첨 / 강화 성공 판정 / 시드 생성.
// MVP 는 Math.random(Goja 지원). provably-fair 가 필요하면 §13 대로 검증 시드 도입.

interface LootEntry {
  template_id: string;
  weight: number;
  min_qty: number;
  max_qty: number;
}

// 64비트에 가까운 양의 정수 시드. Postgres bigint 에 안전한 범위로 제한.
function makeSeed(): number {
  // 2^52 미만으로 제한해 JS number 정밀도 유지.
  return Math.floor(Math.random() * 9007199254740991);
}

function randInt(minInclusive: number, maxInclusive: number): number {
  return minInclusive + Math.floor(Math.random() * (maxInclusive - minInclusive + 1));
}

// 가중 추첨. 빈 테이블이면 null(=드랍 없음).
function rollLoot(entries: LootEntry[]): { template_id: string; quantity: number } | null {
  if (!entries || entries.length === 0) return null;
  let total = 0;
  for (const e of entries) total += e.weight;
  if (total <= 0) return null;

  let r = Math.random() * total;
  for (const e of entries) {
    r -= e.weight;
    if (r <= 0) {
      const qty = randInt(e.min_qty, e.max_qty);
      return { template_id: e.template_id, quantity: Math.max(1, qty) };
    }
  }
  // 부동소수 오차 보정.
  const last = entries[entries.length - 1];
  return { template_id: last.template_id, quantity: Math.max(1, randInt(last.min_qty, last.max_qty)) };
}

// 강화 성공 판정. rate 0~1.
function rollSuccess(rate: number): boolean {
  return Math.random() < rate;
}
