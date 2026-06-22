-- ============================================================================
-- reads.sql — 읽기 전용 조회 함수 (Nakama read RPC 가 호출, §6.1)
-- 쓰기 아님. ledger/idempotency 불필요. SECURITY DEFINER 로 RLS 우회하되 인자로 범위 제한.
-- ============================================================================

-- 본인 인벤토리(에스크로 제외) + 프로필 골드.
create or replace function get_inventory(p_user uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'gold', coalesce((select gold from profiles where id = p_user), 0),
    'items', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', i.id,
        'template_id', i.template_id,
        'name', t.name,
        'type', t.type,
        'slot', t.slot,
        'rarity', t.rarity,
        'quantity', i.quantity,
        'enhance_level', i.enhance_level,
        'bound', i.bound,
        'location', i.location,
        'base_stats', t.base_stats
      ) order by i.created_at)
      from items i join item_templates t on t.id = i.template_id
      where i.owner_id = p_user and i.location = 'inventory'
    ), '[]'::jsonb)
  );
$$;

-- 활성 마켓 리스팅 브라우징(가격 오름차순, 페이지네이션).
create or replace function browse_market(p_limit int default 50, p_offset int default 0)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(jsonb_agg(to_jsonb(x)), '[]'::jsonb) from (
    select
      l.id as listing_id,
      l.price,
      l.seller_id,
      p.display_name as seller_name,
      i.id as item_id,
      i.template_id,
      t.name,
      t.rarity,
      i.enhance_level,
      i.quantity,
      l.created_at
    from market_listings l
    join items i on i.id = l.item_id
    join item_templates t on t.id = i.template_id
    join profiles p on p.id = l.seller_id
    where l.status = 'active'
    order by l.price asc
    limit greatest(1, least(p_limit, 200))
    offset greatest(0, p_offset)
  ) x;
$$;

-- 프로필 보장(없으면 생성). Nakama 첫 로그인 시 호출. 멱등.
create or replace function ensure_profile(p_user uuid, p_name text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into profiles (id, display_name)
  values (p_user, coalesce(nullif(p_name, ''), 'player_' || left(p_user::text, 8)))
  on conflict (id) do nothing;
  return jsonb_build_object('ok', true, 'gold', (select gold from profiles where id = p_user));
end;
$$;
