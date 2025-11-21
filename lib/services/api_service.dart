import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/search_panel.dart';
import '../models/customer_detail.dart';
import '../models/customerHoliday.dart';

class DatabaseService {
  static const String baseUrl = 'https://localhost:5001/api';

  // SSL 인증서 검증 무시를 위한 HttpClient (개발용)
  static HttpClient _createHttpClient() {
    final client = HttpClient();
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return client;
  }

  // 관제고객 목록 조회
  static Future<List<SearchPanel>> getCustomers() async {
    try {
      final httpClient = _createHttpClient();
      final request = await httpClient.getUrl(
        Uri.parse('https://localhost:7088/api/관제고객/top'),
      );
      final response = await request.close();

      if (response.statusCode == 200) {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        final List<dynamic> jsonList = json.decode(responseBody);
        return jsonList.map((json) => SearchPanel.fromJson(json)).toList();
      } else {
        print('Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('API 호출 오류: $e');
      return [];
    }
  }

  // 검색어로 고객 검색 (서버 API 사용)
  static Future<List<SearchPanel>> searchCustomers({
    required String filterType,
    required String query,
    String sortType = '번호정렬',
    int count = 100,
  }) async {
    try {
      final httpClient = _createHttpClient();

      // URL 인코딩을 위한 파라미터 구성
      final uri = Uri.parse('https://localhost:7088/api/관제고객/search').replace(
        queryParameters: {
          'filterType': filterType,
          'query': query,
          'sortType': sortType,
          'count': count.toString(),
        },
      );
      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        final List<dynamic> jsonList = json.decode(responseBody);
        return jsonList.map((json) => SearchPanel.fromJson(json)).toList();
      } else {
        print('검색 오류: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('검색 API 호출 오류: $e');
      return [];
    }
  }

  // 로컬에서 검색 (백업용 - 서버 API가 실패할 경우)
  static Future<List<SearchPanel>> searchCustomersLocal({
    required String filterType,
    required String query,
  }) async {
    try {
      // 먼저 전체 목록을 가져온 후 클라이언트에서 필터링
      final customers = await getCustomers();

      if (query.isEmpty) {
        return customers;
      }

      return customers.where((customer) {
        return customer.matchesFilter(filterType, query);
      }).toList();
    } catch (e) {
      print('로컬 검색 오류: $e');
      return [];
    }
  }

  // 관제관리번호로 고객 상세 정보 조회
  static Future<CustomerDetail?> getCustomerDetail(
    String managementNumber,
  ) async {
    try {
      final httpClient = _createHttpClient();
      final encodedNumber = Uri.encodeComponent(managementNumber);
      print(encodedNumber);
      final uri = Uri.parse('https://localhost:7088/api/관제고객/$encodedNumber');

      print('고객 상세 조회 API 호출: $uri');

      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        final Map<String, dynamic> jsonData = json.decode(responseBody);
        return CustomerDetail.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        print('고객 상세 정보를 찾을 수 없음: $managementNumber');
        return null;
      } else {
        print('고객 상세 조회 오류: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('고객 상세 조회 API 호출 오류: $e');
      return null;
    }
  }

  // 관제관리번호로 휴일주간 정보 조회
  static Future<List<CustomerHoliday>> getHoliday(
    String managementNumber,
  ) async {
    try {
      final httpClient = _createHttpClient();
      final encodedNumber = Uri.encodeComponent(managementNumber);
      final uri = Uri.parse(
        'https://localhost:7088/api/관제고객/$encodedNumber/holiday',
      );

      print('휴일주간 조회 API 호출: $uri');

      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        final List<dynamic> jsonList = json.decode(responseBody);
        return jsonList.map((json) => CustomerHoliday.fromJson(json)).toList();
      } else {
        print('휴일주간 조회 오류: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('휴일주간 조회 API 호출 오류: $e');
      return [];
    }
  }

  // 드롭다운 코드 데이터 조회 (CodeDataCache에서 사용)
  Future<List<CodeData>> fetchCodeData(String codeType) async {
    try {
      final httpClient = DatabaseService._createHttpClient();
      final uri = Uri.parse('https://localhost:7088/api/Dropdown/$codeType');

      print('드롭다운 데이터 조회 API 호출: $uri');

      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        final List<dynamic> jsonList = json.decode(responseBody);
        return jsonList
            .map((json) => CodeData.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        print('드롭다운 데이터 조회 오류: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('드롭다운 데이터 조회 API 호출 오류: $e');
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

  /// 코드 데이터 조회 (캐시 우선, 없으면 API 호출)
  static Future<List<CodeData>> getCodeData(String codeType) async {
    final now = DateTime.now();

    // 캐시에 있고 만료되지 않았는지 확인
    if (_cache.containsKey(codeType) &&
        _cacheTime[codeType]!.add(_cacheDuration).isAfter(now)) {
      return _cache[codeType]!;
    }

    // 캐시에 없으면 API에서 가져오기
    final api = DatabaseService();
    final data = await api.fetchCodeData(codeType);
    _cache[codeType] = data;
    _cacheTime[codeType] = now;

    return data;
  }

  /// 캐시 초기화
  static void clearCache() {
    _cache.clear();
    _cacheTime.clear();
  }

  /// 특정 코드 유형의 캐시만 삭제
  static void clearCacheForType(String codeType) {
    _cache.remove(codeType);
    _cacheTime.remove(codeType);
  }
}
