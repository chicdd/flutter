-- ============================================================================
-- reset.sql — public 스키마 전체 초기화 (테이블/함수/인덱스/시드 모두 삭제)
--
-- ⚠️ 경고: public 스키마의 "모든" 객체를 지운다. 이 RPG 프로젝트 전용 DB 에서만 실행할 것.
--   - 우리 테이블/함수/시드가 전부 public 에 있으므로 한 방에 깨끗이 비워진다.
--   - 확장(pgcrypto 등)은 보통 extensions 스키마에 있어 영향받지 않는다.
--   - auth/storage 등 Supabase 관리 스키마는 건드리지 않는다(public 만 리셋).
--
-- 실행 후 db/README.md 의 적용 순서대로 다시 마이그레이션하면 깨끗한 재시작.
-- ============================================================================

drop schema public cascade;
create schema public;

-- Supabase 기본 권한 복구 (스키마 드롭 시 함께 사라지므로 반드시 재부여).
grant usage on schema public to postgres, anon, authenticated, service_role;
grant all on all tables    in schema public to postgres, anon, authenticated, service_role;
grant all on all routines  in schema public to postgres, anon, authenticated, service_role;
grant all on all sequences in schema public to postgres, anon, authenticated, service_role;

alter default privileges in schema public grant all on tables    to postgres, anon, authenticated, service_role;
alter default privileges in schema public grant all on routines  to postgres, anon, authenticated, service_role;
alter default privileges in schema public grant all on sequences to postgres, anon, authenticated, service_role;

comment on schema public is 'standard public schema';
