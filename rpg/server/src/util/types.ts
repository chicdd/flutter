// 공통 타입/헬퍼. Nakama 런타임 타입은 @heroiclabs/nakama-runtime 가 전역 nkruntime 으로 제공.

interface DropResult {
  template_id: string;
  quantity: number;
  item_id?: string;
  stackable?: boolean;
}

interface CreateInstanceResponse {
  run_seed: number;
  biome: string;
  monsters: InstanceMonster[];
}

interface InstanceMonster {
  idx: number;
  template_id: string; // monster_templates.id
  x: number;
  y: number;
  hp: number;
}

// 표준 에러 응답.
function errResponse(message: string, code = 'error'): string {
  return JSON.stringify({ ok: false, code, error: message });
}

function okResponse(data: Record<string, unknown>): string {
  // 주의: 객체 스프레드(...data)를 쓰면 tsc(es5)가 __assign 헬퍼를 주입하는데,
  // 이 헬퍼의 자기재할당이 Goja 에서 "read only property" 로 터진다. 수동 복사로 회피.
  var out: Record<string, unknown> = { ok: true };
  for (var k in data) {
    if (Object.prototype.hasOwnProperty.call(data, k)) {
      out[k] = data[k];
    }
  }
  return JSON.stringify(out);
}

// payload 파싱(빈 문자열 허용).
function parsePayload<T>(payload: string): T {
  if (!payload) return {} as T;
  return JSON.parse(payload) as T;
}
