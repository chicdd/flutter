import 'database_service.dart';

/// 드롭다운 코드 데이터 모델
class CodeData {
  final String code;
  final String name;
  final String? description;

  CodeData({required this.code, required this.name, this.description});

  factory CodeData.fromJson(Map<String, dynamic> json) {
    return CodeData(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
    );
  }

  @override
  String toString() => name; // 드롭다운에서 표시될 텍스트

  // 중복 제거를 위한 동등성 비교
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodeData &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

/// 드롭다운 데이터 로컬 캐싱 클래스
class CodeDataCache {
  static final Map<String, List<CodeData>> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static const Duration _cacheDuration = Duration(hours: 1);

  /// 코드 데이터 조회 (캐시 우선, 없으면 API 호출)
  static Future<List<CodeData>> getCodeData(
    String codeType,
    DatabaseService api,
  ) async {
    final now = DateTime.now();

    // 캐시에 있고 만료되지 않았는지 확인
    if (_cache.containsKey(codeType) &&
        _cacheTime[codeType]!.add(_cacheDuration).isAfter(now)) {
      print('캐시에서 로드: $codeType');
      return _cache[codeType]!;
    }

    // 캐시에 없으면 API에서 가져오기
    print('API에서 로드: $codeType');
    final jsonData = await api.fetchCodeData(codeType);

    // JSON 데이터를 CodeData 객체로 변환
    final codeDataList = jsonData
        .map((json) => CodeData.fromJson(json as Map<String, dynamic>))
        .toList();

    // 중복 제거
    final uniqueData = codeDataList.toSet().toList();

    _cache[codeType] = uniqueData;
    _cacheTime[codeType] = now;

    return uniqueData;
  }

  /// 특정 코드 타입의 캐시 삭제
  static void clearCache([String? codeType]) {
    if (codeType != null) {
      _cache.remove(codeType);
      _cacheTime.remove(codeType);
    } else {
      _cache.clear();
      _cacheTime.clear();
    }
  }

  /// 모든 캐시 데이터 미리 로드 (앱 시작 시 호출)
  static Future<void> preloadAllCaches(DatabaseService api) async {
    final codeTypes = [
      'managementarea',
      'operationarea',
      'businesstype',
      'vehiclecode',
      'policestation',
      'policedistrict',
      'usageline',
      'servicetype',
      'mainsystem',
      'subsystem',
      'misettings',
    ];

    for (final codeType in codeTypes) {
      try {
        await getCodeData(codeType, api);
      } catch (e) {
        print('캐시 프리로드 실패: $codeType - $e');
      }
    }
  }
}
