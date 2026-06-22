// 인스턴스/몬스터 DTO (§9 models). 서버 rpc_create_instance 응답 매핑.

class InstanceMonster {
  final int idx;
  final String templateId;
  final double x;
  final double y;
  final int hp;

  InstanceMonster({
    required this.idx,
    required this.templateId,
    required this.x,
    required this.y,
    required this.hp,
  });

  factory InstanceMonster.fromJson(Map<String, dynamic> j) => InstanceMonster(
        idx: (j['idx'] as num).toInt(),
        templateId: j['template_id'] as String,
        x: (j['x'] as num).toDouble(),
        y: (j['y'] as num).toDouble(),
        hp: (j['hp'] as num).toInt(),
      );
}

class GameInstance {
  final int runSeed;
  final String biome;
  final List<InstanceMonster> monsters;

  GameInstance({
    required this.runSeed,
    required this.biome,
    required this.monsters,
  });

  factory GameInstance.fromJson(Map<String, dynamic> j) => GameInstance(
        runSeed: (j['run_seed'] as num).toInt(),
        biome: (j['biome'] as String?) ?? 'forest',
        monsters: ((j['monsters'] as List?) ?? const [])
            .map((m) => InstanceMonster.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}
