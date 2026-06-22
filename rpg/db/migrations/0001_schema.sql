-- ============================================================================
-- 0001_schema.sql — 2D 인스턴스 RPG 코어 스키마 (§5)
-- 시스템 오브 레코드: 프로필/지갑, 아이템, 마켓, 거래, 원장, 인스턴스/드랍.
-- 권위 불변식(§3) 준수: 모든 경제 쓰기는 service_role(Nakama) 경유 SECURITY DEFINER 함수로만.
-- ============================================================================

create extension if not exists pgcrypto; -- gen_random_uuid()

-- ----------------------------------------------------------------------------
-- 5.1 프로필 / 지갑
-- ----------------------------------------------------------------------------
create table if not exists profiles (
  id            uuid primary key,              -- = Nakama user_id
  display_name  text not null,
  gold          bigint not null default 0 check (gold >= 0),
  created_at    timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- 5.2 아이템 정의 / 인스턴스
-- ----------------------------------------------------------------------------
create table if not exists item_templates (
  id          text primary key,                -- 예: 'sword_iron', 'scroll_enhance_t1'
  name        text not null,
  type        text not null check (type in ('equipment','consumable','scroll','misc')),
  slot        text,                            -- equipment 전용: 'weapon','armor',...
  rarity      text not null default 'common',
  stackable   boolean not null default false,
  max_enhance int not null default 0,          -- equipment 전용
  tradable    boolean not null default true,
  base_price  bigint not null default 0,
  base_stats  jsonb not null default '{}'::jsonb
);

-- 소유된 아이템 인스턴스 (장비=고유, 스택형=수량)
create table if not exists items (
  id            uuid primary key default gen_random_uuid(),
  owner_id      uuid not null references profiles(id),
  template_id   text not null references item_templates(id),
  quantity      int not null default 1 check (quantity >= 1),
  enhance_level int not null default 0,
  bound         boolean not null default false,  -- true = 거래 불가(소울바운드)
  location      text not null default 'inventory'
                check (location in ('inventory','market_escrow','trade_escrow')),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create index if not exists items_owner_location_idx on items(owner_id, location);

-- ----------------------------------------------------------------------------
-- 5.3 마켓보드 / 거래 / 원장
-- ----------------------------------------------------------------------------
create table if not exists market_listings (
  id          uuid primary key default gen_random_uuid(),
  seller_id   uuid not null references profiles(id),
  item_id     uuid not null references items(id),   -- location='market_escrow'
  price       bigint not null check (price > 0),
  status      text not null default 'active'
              check (status in ('active','sold','cancelled','expired')),
  buyer_id    uuid references profiles(id),
  created_at  timestamptz not null default now(),
  expires_at  timestamptz
);
create index if not exists market_listings_status_price_idx on market_listings(status, price);

create table if not exists trades (
  id          uuid primary key default gen_random_uuid(),
  a_id        uuid not null references profiles(id),
  b_id        uuid not null references profiles(id),
  state       text not null default 'open'
              check (state in ('open','locked','confirmed','completed','cancelled')),
  a_items     jsonb not null default '[]'::jsonb,    -- item id 배열
  b_items     jsonb not null default '[]'::jsonb,
  a_gold      bigint not null default 0,
  b_gold      bigint not null default 0,
  a_locked    boolean not null default false,
  b_locked    boolean not null default false,
  a_confirmed boolean not null default false,
  b_confirmed boolean not null default false,
  created_at  timestamptz not null default now(),
  completed_at timestamptz
);

-- 모든 아이템/골드 이동의 감사 원장 (§3.4)
create table if not exists ledger (
  id              bigserial primary key,
  kind            text not null,   -- 'drop','enhance','market_list','market_buy','market_cancel','trade'
  actor_id        uuid references profiles(id),
  counterparty_id uuid references profiles(id),
  item_id         uuid,
  template_id     text,
  quantity        int,
  gold_delta      bigint,
  idempotency_key text unique not null,
  meta            jsonb not null default '{}'::jsonb,
  created_at      timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- 5.4 인스턴스 / 몬스터 / 드랍
-- ----------------------------------------------------------------------------
create table if not exists monster_templates (
  id         text primary key,
  name       text not null,
  hp         int not null,
  loot_table text not null
);

create table if not exists loot_entries (
  id           bigserial primary key,
  loot_table   text not null,
  template_id  text not null references item_templates(id),
  weight       int not null check (weight > 0),
  min_qty      int not null default 1,
  max_qty      int not null default 1
);
create index if not exists loot_entries_table_idx on loot_entries(loot_table);

-- 킬 이중 청구 방지용 (인스턴스 시드 + 몬스터 인덱스 단위)
create table if not exists kill_claims (
  run_seed    bigint not null,
  monster_idx int not null,
  owner_id    uuid not null references profiles(id),
  claimed_at  timestamptz not null default now(),
  primary key (run_seed, monster_idx, owner_id)
);
