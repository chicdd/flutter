-- ============================================================================
-- 0001_seed.sql — MVP 시드 데이터 (item_templates, monster_templates, loot_entries)
-- 플레이스홀더 밸런스. §11 Phase 0 요구사항.
-- 재실행 안전(idempotent): on conflict do nothing/update.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 아이템 템플릿
-- ----------------------------------------------------------------------------
insert into item_templates (id, name, type, slot, rarity, stackable, max_enhance, tradable, base_price, base_stats) values
  ('sword_iron',     '철검',         'equipment', 'weapon', 'common',   false, 10, true,  100, '{"atk": 8}'),
  ('sword_steel',    '강철검',       'equipment', 'weapon', 'uncommon', false, 12, true,  300, '{"atk": 14}'),
  ('armor_leather',  '가죽 갑옷',     'equipment', 'armor',  'common',   false, 10, true,  90,  '{"def": 6}'),
  ('armor_iron',     '철 갑옷',       'equipment', 'armor',  'uncommon', false, 12, true,  280, '{"def": 11}'),
  ('potion_hp',      'HP 물약',       'consumable', null,    'common',   true,  0,  true,  20,  '{"heal": 50}'),
  ('scroll_enhance_t1', '강화주문서 T1', 'scroll',  null,    'common',   true,  0,  true,  150, '{"success_rate": 0.7}'),
  ('scroll_enhance_t2', '강화주문서 T2', 'scroll',  null,    'uncommon', true,  0,  true,  500, '{"success_rate": 0.5}'),
  ('junk_bone',      '뼛조각',       'misc',      null,     'common',   true,  0,  true,  3,   '{}')
on conflict (id) do update set
  name = excluded.name, type = excluded.type, slot = excluded.slot,
  rarity = excluded.rarity, stackable = excluded.stackable, max_enhance = excluded.max_enhance,
  tradable = excluded.tradable, base_price = excluded.base_price, base_stats = excluded.base_stats;

-- ----------------------------------------------------------------------------
-- 몬스터 템플릿
-- ----------------------------------------------------------------------------
insert into monster_templates (id, name, hp, loot_table) values
  ('slime',    '슬라임',   30,  'loot_slime'),
  ('goblin',   '고블린',   60,  'loot_goblin'),
  ('skeleton', '스켈레톤', 90,  'loot_skeleton')
on conflict (id) do update set
  name = excluded.name, hp = excluded.hp, loot_table = excluded.loot_table;

-- ----------------------------------------------------------------------------
-- 루트 테이블 (weight 가중 추첨, 서버 RNG 가 이 테이블을 롤)
-- 재실행 안전을 위해 loot_table 별로 지우고 재삽입.
-- ----------------------------------------------------------------------------
delete from loot_entries where loot_table in ('loot_slime','loot_goblin','loot_skeleton');

insert into loot_entries (loot_table, template_id, weight, min_qty, max_qty) values
  -- 슬라임: 쩌리 위주
  ('loot_slime',    'junk_bone',         60, 1, 2),
  ('loot_slime',    'potion_hp',         30, 1, 1),
  ('loot_slime',    'armor_leather',     10, 1, 1),
  -- 고블린: 중간
  ('loot_goblin',   'junk_bone',         40, 1, 3),
  ('loot_goblin',   'potion_hp',         30, 1, 2),
  ('loot_goblin',   'sword_iron',        20, 1, 1),
  ('loot_goblin',   'scroll_enhance_t1', 10, 1, 1),
  -- 스켈레톤: 좋은 편
  ('loot_skeleton', 'potion_hp',         30, 1, 2),
  ('loot_skeleton', 'sword_steel',       15, 1, 1),
  ('loot_skeleton', 'armor_iron',        15, 1, 1),
  ('loot_skeleton', 'scroll_enhance_t1', 25, 1, 1),
  ('loot_skeleton', 'scroll_enhance_t2', 15, 1, 1);
