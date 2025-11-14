import 'package:mssql_connection/mssql_connection.dart';
import '../models/customer.dart';
import '../models/customer_detail.dart';

class DatabaseService {
  static MssqlConnection? _connection;

  // 데이터베이스 연결 설정
  static const String _server = 'myip';
  static const String _database = 'neosecurity_Ring';
  static const String _username = 'neo';
  static const String _password = '1234';
  static const int _port = 1433;

  // 데이터베이스 연결 초기화
  static Future<MssqlConnection> _getConnection() async {
    if (_connection != null && _connection!.isConnected) {
      return _connection!;
    }

    _connection = MssqlConnection.getInstance();

    bool isConnected = await _connection!.connect(
      ip: _server,
      port: _port.toString(),
      databaseName: _database,
      username: _username,
      password: _password,
    );

    if (!isConnected) {
      throw Exception('데이터베이스 연결 실패');
    }

    print('데이터베이스 연결 성공');
    return _connection!;
  }

  // 연결 종료
  static Future<void> closeConnection() async {
    if (_connection != null && _connection!.isConnected) {
      await _connection!.disconnect();
      _connection = null;
      print('데이터베이스 연결 종료');
    }
  }

  // 관제고객 목록 조회
  static Future<List<Customer>> getCustomers({int count = 100}) async {
    try {
      final conn = await _getConnection();

      final query = '''
        SELECT TOP $count
          관제관리번호,
          관제상호,
          대표자,
          물건주소,
          관제연락처1,
          관제연락처2,
          출동권역코드,
          관제고객상태코드,
          서비스종류코드
        FROM 관제고객마스터뷰
        ORDER BY 관제관리번호
      ''';

      final result = await conn.getData(query);

      if (result == null || result.isEmpty) {
        return [];
      }

      return result.map((row) {
        return Customer.fromJson({
          '관제관리번호': row['관제관리번호'],
          '관제상호': row['관제상호'],
          '대표자': row['대표자'],
          '물건주소': row['물건주소'],
          '관제연락처1': row['관제연락처1'],
          '관제연락처2': row['관제연락처2'],
          '출동권역코드': row['출동권역코드'],
          '관제고객상태코드': row['관제고객상태코드'],
          '서비스종류코드': row['서비스종류코드'],
        });
      }).toList();
    } catch (e) {
      print('관제고객 목록 조회 오류: $e');
      return [];
    }
  }

  // 검색어로 고객 검색
  static Future<List<Customer>> searchCustomers({
    required String filterType,
    required String query,
    String sortType = '번호정렬',
    int count = 100,
  }) async {
    try {
      final conn = await _getConnection();

      String whereClause = '';

      if (query.isNotEmpty) {
        final searchQuery = query.replaceAll("'", "''"); // SQL Injection 방지

        switch (filterType) {
          case '고객번호':
            whereClause = "WHERE 관제관리번호 LIKE '%$searchQuery%'";
            break;
          case '상호':
            whereClause = "WHERE 관제상호 LIKE '%$searchQuery%'";
            break;
          case '대표자':
            whereClause = "WHERE 대표자 LIKE '%$searchQuery%'";
            break;
          case '물건주소':
            whereClause = "WHERE 물건주소 LIKE '%$searchQuery%'";
            break;
          case '전화번호':
          case '관제연락처1':
            whereClause = "WHERE 관제연락처1 LIKE '%$searchQuery%'";
            break;
          case '사용자HP':
            // 사용자마스터 테이블과 JOIN 필요
            final userQuery = '''
              SELECT DISTINCT 관제관리번호
              FROM 사용자마스터
              WHERE 휴대전화 LIKE '%$searchQuery%'
            ''';

            final userResult = await conn.getData(userQuery);

            if (userResult == null || userResult.isEmpty) {
              return [];
            }

            final managementNumbers = userResult
                .map((row) => "'${row['관제관리번호']}'")
                .join(',');

            whereClause = "WHERE 관제관리번호 IN ($managementNumbers)";
            break;
          default:
            whereClause = '''
              WHERE 관제관리번호 LIKE '%$searchQuery%'
                 OR 관제상호 LIKE '%$searchQuery%'
                 OR 대표자 LIKE '%$searchQuery%'
                 OR 물건주소 LIKE '%$searchQuery%'
            ''';
        }
      }

      final orderClause = sortType == '상호정렬'
          ? 'ORDER BY 관제상호'
          : 'ORDER BY 관제관리번호';

      final sqlQuery = '''
        SELECT TOP $count
          관제관리번호,
          관제상호,
          대표자,
          물건주소,
          관제연락처1,
          관제연락처2,
          출동권역코드,
          관제고객상태코드,
          서비스종류코드
        FROM 관제고객마스터뷰
        $whereClause
        $orderClause
      ''';

      print('실행 SQL: $sqlQuery');

      final result = await conn.getData(sqlQuery);

      if (result == null || result.isEmpty) {
        return [];
      }

      return result.map((row) {
        return Customer.fromJson({
          '관제관리번호': row['관제관리번호'],
          '관제상호': row['관제상호'],
          '대표자': row['대표자'],
          '물건주소': row['물건주소'],
          '관제연락처1': row['관제연락처1'],
          '관제연락처2': row['관제연락처2'],
          '출동권역코드': row['출동권역코드'],
          '관제고객상태코드': row['관제고객상태코드'],
          '서비스종류코드': row['서비스종류코드'],
        });
      }).toList();
    } catch (e) {
      print('관제고객 검색 오류: $e');
      return [];
    }
  }

  // 관제관리번호로 고객 상세 정보 조회
  static Future<CustomerDetail?> getCustomerDetail(String managementNumber) async {
    try {
      final conn = await _getConnection();

      final searchNumber = managementNumber.replaceAll("'", "''"); // SQL Injection 방지

      final query = '''
        SELECT *
        FROM 관제고객마스터뷰
        WHERE 관제관리번호 = '$searchNumber'
      ''';

      print('고객 상세 조회 SQL: $query');

      final result = await conn.getData(query);

      if (result == null || result.isEmpty) {
        print('고객 상세 정보를 찾을 수 없음: $managementNumber');
        return null;
      }

      final row = result.first;

      // CustomerDetail.fromJson에 필요한 모든 필드를 매핑
      return CustomerDetail.fromJson({
        '관제관리번호': row['관제관리번호'],
        '관제상호': row['관제상호'],
        '대표자': row['대표자'],
        '물건주소': row['물건주소'],
        '관제연락처1': row['관제연락처1'],
        '관제연락처2': row['관제연락처2'],
        '출동권역코드': row['출동권역코드'],
        '관제고객상태코드': row['관제고객상태코드'],
        '서비스종류코드': row['서비스종류코드'],
        '관리구역코드': row['관리구역코드'],
        '업종대코드': row['업종대코드'],
        '차량코드': row['차량코드'],
        '경찰서코드': row['경찰서코드'],
        '지구대코드': row['지구대코드'],
        '사용회선종류': row['사용회선종류'],
        '기기종류코드': row['기기종류코드'],
        '미경계분류코드': row['미경계분류코드'],
        '미경계종류코드': row['미경계종류코드'],
        '물건우편번호': row['물건우편번호'],
        '물건지번주소': row['물건지번주소'],
        '물건도로명주소': row['물건도로명주소'],
        '청구우편번호': row['청구우편번호'],
        '청구지번주소': row['청구지번주소'],
        '청구도로명주소': row['청구도로명주소'],
        '주장치번호': row['주장치번호'],
        '부장치번호': row['부장치번호'],
        '회선번호': row['회선번호'],
        '관제메모': row['관제메모'],
        '월관제료': row['월관제료'],
        '개시년월일': row['개시년월일']?.toString(),
        '해지년월일': row['해지년월일']?.toString(),
      });
    } catch (e) {
      print('고객 상세 조회 오류: $e');
      return null;
    }
  }

  // 드롭다운 코드 데이터 조회
  static Future<List<CodeData>> fetchCodeData(String codeType) async {
    try {
      final conn = await _getConnection();

      String tableName;
      String codeColumn;
      String nameColumn;

      switch (codeType.toLowerCase()) {
        case 'managementarea':
          tableName = '관리구역코드';
          codeColumn = '관리구역코드';
          nameColumn = '관리구역코드명';
          break;
        case 'operationarea':
          tableName = '출동권역코드';
          codeColumn = '출동권역코드';
          nameColumn = '출동권역코드명';
          break;
        case 'businesstype':
          tableName = '업종대코드';
          codeColumn = '업종대코드';
          nameColumn = '업종대코드명';
          break;
        case 'policestation':
          tableName = '경찰서코드';
          codeColumn = '경찰서코드';
          nameColumn = '경찰서코드명';
          break;
        case 'policedistrict':
          tableName = '지구대코드';
          codeColumn = '지구대코드';
          nameColumn = '지구대코드명';
          break;
        case 'usageline':
          tableName = '사용회선종류';
          codeColumn = '사용회선종류';
          nameColumn = '사용회선종류명';
          break;
        case 'servicetype':
          tableName = '서비스종류코드';
          codeColumn = '서비스종류코드';
          nameColumn = '서비스종류코드명';
          break;
        case 'customerstatus':
          tableName = '관제고객상태코드';
          codeColumn = '관제고객상태코드';
          nameColumn = '관제고객상태코드명';
          break;
        case 'mainsystem':
          tableName = '기기종류코드';
          codeColumn = '기기종류코드';
          nameColumn = '기기종류명';
          break;
        case 'subsystem':
          tableName = '미경계분류코드';
          codeColumn = '미경계분류코드';
          nameColumn = '미경계분류코드명';
          break;
        case 'vehiclecode':
          tableName = '차량코드';
          codeColumn = '차량코드';
          nameColumn = '차량코드명';
          break;
        case 'misettings':
          tableName = '미경계종류코드';
          codeColumn = '미경계종류코드';
          nameColumn = '미경계종류코드명';
          break;
        default:
          print('지원하지 않는 코드 유형: $codeType');
          return [];
      }

      final query = '''
        SELECT $codeColumn AS code, $nameColumn AS name
        FROM $tableName
        ORDER BY $codeColumn
      ''';

      print('드롭다운 데이터 조회 SQL: $query');

      final result = await conn.getData(query);

      if (result == null || result.isEmpty) {
        return [];
      }

      return result.map((row) {
        return CodeData(
          code: row['code']?.toString() ?? '',
          name: row['name']?.toString() ?? '',
        );
      }).toList();
    } catch (e) {
      print('드롭다운 데이터 조회 오류: $e');
      return [];
    }
  }
}

// 코드 데이터 모델
class CodeData {
  final String code;
  final String name;
  final String? description;

  CodeData({required this.code, required this.name, this.description});

  factory CodeData.fromJson(Map<String, dynamic> json) {
    return CodeData(
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }

  @override
  String toString() => '$code - $name';
}

// 드롭다운 데이터 캐시 클래스
class CodeDataCache {
  static final Map<String, List<CodeData>> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static const Duration _cacheDuration = Duration(hours: 1);

  /// 코드 데이터 조회 (캐시 우선, 없으면 DB 직접 호출)
  static Future<List<CodeData>> getCodeData(String codeType) async {
    final now = DateTime.now();
    print("codeType: $codeType");

    // 캐시에 있고 만료되지 않았는지 확인
    if (_cache.containsKey(codeType) &&
        _cacheTime[codeType]!.add(_cacheDuration).isAfter(now)) {
      print('캐시에서 $codeType 데이터 반환 (${_cache[codeType]!.length}개)');
      return _cache[codeType]!;
    }

    // 캐시에 없으면 DB에서 가져오기
    print('DB에서 $codeType 데이터 조회');
    final data = await DatabaseService.fetchCodeData(codeType);
    _cache[codeType] = data;
    _cacheTime[codeType] = now;

    return data;
  }

  /// 캐시 초기화
  static void clearCache() {
    _cache.clear();
    _cacheTime.clear();
    print('드롭다운 캐시가 초기화되었습니다.');
  }

  /// 특정 코드 유형의 캐시만 삭제
  static void clearCacheForType(String codeType) {
    _cache.remove(codeType);
    _cacheTime.remove(codeType);
    print('$codeType 캐시가 삭제되었습니다.');
  }
}
