-- ============================================================================
-- grant_drop(p_user, p_template, p_qty, p_idem) — §7
-- 드랍 보상 지급. 스택형이면 수량 증가/행 생성, 장비면 신규 인스턴스 생성.
-- 트랜잭션 + ledger append + idempotency_key UNIQUE 보호.
-- 권위 불변식(§3.1): 아이템 생성(mint)은 오직 이 서버 경로로만.
-- ============================================================================

create or replace function grant_drop(
  p_user     uuid,
  p_template text,
  p_qty      int,
  p_idem     text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_stackable boolean;
  v_item_id   uuid;
  v_existing  uuid;
begin
  -- 멱등: 이미 처리된 요청이면 무시.
  if econ_already_done(p_idem) then
    return jsonb_build_object('ok', true, 'idempotent', true);
  end if;

  if p_qty is null or p_qty < 1 then
    raise exception 'grant_drop: invalid quantity %', p_qty;
  end if;

  select stackable into v_stackable from item_templates where id = p_template;
  if v_stackable is null then
    raise exception 'grant_drop: unknown template %', p_template;
  end if;

  if v_stackable then
    -- 스택형: 인벤토리에 기존 스택 있으면 수량 증가, 없으면 생성.
    select id into v_existing
      from items
     where owner_id = p_user
       and template_id = p_template
       and location = 'inventory'
       and bound = false
     limit 1;

    if v_existing is not null then
      update items
         set quantity = quantity + p_qty, updated_at = now()
       where id = v_existing
       returning id into v_item_id;
    else
      insert into items (owner_id, template_id, quantity)
      values (p_user, p_template, p_qty)
      returning id into v_item_id;
    end if;
  else
    -- 장비/비스택: 신규 고유 인스턴스.
    insert into items (owner_id, template_id, quantity)
    values (p_user, p_template, 1)
    returning id into v_item_id;
  end if;

  insert into ledger (kind, actor_id, item_id, template_id, quantity, gold_delta, idempotency_key, meta)
  values ('drop', p_user, v_item_id, p_template, p_qty, 0, p_idem, '{}'::jsonb);

  return jsonb_build_object(
    'ok', true,
    'idempotent', false,
    'item_id', v_item_id,
    'template_id', p_template,
    'quantity', p_qty,
    'stackable', v_stackable
  );
end;
$$;
