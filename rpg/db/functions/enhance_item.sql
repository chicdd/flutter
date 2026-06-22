-- ============================================================================
-- enhance_item(p_user, p_item, p_scroll_template, p_success, p_idem) — §7
-- 주문서 1 소모. 성공 시 enhance_level+1, 실패 시 룰대로(MVP: 유지).
-- RNG 결과(p_success)는 Nakama 가 결정해 전달(§3.5).
-- 트랜잭션 + ledger + idempotency_key.
--
-- 실패 룰(§13 미해결)은 MVP 에서 "유지"로 결정. 등급하락/파괴는 TODO.
-- ============================================================================

create or replace function enhance_item(
  p_user            uuid,
  p_item            uuid,
  p_scroll_template text,
  p_success         boolean,
  p_idem            text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner       uuid;
  v_template    text;
  v_enhance     int;
  v_max_enhance int;
  v_scroll_id   uuid;
  v_new_level   int;
begin
  if econ_already_done(p_idem) then
    return jsonb_build_object('ok', true, 'idempotent', true);
  end if;

  -- 대상 아이템 소유/상태 검증 (FOR UPDATE 로 잠금).
  select i.owner_id, i.template_id, i.enhance_level, t.max_enhance
    into v_owner, v_template, v_enhance, v_max_enhance
    from items i
    join item_templates t on t.id = i.template_id
   where i.id = p_item
   for update;

  if v_owner is null then
    raise exception 'enhance_item: item % not found', p_item;
  end if;
  if v_owner <> p_user then
    raise exception 'enhance_item: not owner';
  end if;
  if v_enhance >= v_max_enhance then
    raise exception 'enhance_item: already at max enhance %', v_max_enhance;
  end if;

  -- 주문서 1개 소모 (인벤토리의 해당 템플릿 스택).
  select id into v_scroll_id
    from items
   where owner_id = p_user
     and template_id = p_scroll_template
     and location = 'inventory'
     and quantity >= 1
   limit 1
   for update;

  if v_scroll_id is null then
    raise exception 'enhance_item: no scroll % in inventory', p_scroll_template;
  end if;

  update items set quantity = quantity - 1, updated_at = now() where id = v_scroll_id;
  delete from items where id = v_scroll_id and quantity <= 0;

  -- 성공/실패 적용. MVP 실패 룰 = 유지.
  if p_success then
    v_new_level := v_enhance + 1;
    update items set enhance_level = v_new_level, updated_at = now() where id = p_item;
  else
    v_new_level := v_enhance; -- TODO(§13): 하락/파괴 룰 결정
  end if;

  insert into ledger (kind, actor_id, item_id, template_id, quantity, gold_delta, idempotency_key, meta)
  values ('enhance', p_user, p_item, v_template, 0, 0, p_idem,
          jsonb_build_object('success', p_success, 'from', v_enhance, 'to', v_new_level, 'scroll', p_scroll_template));

  return jsonb_build_object(
    'ok', true,
    'idempotent', false,
    'success', p_success,
    'item_id', p_item,
    'enhance_level', v_new_level
  );
end;
$$;
