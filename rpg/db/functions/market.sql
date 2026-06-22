-- ============================================================================
-- market.sql — 마켓보드 트랜잭션 (§7)
--   create_listing(p_seller, p_item, p_price, p_idem)
--   buy_listing(p_buyer, p_listing, p_idem)        -- 원자 스왑
--   cancel_listing(p_seller, p_listing, p_idem)
-- 모두 SECURITY DEFINER + 트랜잭션 + ledger + idempotency_key.
-- 에스크로는 행 삭제 대신 items.location 전환(§5.2 감사 추적).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- create_listing: 소유·tradable·bound 검증 → items.location='market_escrow' → 리스팅 생성.
-- ----------------------------------------------------------------------------
create or replace function create_listing(
  p_seller uuid,
  p_item   uuid,
  p_price  bigint,
  p_idem   text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner    uuid;
  v_bound    boolean;
  v_location text;
  v_template text;
  v_tradable boolean;
  v_listing  uuid;
begin
  if econ_already_done(p_idem) then
    return jsonb_build_object('ok', true, 'idempotent', true);
  end if;
  if p_price is null or p_price <= 0 then
    raise exception 'create_listing: price must be > 0';
  end if;

  select i.owner_id, i.bound, i.location, i.template_id, t.tradable
    into v_owner, v_bound, v_location, v_template, v_tradable
    from items i join item_templates t on t.id = i.template_id
   where i.id = p_item
   for update;

  if v_owner is null then raise exception 'create_listing: item not found'; end if;
  if v_owner <> p_seller then raise exception 'create_listing: not owner'; end if;
  if v_location <> 'inventory' then raise exception 'create_listing: item not in inventory (%).', v_location; end if;
  if v_bound or not v_tradable then raise exception 'create_listing: item not tradable'; end if;

  update items set location = 'market_escrow', updated_at = now() where id = p_item;

  insert into market_listings (seller_id, item_id, price)
  values (p_seller, p_item, p_price)
  returning id into v_listing;

  insert into ledger (kind, actor_id, item_id, template_id, gold_delta, idempotency_key, meta)
  values ('market_list', p_seller, p_item, v_template, 0, p_idem,
          jsonb_build_object('listing_id', v_listing, 'price', p_price));

  return jsonb_build_object('ok', true, 'idempotent', false, 'listing_id', v_listing);
end;
$$;

-- ----------------------------------------------------------------------------
-- buy_listing: 골드 검증 → 구매자 차감/판매자 가산 → 소유권 이전 + location='inventory'
--              → 리스팅 'sold'. 단일 트랜잭션 원자 스왑(§3.6).
-- ----------------------------------------------------------------------------
create or replace function buy_listing(
  p_buyer   uuid,
  p_listing uuid,
  p_idem    text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_seller  uuid;
  v_item    uuid;
  v_price   bigint;
  v_status  text;
  v_gold    bigint;
  v_template text;
begin
  if econ_already_done(p_idem) then
    return jsonb_build_object('ok', true, 'idempotent', true);
  end if;

  select seller_id, item_id, price, status
    into v_seller, v_item, v_price, v_status
    from market_listings
   where id = p_listing
   for update;

  if v_seller is null then raise exception 'buy_listing: listing not found'; end if;
  if v_status <> 'active' then raise exception 'buy_listing: listing not active (%).', v_status; end if;
  if v_seller = p_buyer then raise exception 'buy_listing: cannot buy own listing'; end if;

  -- 구매자 골드 잠금/검증.
  select gold into v_gold from profiles where id = p_buyer for update;
  if v_gold is null then raise exception 'buy_listing: buyer profile not found'; end if;
  if v_gold < v_price then raise exception 'buy_listing: insufficient gold'; end if;

  select template_id into v_template from items where id = v_item;

  -- 원자 스왑.
  update profiles set gold = gold - v_price where id = p_buyer;
  update profiles set gold = gold + v_price where id = v_seller;
  update items
     set owner_id = p_buyer, location = 'inventory', updated_at = now()
   where id = v_item;
  update market_listings
     set status = 'sold', buyer_id = p_buyer
   where id = p_listing;

  insert into ledger (kind, actor_id, counterparty_id, item_id, template_id, gold_delta, idempotency_key, meta)
  values ('market_buy', p_buyer, v_seller, v_item, v_template, -v_price, p_idem,
          jsonb_build_object('listing_id', p_listing, 'price', v_price));

  return jsonb_build_object('ok', true, 'idempotent', false, 'item_id', v_item, 'price', v_price);
end;
$$;

-- ----------------------------------------------------------------------------
-- cancel_listing: 본인 확인 → 에스크로 복귀(location='inventory') → 리스팅 'cancelled'.
-- ----------------------------------------------------------------------------
create or replace function cancel_listing(
  p_seller  uuid,
  p_listing uuid,
  p_idem    text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_seller uuid;
  v_item   uuid;
  v_status text;
  v_template text;
begin
  if econ_already_done(p_idem) then
    return jsonb_build_object('ok', true, 'idempotent', true);
  end if;

  select seller_id, item_id, status
    into v_seller, v_item, v_status
    from market_listings
   where id = p_listing
   for update;

  if v_seller is null then raise exception 'cancel_listing: listing not found'; end if;
  if v_seller <> p_seller then raise exception 'cancel_listing: not owner'; end if;
  if v_status <> 'active' then raise exception 'cancel_listing: listing not active (%).', v_status; end if;

  select template_id into v_template from items where id = v_item;

  update items set location = 'inventory', updated_at = now() where id = v_item;
  update market_listings set status = 'cancelled' where id = p_listing;

  insert into ledger (kind, actor_id, item_id, template_id, gold_delta, idempotency_key, meta)
  values ('market_cancel', p_seller, v_item, v_template, 0, p_idem,
          jsonb_build_object('listing_id', p_listing));

  return jsonb_build_object('ok', true, 'idempotent', false, 'item_id', v_item);
end;
$$;
