-- ============================================================================
-- execute_trade(p_trade_id, p_idem) — §7
-- trades.state='confirmed' 확인 → 양측 아이템 소유권 교환 + 골드 정산
--   + location='inventory' → 'completed'. 단일 트랜잭션, 부분 성공 불가(§3.6).
-- 거래 상태머신/에스크로 진입은 Nakama match handler(§6.2)가 소유.
-- 이 함수는 confirmed 상태의 최종 원자 스왑만 책임진다.
-- ============================================================================

create or replace function execute_trade(
  p_trade_id uuid,
  p_idem     text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_a       uuid;
  v_b       uuid;
  v_state   text;
  v_a_items jsonb;
  v_b_items jsonb;
  v_a_gold  bigint;
  v_b_gold  bigint;
  v_gold_a  bigint;
  v_gold_b  bigint;
  v_item    uuid;
begin
  if econ_already_done(p_idem) then
    return jsonb_build_object('ok', true, 'idempotent', true);
  end if;

  select a_id, b_id, state, a_items, b_items, a_gold, b_gold
    into v_a, v_b, v_state, v_a_items, v_b_items, v_a_gold, v_b_gold
    from trades
   where id = p_trade_id
   for update;

  if v_a is null then raise exception 'execute_trade: trade not found'; end if;
  if v_state <> 'confirmed' then raise exception 'execute_trade: trade not confirmed (%).', v_state; end if;

  -- 골드 검증 + 잠금.
  select gold into v_gold_a from profiles where id = v_a for update;
  select gold into v_gold_b from profiles where id = v_b for update;
  if v_gold_a < v_a_gold then raise exception 'execute_trade: A insufficient gold'; end if;
  if v_gold_b < v_b_gold then raise exception 'execute_trade: B insufficient gold'; end if;

  -- 아이템 escrow 무결성 검증: A가 내놓은 아이템은 A 소유 + trade_escrow 여야 함.
  for v_item in select (value)::uuid from jsonb_array_elements_text(v_a_items) loop
    if not exists (select 1 from items where id = v_item and owner_id = v_a and location = 'trade_escrow') then
      raise exception 'execute_trade: A item % not in escrow', v_item;
    end if;
  end loop;
  for v_item in select (value)::uuid from jsonb_array_elements_text(v_b_items) loop
    if not exists (select 1 from items where id = v_item and owner_id = v_b and location = 'trade_escrow') then
      raise exception 'execute_trade: B item % not in escrow', v_item;
    end if;
  end loop;

  -- 아이템 소유권 교환: A→B, B→A. 전부 inventory 로 복귀.
  update items set owner_id = v_b, location = 'inventory', updated_at = now()
   where id in (select (value)::uuid from jsonb_array_elements_text(v_a_items));
  update items set owner_id = v_a, location = 'inventory', updated_at = now()
   where id in (select (value)::uuid from jsonb_array_elements_text(v_b_items));

  -- 골드 정산.
  update profiles set gold = gold - v_a_gold + v_b_gold where id = v_a;
  update profiles set gold = gold - v_b_gold + v_a_gold where id = v_b;

  update trades set state = 'completed', completed_at = now() where id = p_trade_id;

  insert into ledger (kind, actor_id, counterparty_id, gold_delta, idempotency_key, meta)
  values ('trade', v_a, v_b, v_b_gold - v_a_gold, p_idem,
          jsonb_build_object('trade_id', p_trade_id, 'a_items', v_a_items, 'b_items', v_b_items,
                             'a_gold', v_a_gold, 'b_gold', v_b_gold));

  return jsonb_build_object('ok', true, 'idempotent', false, 'trade_id', p_trade_id);
end;
$$;
