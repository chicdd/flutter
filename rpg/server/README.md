# /server — Nakama TypeScript 권위 런타임 (§6)

Nakama 가 **권위·검증·RNG·실시간 세션**을 담당한다. 실제 경제 데이터 변경은
Supabase 의 SECURITY DEFINER 함수(`/db/functions`)에서 원자적으로 일어난다(§3, §4).

## 구성

```
src/
  main.ts              # InitModule: RPC/매치/인증훅 등록
  rpc/
    createInstance.ts  # rpc_create_instance — 시드 생성 + 몬스터 레이아웃
    reportKill.ts      # rpc_report_kill   — 이중청구 차단 + 루트 롤(RNG) + grant_drop
    enhanceItem.ts     # rpc_enhance_item  — 성공 RNG + enhance_item
    market.ts          # rpc_list/buy/cancel
    inventory.ts       # rpc_get_inventory / rpc_browse_market (read)
  match/tradeHandler.ts # 실시간 P2P 거래 상태머신 (Phase 4 골격)
  supabase/client.ts   # service_role 로 PostgREST RPC 호출
  util/                # rng, instanceGen(결정론적 몬스터), rateLimit, types
types/nakama-runtime.d.ts # 벤더링한 nkruntime 타입 (heroiclabs/nakama-common)
```

> `types/nakama-runtime.d.ts` 는 npm 패키지가 아니라 nakama-common 저장소의 `index.d.ts` 를
> 벤더링한 것이다(작성 시점 npm 미배포). 갱신: 해당 저장소 루트의 `index.d.ts` 를 덮어쓰면 된다.

## 빌드 (Node 필요, Docker 불필요)

```bash
cd server
npm install
npm run typecheck   # tsc --noEmit
npm run build       # rollup → build/index.js (Goja 가 로드하는 단일 번들)
```

Nakama JS 런타임은 Goja(단일 JS) 위에서 돈다 → rollup 으로 한 파일에 번들한다.
`main.ts` 끝의 `!InitModule && InitModule.bind(null)` 은 tree-shaking 방지용(공식 패턴).

## 실행 (Docker 필요)

```bash
cp .env.example .env        # SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY 채우기
npm run build               # build/index.js 먼저 생성
docker compose up           # Nakama(7350) + Postgres + Console(7351)
```

- Nakama Console: http://localhost:7351 (기본 admin / password)
- Dart 클라이언트는 HTTP API 포트 **7350** 으로 접속.
- `SUPABASE_*` 는 `.env` → compose 의 `--runtime.env` 로 주입되어 런타임 `ctx.env` 에 노출된다.

> 현재 개발 머신에 Docker 가 없으면 빌드까지만 가능하다. Docker Desktop 설치 후 위 명령으로 기동.

## RPC 빠른 점검

기동 후 hello RPC 로 런타임 로딩 확인:

```bash
# 1) 디바이스 인증으로 세션 토큰 얻기
curl -s "http://127.0.0.1:7350/v2/account/authenticate/device?create=true" \
  -H "Authorization: Basic ZGVmYXVsdGtleTo=" \
  -H "Content-Type: application/json" \
  -d '{"id":"00000000-0000-0000-0000-000000000001"}'
# → access_token 복사

# 2) hello RPC
curl -s "http://127.0.0.1:7350/v2/rpc/rpc_hello" \
  -H "Authorization: Bearer <ACCESS_TOKEN>" \
  -H "Content-Type: application/json" -d '"{}"'
```

## RPC 카탈로그 (§6.1)

| RPC | 입력(JSON) | 비고 |
|---|---|---|
| `rpc_hello` | any | 헬스체크 |
| `rpc_create_instance` | `{biome?, monster_count?}` | seed + monsters[] 반환 |
| `rpc_report_kill` | `{run_seed, monster_idx}` | 드랍 판정(서버 RNG) |
| `rpc_enhance_item` | `{item_id, scroll_template, idempotency_key?}` | 강화 |
| `rpc_get_inventory` | `{}` | 인벤토리 read |
| `rpc_browse_market` | `{limit?, offset?}` | 마켓 read |
| `rpc_list_item` | `{item_id, price, idempotency_key?}` | 등록 |
| `rpc_buy_listing` | `{listing_id, idempotency_key?}` | 구매 |
| `rpc_cancel_listing` | `{listing_id, idempotency_key?}` | 취소 |
