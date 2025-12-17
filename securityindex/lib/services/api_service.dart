import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/search_panel.dart';
import '../models/customer_detail.dart';
import '../models/customerHoliday.dart';
import '../models/additional_service.dart';
import '../models/dvr_info.dart';
import '../models/AuthRegist.dart';
import '../models/document_info.dart';
import '../models/userZone.dart';
import '../models/recentsignalinfo.dart';

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

  // 관제관리번호로 부가서비스 정보 조회
  static Future<List<AdditionalService>> getAdditionalServices(
    String managementNumber,
  ) async {
    try {
      final httpClient = _createHttpClient();
      final encodedNumber = Uri.encodeComponent(managementNumber);
      final uri = Uri.parse(
        'https://localhost:7088/api/관제고객/$encodedNumber/service',
      );

      print('부가서비스 조회 API 호출: $uri');

      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        final List<dynamic> jsonList = json.decode(responseBody);
        return jsonList
            .map((json) => AdditionalService.fromJson(json))
            .toList();
      } else {
        print('부가서비스 조회 오류: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('부가서비스 조회 API 호출 오류: $e');
      return [];
    }
  }

  // 관제관리번호로 DVR 연동 정보 조회
  static Future<List<DVRInfo>> getDVRInfo(String managementNumber) async {
    try {
      final httpClient = _createHttpClient();
      final encodedNumber = Uri.encodeComponent(managementNumber);
      final uri = Uri.parse(
        'https://localhost:7088/api/관제고객/$encodedNumber/dvr',
      );

      print('DVR 정보 조회 API 호출: $uri');

      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        final List<dynamic> jsonList = json.decode(responseBody);
        return jsonList.map((json) => DVRInfo.fromJson(json)).toList();
      } else {
        print('DVR 정보 조회 오류: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('DVR 정보 조회 API 호출 오류: $e');
      return [];
    }
  }

  // 관제관리번호로 스마트폰 인증 정보 조회
  static Future<List<AuthRegist>> getSmartphoneAuthInfo(
    String managementNumber,
  ) async {
    try {
      final httpClient = _createHttpClient();
      final encodedNumber = Uri.encodeComponent(managementNumber);
      final uri = Uri.parse(
        'https://localhost:7088/api/관제고객/$encodedNumber/smartphone-auth',
      );

      print('스마트폰 인증 정보 조회 API 호출: $uri');

      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        final List<dynamic> jsonList = json.decode(responseBody);
        return jsonList.map((json) => AuthRegist.fromJson(json)).toList();
      } else {
        print('스마트폰 인증 정보 조회 오류: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('스마트폰 인증 정보 조회 API 호출 오류: $e');
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

  /// 사용자 정보 조회
  /// 관제관리번호로 사용자 정보 목록을 조회합니다.
  static Future<List<UserZoneInfo>> getUserInfo(String managementNumber) async {
    try {
      final httpClient = _createHttpClient();
      final encodedNumber = Uri.encodeComponent(managementNumber);
      final uri = Uri.parse(
        'https://localhost:7088/api/관제고객/$encodedNumber/user-info',
      );

      print('사용자 정보 조회 API 호출: $uri');

      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        final List<dynamic> jsonList = json.decode(responseBody);
        return jsonList.map((json) => UserZoneInfo.fromJson(json)).toList();
      } else {
        print('사용자 정보 조회 오류: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('사용자 정보 조회 API 호출 오류: $e');
      return [];
    }
  }

  /// 존정보 조회
  /// 관제관리번호로 존정보 목록을 조회합니다.
  static Future<List<ZoneInfo>> getZoneInfo(String managementNumber) async {
    try {
      final httpClient = _createHttpClient();
      final encodedNumber = Uri.encodeComponent(managementNumber);
      final uri = Uri.parse(
        'https://localhost:7088/api/관제고객/$encodedNumber/zone-info',
      );

      print('존정보 조회 API 호출: $uri');

      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        final List<dynamic> jsonList = json.decode(responseBody);
        return jsonList.map((json) => ZoneInfo.fromJson(json)).toList();
      } else {
        print('존정보 조회 오류: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('존정보 조회 API 호출 오류: $e');
      return [];
    }
  }

  // 관제관리번호로 문서 정보 조회
  static Future<List<DocumentInfo>> getDocumentInfo(
    String managementNumber,
  ) async {
    try {
      final httpClient = _createHttpClient();
      final encodedNumber = Uri.encodeComponent(managementNumber);
      final uri = Uri.parse(
        'https://localhost:7088/api/관제고객/$encodedNumber/documents',
      );

      print('문서 정보 조회 API 호출: $uri');

      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        final List<dynamic> jsonList = json.decode(responseBody);
        return jsonList.map((json) => DocumentInfo.fromJson(json)).toList();
      } else {
        print('문서 정보 조회 오류: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('문서 정보 조회 API 호출 오류: $e');
      return [];
    }
  }

  /// 최근 수신신호 조회 (페이징 지원)
  /// 관제관리번호, 시작일자, 종료일자, 신호필터, 정렬 순서로 수신신호를 조회합니다.
  /// 반환값: {data: List<RecentSignalInfo>, totalCount: int}
  static Future<Map<String, dynamic>> getRecentSignals({
    required String managementNumber,
    required DateTime startDate,
    required DateTime endDate,
    String signalFilter = '전체신호',
    bool ascending = false,
    int skip = 0,
    int take = 100,
  }) async {
    try {
      final httpClient = _createHttpClient();
      final encodedNumber = Uri.encodeComponent(managementNumber);

      // 날짜를 YYYY-MM-DD 형식으로 변환
      final startDateStr =
          '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final endDateStr =
          '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

      final uri = Uri.parse(
        'https://localhost:7088/api/관제고객/$encodedNumber/recent-signals',
      ).replace(queryParameters: {
        '시작일자': startDateStr,
        '종료일자': endDateStr,
        '신호필터': signalFilter,
        '오름차순정렬': ascending.toString(),
        'skip': skip.toString(),
        'take': take.toString(),
      });

      print('최근 수신신호 조회 API 호출: $uri');

      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        final Map<String, dynamic> jsonData = json.decode(responseBody);
        final List<dynamic> dataList = jsonData['data'] ?? [];
        final int totalCount = jsonData['totalCount'] ?? 0;

        final signals = dataList.map((json) => RecentSignalInfo.fromJson(json)).toList();
        return {'data': signals, 'totalCount': totalCount};
      } else {
        print('최근 수신신호 조회 오류: ${response.statusCode}');
        return {'data': <RecentSignalInfo>[], 'totalCount': 0};
      }
    } catch (e) {
      print('최근 수신신호 조회 API 호출 오류: $e');
      return {'data': <RecentSignalInfo>[], 'totalCount': 0};
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

  /// 코드 추가
  static Future<bool> insertCode({
    required String typeName,
    required String code,
    required String codeName,
  }) async {
    try {
      final httpClient = DatabaseService._createHttpClient();
      final uri = Uri.parse('https://localhost:7088/api/Insert/$typeName');

      print('코드 추가 API 호출: $uri');
      print('코드: $code, 코드명: $codeName');

      final request = await httpClient.postUrl(uri);
      request.headers.set('Content-Type', 'application/json; charset=utf-8');

      // DeleteController와 동일한 구조로 code, codeName 키 사용
      final body = json.encode({'code': code, 'codeName': codeName});

      request.write(body);
      final response = await request.close();

      if (response.statusCode == 201) {
        print('코드 추가 성공');
        // 캐시 삭제하여 다음 조회 시 최신 데이터 반영
        clearCacheForType(typeName);
        return true;
      } else {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        print('코드 추가 오류: ${response.statusCode}, $responseBody');
        return false;
      }
    } catch (e) {
      print('코드 추가 API 호출 오류: $e');
      return false;
    }
  }

  /// 코드 삭제
  static Future<bool> deleteCodeType({
    required String typeName,
    required String code,
  }) async {
    try {
      final httpClient = DatabaseService._createHttpClient();
      // 쿼리 파라미터로 code 전달
      final uri = Uri.parse(
        'https://localhost:7088/api/Delete/$typeName',
      ).replace(queryParameters: {'code': code});

      print('코드 삭제 API 호출: $uri');
      print('code: $code');

      final request = await httpClient.deleteUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        print('코드 삭제 성공');
        // 캐시 삭제하여 다음 조회 시 최신 데이터 반영
        clearCacheForType(typeName);
        return true;
      } else {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        print('코드 삭제 오류: ${response.statusCode}, $responseBody');
        return false;
      }
    } catch (e) {
      print('코드 삭제 API 호출 오류: $e');
      return false;
    }
  }

  /// 문서 업로드 (파일 + 메타데이터)
  static Future<bool> uploadDocument({
    required String managementNumber,
    required String documentName,
    required String documentExtension,
    required String documentDescription,
    required String documentTypeName,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      final httpClient = DatabaseService._createHttpClient();
      final uri = Uri.parse('https://localhost:7088/api/Import/document');

      print('문서 업로드 API 호출: $uri');
      print('관제관리번호: $managementNumber, 문서명: $documentName');

      final request = await httpClient.postUrl(uri);

      // Multipart form data 생성
      final boundary =
          '----WebKitFormBoundary${DateTime.now().millisecondsSinceEpoch}';
      request.headers.set(
        'Content-Type',
        'multipart/form-data; boundary=$boundary',
      );

      // Body 생성
      final bodyBuffer = <int>[];

      // 필드 추가 함수
      void addField(String name, String value) {
        bodyBuffer.addAll(utf8.encode('--$boundary\r\n'));
        bodyBuffer.addAll(
          utf8.encode('Content-Disposition: form-data; name="$name"\r\n\r\n'),
        );
        bodyBuffer.addAll(utf8.encode(value));
        bodyBuffer.addAll(utf8.encode('\r\n'));
      }

      // 메타데이터 추가
      addField('관제관리번호', managementNumber);
      addField('문서명', documentName);
      addField('문서확장자', documentExtension);
      addField('문서설명', documentDescription);
      addField('문서종류명', documentTypeName);

      // 파일 추가
      bodyBuffer.addAll(utf8.encode('--$boundary\r\n'));
      bodyBuffer.addAll(
        utf8.encode(
          'Content-Disposition: form-data; name="file"; filename="$fileName"\r\n',
        ),
      );
      bodyBuffer.addAll(
        utf8.encode('Content-Type: application/octet-stream\r\n\r\n'),
      );
      bodyBuffer.addAll(fileBytes);
      bodyBuffer.addAll(utf8.encode('\r\n'));

      // 종료 boundary
      bodyBuffer.addAll(utf8.encode('--$boundary--\r\n'));

      request.contentLength = bodyBuffer.length;
      request.add(bodyBuffer);

      final response = await request.close();

      if (response.statusCode == 200) {
        print('문서 업로드 성공');
        return true;
      } else {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        print('문서 업로드 오류: ${response.statusCode}, $responseBody');
        return false;
      }
    } catch (e) {
      print('문서 업로드 API 호출 오류: $e');
      return false;
    }
  }

  /// 스마트폰 앱 인증 정보 추가
  static Future<bool> insertAuth({
    required String phoneNumber,
    required String controlManagementNumber,
    required String erpCusNumber,
    required String businessName,
    required String userName,
    required bool remoteGuardAllowed,
    required bool remoteReleaseAllowed,
  }) async {
    try {
      final httpClient = DatabaseService._createHttpClient();
      final uri = Uri.parse('https://localhost:7088/api/Insert/auth');

      print('인증 정보 추가 API 호출: $uri');
      print('휴대폰번호: $phoneNumber, 관제관리번호: $controlManagementNumber');

      final request = await httpClient.postUrl(uri);
      request.headers.set('Content-Type', 'application/json; charset=utf-8');

      final body = json.encode({
        '휴대폰번호': phoneNumber,
        '관제관리번호': controlManagementNumber,
        '영업관리번호': erpCusNumber,
        '상호명': businessName,
        '사용자이름': userName,
        '원격경계여부': remoteGuardAllowed,
        '원격해제여부': remoteReleaseAllowed,
      });

      request.write(body);
      final response = await request.close();

      if (response.statusCode == 201) {
        print('인증 정보 추가 성공');
        return true;
      } else {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        print('인증 정보 추가 오류: ${response.statusCode}, $responseBody');
        return false;
      }
    } catch (e) {
      print('인증 정보 추가 API 호출 오류: $e');
      return false;
    }
  }
}
