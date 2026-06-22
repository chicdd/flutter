-- ============================================================================
-- 00_common.sql — 경제 함수 공통 헬퍼
-- 권위 불변식(§3.3): 모든 경제 변경은 멱등(idempotency_key UNIQUE). 동일 요청 2회 → 2번째 무시.
-- ============================================================================

-- 멱등 가드: 이미 처리된 idem 키면 true 반환(=호출자는 즉시 no-op 종료).
-- ledger 에 키가 존재하는지로 판정. 단일 트랜잭션 안에서 호출되어야 한다.
create or replace function econ_already_done(p_idem text)
returns boolean
language sql
stable
as $$
  select exists(select 1 from ledger where idempotency_key = p_idem);
$$;

-- 멱등 처리 결과를 담는 표준 반환 타입은 jsonb 로 통일한다.
-- 각 함수는 { "ok": bool, "idempotent": bool, ... } 형태를 반환.
