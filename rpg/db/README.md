# /db — Supabase (PostgreSQL) 시스템 오브 레코드

§3 권위 불변식: **클라이언트는 경제 테이블에 직접 쓰지 않는다.** 모든 경제 변경은
`Client → Nakama RPC → 여기의 SECURITY DEFINER 함수` 경로만 사용한다.

## 적용 순서

PSQL 또는 Supabase SQL Editor 에서 아래 순서로 실행:

```bash
# 환경변수: $DB = postgres 연결 문자열 (Supabase: Settings → Database → Connection string)
psql "$DB" -f migrations/0001_schema.sql
psql "$DB" -f migrations/0002_rls.sql
psql "$DB" -f functions/00_common.sql
psql "$DB" -f functions/grant_drop.sql
psql "$DB" -f functions/claim_kill.sql
psql "$DB" -f functions/enhance_item.sql
psql "$DB" -f functions/market.sql
psql "$DB" -f functions/execute_trade.sql
psql "$DB" -f functions/reads.sql
psql "$DB" -f seed/0001_seed.sql
```

또는 한 번에:

```bash
cat migrations/0001_schema.sql migrations/0002_rls.sql \
    functions/00_common.sql functions/grant_drop.sql functions/claim_kill.sql \
    functions/enhance_item.sql functions/market.sql functions/execute_trade.sql \
    functions/reads.sql seed/0001_seed.sql | psql "$DB"
```

> Windows PowerShell 에서는 `Get-Content` 로 연결하거나 Supabase 대시보드 SQL Editor 에 순서대로 붙여넣기.

## 함수 카탈로그 (§7)

| 함수 | 종류 | 멱등키 | 비고 |
|---|---|---|---|
| `grant_drop` | write | ✅ | 드랍 지급(mint). **Phase 1 동작.** |
| `claim_kill` | write | (PK) | 킬 이중청구 차단 + 루트 테이블 조회. **Phase 1 동작.** |
| `enhance_item` | write | ✅ | 강화. 성공여부는 Nakama RNG 가 전달. 실패룰=유지(MVP). |
| `create_listing` / `buy_listing` / `cancel_listing` | write | ✅ | 마켓 에스크로/원자 스왑. |
| `execute_trade` | write | ✅ | confirmed 거래 원자 스왑. |
| `get_inventory` / `browse_market` | read | — | Nakama read RPC 용. |
| `ensure_profile` | write | — | 첫 로그인 프로필 보장(멱등 upsert). |

## 멱등성

모든 write 함수 첫 줄에서 `econ_already_done(p_idem)` 체크 → 이미 처리된 키면 no-op.
`ledger.idempotency_key` 가 UNIQUE 라서 동시성 하에서도 2번째 INSERT 가 실패해 트랜잭션이 롤백된다.

## RLS

`0002_rls.sql` 로 모든 테이블 RLS 활성. **쓰기 정책을 만들지 않음** → service_role 만 통과.
클라이언트 직접 read 가 필요해지면 같은 파일의 주석 정책을 해제.
