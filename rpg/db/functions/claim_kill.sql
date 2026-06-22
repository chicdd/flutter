-- ============================================================================
-- claim_kill(p_seed, p_idx, p_owner, p_monster) — 킬 이중청구 차단 + 루트 테이블 조회 (§6.1)
-- kill_claims PK(run_seed, monster_idx, owner_id) 로 멱등 보장.
-- 이미 청구된 킬이면 {ok:false, reason:'already_claimed'} 반환.
-- 신규면 해당 몬스터의 loot_table 엔트리를 반환(서버가 RNG 로 롤).
-- ============================================================================

create or replace function claim_kill(
  p_seed    bigint,
  p_idx     int,
  p_owner   uuid,
  p_monster text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_inserted int;
  v_loot     text;
begin
  insert into kill_claims (run_seed, monster_idx, owner_id)
  values (p_seed, p_idx, p_owner)
  on conflict (run_seed, monster_idx, owner_id) do nothing;

  get diagnostics v_inserted = row_count;
  if v_inserted = 0 then
    return jsonb_build_object('ok', false, 'reason', 'already_claimed');
  end if;

  select loot_table into v_loot from monster_templates where id = p_monster;
  if v_loot is null then
    raise exception 'claim_kill: unknown monster %', p_monster;
  end if;

  return jsonb_build_object(
    'ok', true,
    'loot_table', v_loot,
    'entries', coalesce((
      select jsonb_agg(jsonb_build_object(
        'template_id', template_id,
        'weight', weight,
        'min_qty', min_qty,
        'max_qty', max_qty
      ))
      from loot_entries where loot_table = v_loot
    ), '[]'::jsonb)
  );
end;
$$;
