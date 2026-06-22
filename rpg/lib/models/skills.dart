// 무기 전용 스킬 메타데이터. 실제 실행/이펙트는 RpgGame 이 SkillId 로 분기한다.
// 스킬 키: A S D F G H (현재 무기당 2개, 나머지 슬롯은 비활성).
import 'gear.dart';

enum SkillId {
  basicSlash,
  swordSwing,
  swordWhirl,
  spearThrust,
  spearSweep,
  bowDouble,
  bowBomb,
  axeSmash,
  axeWhirl,
  staffFireball,
  staffNova,
}

class SkillDef {
  final SkillId id;
  final String key; // 'A'..'H'
  final String name;
  final String desc;
  final double cooldown; // 초

  const SkillDef(this.id, this.key, this.name, this.desc, this.cooldown);
}

const List<String> skillKeys = ['A', 'S', 'D', 'F', 'G', 'H'];

List<SkillDef> skillsForWeapon(WeaponType? t) {
  switch (t) {
    case WeaponType.sword:
      return const [
        SkillDef(SkillId.swordSwing, 'A', '소드 스윙', '정면을 넓게 베어 큰 피해(x1.8)를 줍니다.', 2.5),
        SkillDef(SkillId.swordWhirl, 'S', '월윈드', '주위를 회전 베기로 휩쓸어 전방위 피해(x1.5)를 줍니다.', 6.0),
      ];
    case WeaponType.spear:
      return const [
        SkillDef(SkillId.spearThrust, 'A', '관통 찌르기', '직선상의 모든 적을 관통(x2.2)합니다.', 3.0),
        SkillDef(SkillId.spearSweep, 'S', '창 휘두르기', '넓은 부채꼴로 쓸어버립니다(x1.5).', 5.0),
      ];
    case WeaponType.bow:
      return const [
        SkillDef(SkillId.bowDouble, 'A', '더블샷', '화살 2발을 연속 발사(각 x1.3)합니다.', 3.0),
        SkillDef(SkillId.bowBomb, 'S', '애로우 봄', '폭발 화살로 착탄 지점에 광역 피해(x2.2)를 줍니다.', 8.0),
      ];
    case WeaponType.axe:
      return const [
        SkillDef(SkillId.axeSmash, 'A', '강타', '정면을 강하게 내려쳐 큰 피해(x2.6)를 줍니다.', 4.0),
        SkillDef(SkillId.axeWhirl, 'S', '회오리 도끼', '주위를 두 바퀴 휩쓸어 전방위 피해(x1.7)를 줍니다.', 7.0),
      ];
    case WeaponType.staff:
      return const [
        SkillDef(SkillId.staffFireball, 'A', '파이어볼', '폭발하는 화염구를 발사(x2.2 광역)합니다.', 4.0),
        SkillDef(SkillId.staffNova, 'S', '아케인 노바', '주위에 마력 폭발을 일으켜 광역 피해(x1.9)를 줍니다.', 10.0),
      ];
    case null:
      return const [
        SkillDef(SkillId.basicSlash, 'A', '맨손 타격', '정면을 가격합니다(x1.5).', 2.0),
      ];
  }
}

// 키 → 현재 무기 스킬 매핑.
SkillDef? skillForKey(WeaponType? t, String key) {
  for (final s in skillsForWeapon(t)) {
    if (s.key == key) return s;
  }
  return null;
}
