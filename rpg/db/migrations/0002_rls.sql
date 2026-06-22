-- ============================================================================
-- 0002_rls.sql — Row Level Security 방침 (§5.5)
-- 권위 불변식(§3.2): 클라이언트는 경제 테이블에 절대 직접 쓰지 않는다.
--   - 모든 INSERT/UPDATE/DELETE 는 service_role(Nakama) 만 가능.
--   - service_role 은 RLS 를 BYPASS 하므로 별도 정책 없이도 전권을 가진다.
--   - 따라서 RLS 를 켜고 "쓰기 정책을 만들지 않으면" anon/authenticated 쓰기는 전면 차단된다.
--   - 읽기는 MVP 에서 Nakama 경유로 통일(아래 read 정책은 주석으로 보존, 성능 필요 시 활성화).
-- ============================================================================

alter table profiles        enable row level security;
alter table items           enable row level security;
alter table item_templates  enable row level security;
alter table market_listings enable row level security;
alter table trades          enable row level security;
alter table ledger          enable row level security;
alter table monster_templates enable row level security;
alter table loot_entries    enable row level security;
alter table kill_claims     enable row level security;

-- 쓰기 정책 없음 → anon/authenticated 쓰기 전면 차단. service_role 만 통과.

-- ----------------------------------------------------------------------------
-- (선택) 읽기 전용 RLS — 성능이 필요할 때만 활성화.
-- MVP 기본은 Nakama RPC(rpc_browse_market / rpc_get_inventory) 경유 read 이므로 비활성.
-- 클라이언트가 Supabase read 전용 JWT 브리지(auth.uid() = profiles.id)를 쓸 때만 의미.
-- ----------------------------------------------------------------------------

-- 아이템 템플릿/루트/몬스터 정의는 공개 read 안전(경제값 아님).
-- create policy item_templates_read   on item_templates   for select using (true);
-- create policy monster_templates_read on monster_templates for select using (true);
-- create policy loot_entries_read     on loot_entries     for select using (true);

-- 본인 프로필/아이템만 read (auth.uid() 가 Nakama user_id 와 매핑된 경우).
-- create policy profiles_read_self on profiles for select using (auth.uid() = id);
-- create policy items_read_self    on items    for select using (auth.uid() = owner_id);

-- 활성 마켓 리스팅은 공개 브라우징 허용.
-- create policy market_active_read on market_listings for select using (status = 'active');
