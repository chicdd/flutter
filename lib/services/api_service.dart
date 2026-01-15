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
import '../models/search_log.dart';
import '../models/customer_history.dart';
import '../models/map_diagram.dart';
import '../models/blueprint.dart';
import '../models/aslog.dart';
import '../models/sales_info.dart';
import '../models/payment_history.dart';
import '../models/visit_as_history.dart';

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

  /// 기본 고객 정보 수정
  static Future<bool> updateBasicCustomerInfo({
    required String managementNumber,
    required Map<String, dynamic> data,
  }) async {
    try {
      final httpClient = DatabaseService._createHttpClient();
      final encodedNumber = Uri.encodeComponent(managementNumber);
      final uri = Uri.parse('');

      print('기본 고객 정보 수정 API 호출: $uri');
      print('관제관리번호: $managementNumber');

      final request = await httpClient.putUrl(uri);
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.write(json.encode(data));
      print(json.encode(data));
      final response = await request.close();
      final String responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        print('기본 고객 정보 수정 성공');
        return true;
      } else {
        print('기본 고객 정보 수정 실패: ${response.statusCode}, $responseBody');
        return false;
      }
    } catch (e) {
      print('기본 고객 정보 수정 API 호출 오류: $e');
      return false;
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

      final uri =
          Uri.parse(
            'https://localhost:7088/api/관제고객/$encodedNumber/recent-signals',
          ).replace(
            queryParameters: {
              '시작일자': startDateStr,
              '종료일자': endDateStr,
              '신호필터': signalFilter,
              '오름차순정렬': ascending.toString(),
              'skip': skip.toString(),
              'take': take.toString(),
            },
          );

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

        final signals = dataList
            .map((json) => RecentSignalInfo.fromJson(json))
            .toList();
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

  /// 관제개시 정보 조회
  /// 관제관리번호로 관제개시 정보를 조회합니다.
  static Future<List<Map<String, dynamic>>> getControlSignalActivations(
    String managementNumber,
  ) async {
    try {
      final httpClient = _createHttpClient();
      final encodedNumber = Uri.encodeComponent(managementNumber);
      final uri = Uri.parse('https://localhost:7088/api/관제개시/$encodedNumber');

      print('관제개시 조회 API 호출: $uri');

      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        final List<dynamic> jsonList = json.decode(responseBody);
        return jsonList.cast<Map<String, dynamic>>();
      } else {
        print('관제개시 조회 오류: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('관제개시 조회 API 호출 오류: $e');
      return [];
    }
  }

  /// 관제개시 정보 추가
  static Future<bool> addControlSignalActivation(
    Map<String, dynamic> data,
  ) async {
    try {
      final httpClient = _createHttpClient();
      final request = await httpClient.postUrl(
        Uri.parse('https://localhost:7088/api/관제개시'),
      );

      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.write(json.encode(data));

      final response = await request.close();
      final String responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 201) {
        print('관제개시 추가 성공');
        return true;
      } else {
        print('관제개시 추가 실패: $responseBody');
        return false;
      }
    } catch (e) {
      print('관제개시 추가 API 호출 오류: $e');
      return false;
    }
  }

  /// 보수점검 완료이력 조회
  /// 관제관리번호로 보수점검 완료이력을 조회합니다.
  static Future<List<Map<String, dynamic>>> getMaintenanceInspectionHistory(
    String managementNumber,
  ) async {
    try {
      final httpClient = _createHttpClient();
      final encodedNumber = Uri.encodeComponent(managementNumber);
      final uri = Uri.parse('https://localhost:7088/api/보수점검/$encodedNumber');

      print('보수점검 완료이력 조회 API 호출: $uri');

      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        final List<dynamic> jsonList = json.decode(responseBody);
        return jsonList.cast<Map<String, dynamic>>();
      } else {
        print('보수점검 완료이력 조회 오류: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('보수점검 완료이력 조회 API 호출 오류: $e');
      return [];
    }
  }

  /// 보수점검 정보 추가
  static Future<bool> addMaintenanceInspection(
    Map<String, dynamic> data,
  ) async {
    try {
      final httpClient = _createHttpClient();
      final request = await httpClient.postUrl(
        Uri.parse('https://localhost:7088/api/보수점검'),
      );

      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.write(json.encode(data));

      final response = await request.close();
      final String responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 201) {
        print('보수점검 추가 성공');
        return true;
      } else {
        print('보수점검 추가 실패: $responseBody');
        return false;
      }
    } catch (e) {
      print('보수점검 추가 API 호출 오류: $e');
      return false;
    }
  }

  /// 검색로그 내역조회 (페이징 지원)
  /// 관제관리번호, 시작일자, 종료일자로 검색로그를 조회합니다.
  /// 반환값: {data: List<SearchLogData>, totalCount: int}
  static Future<Map<String, dynamic>> getSearchLogs({
    required String managementNumber,
    required DateTime startDate,
    required DateTime endDate,
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

      final uri =
          Uri.parse(
            'https://localhost:7088/api/관제고객/검색로그내역조회/$encodedNumber',
          ).replace(
            queryParameters: {
              '시작일자': startDateStr,
              '종료일자': endDateStr,
              'skip': skip.toString(),
              'take': take.toString(),
            },
          );

      print('검색로그 내역조회 API 호출: $uri');

      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        final Map<String, dynamic> jsonData = json.decode(responseBody);
        final List<dynamic> dataList = jsonData['data'] ?? [];
        final int totalCount = jsonData['totalCount'] ?? 0;

        final logs = dataList
            .map((json) => SearchLogData.fromJson(json))
            .toList();
        return {'data': logs, 'totalCount': totalCount};
      } else {
        print('검색로그 내역조회 오류: ${response.statusCode}');
        return {'data': <SearchLogData>[], 'totalCount': 0};
      }
    } catch (e) {
      print('검색로그 내역조회 API 호출 오류: $e');
      return {'data': <SearchLogData>[], 'totalCount': 0};
    }
  }

  /// 고객정보 변동이력 조회 (페이징 지원)
  /// 관제관리번호, 시작일자, 종료일자로 고객정보 변동이력을 조회합니다.
  /// 반환값: {data: List<CustomerHistoryData>, totalCount: int}
  static Future<Map<String, dynamic>> getCustomerHistory({
    required String managementNumber,
    required DateTime startDate,
    required DateTime endDate,
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

      final uri =
          Uri.parse(
            'https://localhost:7088/api/관제고객/고객정보변동이력/$encodedNumber',
          ).replace(
            queryParameters: {
              '시작일자': startDateStr,
              '종료일자': endDateStr,
              'skip': skip.toString(),
              'take': take.toString(),
            },
          );

      print('고객정보 변동이력 조회 API 호출: $uri');

      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        final Map<String, dynamic> jsonData = json.decode(responseBody);
        final List<dynamic> dataList = jsonData['data'] ?? [];
        final int totalCount = jsonData['totalCount'] ?? 0;

        final history = dataList
            .map((json) => CustomerHistoryData.fromJson(json))
            .toList();
        return {'data': history, 'totalCount': totalCount};
      } else {
        print('고객정보 변동이력 조회 오류: ${response.statusCode}');
        return {'data': <CustomerHistoryData>[], 'totalCount': 0};
      }
    } catch (e) {
      print('고객정보 변동이력 조회 API 호출 오류: $e');
      return {'data': <CustomerHistoryData>[], 'totalCount': 0};
    }
  }

  /// 약도 데이터 조회
  ///
  /// [managementNumber] - 관제관리번호
  /// 반환: MapDiagramData? - 약도 데이터 (없으면 null)
  static Future<MapDiagramData?> getMapDiagram({
    required String managementNumber,
  }) async {
    try {
      print('약도 조회 요청: 관제관리번호=$managementNumber');

      final encodedNumber = Uri.encodeComponent(managementNumber);
      final uri = Uri.parse(
        'https://localhost:7088/api/관제고객/약도조회/$encodedNumber',
      );

      final client = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();

        final Map<String, dynamic> data = json.decode(responseBody);
        final mapDiagram = MapDiagramData.fromJson(data);

        print('약도 조회 성공: 관제관리번호=$managementNumber');
        return mapDiagram;
      } else if (response.statusCode == 404) {
        print('약도 데이터 없음: 관제관리번호=$managementNumber');
        return null;
      } else {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        print('약도 조회 오류: ${response.statusCode}, $responseBody');
        return null;
      }
    } catch (e) {
      print('약도 조회 API 호출 오류: $e');
      return null;
    }
  }

  /// 도면 데이터 조회 (도면마스터 및 도면마스터2)
  ///
  /// [managementNumber] - 관제관리번호
  /// 반환: List<BlueprintData> - 도면 데이터 리스트 (없으면 빈 리스트)
  static Future<List<BlueprintData>> getBlueprints({
    required String managementNumber,
  }) async {
    try {
      print('도면 조회 요청: 관제관리번호=$managementNumber');

      final encodedNumber = Uri.encodeComponent(managementNumber);
      final uri = Uri.parse(
        'https://localhost:7088/api/관제고객/도면조회/$encodedNumber',
      );

      final client = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();

        final List<dynamic> dataList = json.decode(responseBody);
        final blueprints = dataList
            .map((item) => BlueprintData.fromJson(item as Map<String, dynamic>))
            .toList();

        print('도면 조회 성공: 관제관리번호=$managementNumber, 도면개수=${blueprints.length}');
        return blueprints;
      } else if (response.statusCode == 404) {
        print('도면 데이터 없음: 관제관리번호=$managementNumber');
        return [];
      } else {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        print('도면 조회 오류: ${response.statusCode}, $responseBody');
        return [];
      }
    } catch (e) {
      print('도면 조회 API 호출 오류: $e');
      return [];
    }
  }

  /// AS접수 정보 조회
  /// 관제관리번호로 AS접수 정보를 조회합니다.
  static Future<List<AsLog>> getASLog(String managementNumber) async {
    try {
      final httpClient = _createHttpClient();
      final encodedNumber = Uri.encodeComponent(managementNumber);
      final uri = Uri.parse(
        'https://localhost:7088/api/관제고객/$encodedNumber/ashistory',
      );

      print('AS접수 정보 조회 API 호출: $uri');

      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        final List<dynamic> jsonList = json.decode(responseBody);
        return jsonList.map((json) => AsLog.fromJson(json)).toList();
      } else {
        print('AS접수 정보 조회 오류: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('AS접수 정보 조회 API 호출 오류: $e');
      return [];
    }
  }

  /// AS접수 정보 추가
  static Future<bool> addASLog(Map<String, dynamic> data) async {
    try {
      final httpClient = _createHttpClient();
      final request = await httpClient.postUrl(
        Uri.parse('https://localhost:7088/api/Insert/aslog'),
      );

      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.write(json.encode(data));

      final response = await request.close();
      final String responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 201) {
        print('AS접수 추가 성공');
        return true;
      } else {
        print('AS접수 추가 실패: $responseBody');
        return false;
      }
    } catch (e) {
      print('AS접수 추가 API 호출 오류: $e');
      return false;
    }
  }

  /// 영업정보 조회
  /// 고객번호로 영업정보를 조회합니다.
  static Future<SalesInfo?> getSalesInfo(String customerNumber) async {
    try {
      // 고객번호 유효성 검사
      if (customerNumber.isEmpty) {
        print('영업정보 조회 실패: 고객번호가 비어있습니다.');
        return null;
      }

      final httpClient = _createHttpClient();
      final encodedNumber = Uri.encodeComponent(customerNumber);
      final uri = Uri.parse(
        'https://localhost:7088/api/관제고객/sales-info/$encodedNumber',
      );

      print('영업정보 조회 API 호출: $uri (고객번호: $customerNumber)');

      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        final Map<String, dynamic> jsonData = json.decode(responseBody);
        return SalesInfo.fromJson(jsonData);
      } else if (response.statusCode == 503) {
        // ERP DB 연결 오류
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        print('ERP DB 연결 오류: $responseBody');
        throw Exception('ERP_DB_NOT_CONNECTED');
      } else if (response.statusCode == 404) {
        print('영업정보를 찾을 수 없음: $customerNumber');
        return null;
      } else {
        print('영업정보 조회 오류: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('영업정보 조회 API 호출 오류: $e');
      rethrow; // Exception을 다시 던짐
    }
  }

  /// 최근수금이력 조회
  /// 고객번호로 최근수금이력을 조회합니다.
  static Future<List<PaymentHistory>> getPaymentHistory(
    String customerNumber,
  ) async {
    try {
      // 고객번호 유효성 검사
      if (customerNumber.isEmpty) {
        print('최근수금이력 조회 실패: 고객번호가 비어있습니다.');
        return [];
      }

      final httpClient = _createHttpClient();
      final encodedNumber = Uri.encodeComponent(customerNumber);
      final uri = Uri.parse(
        'https://localhost:7088/api/관제고객/payment-history/$encodedNumber',
      );

      print('최근수금이력 조회 API 호출: $uri (고객번호: $customerNumber)');

      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        final List<dynamic> jsonList = json.decode(responseBody);
        return jsonList.map((json) => PaymentHistory.fromJson(json)).toList();
      } else if (response.statusCode == 503) {
        // ERP DB 연결 오류
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        print('ERP DB 연결 오류: $responseBody');
        throw Exception('ERP_DB_NOT_CONNECTED');
      } else if (response.statusCode == 404) {
        print('최근수금이력을 찾을 수 없음: $customerNumber');
        return [];
      } else {
        print('최근수금이력 조회 오류: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('최근수금이력 조회 API 호출 오류: $e');
      rethrow; // Exception을 다시 던짐
    }
  }

  /// 최근 방문 및 A/S이력 조회
  /// 고객번호로 최근 방문 및 A/S이력을 조회합니다.
  static Future<List<VisitAsHistory>> getVisitAsHistory(
    String customerNumber,
  ) async {
    try {
      // 고객번호 유효성 검사
      if (customerNumber.isEmpty) {
        print('최근 방문 및 A/S이력 조회 실패: 고객번호가 비어있습니다.');
        return [];
      }

      final httpClient = _createHttpClient();
      final encodedNumber = Uri.encodeComponent(customerNumber);
      final uri = Uri.parse(
        'https://localhost:7088/api/관제고객/visit-as-history/$encodedNumber',
      );

      print('최근 방문 및 A/S이력 조회 API 호출: $uri (고객번호: $customerNumber)');

      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        final List<dynamic> jsonList = json.decode(responseBody);
        return jsonList.map((json) => VisitAsHistory.fromJson(json)).toList();
      } else if (response.statusCode == 503) {
        // ERP DB 연결 오류
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        print('ERP DB 연결 오류: $responseBody');
        throw Exception('ERP_DB_NOT_CONNECTED');
      } else if (response.statusCode == 404) {
        print('최근 방문 및 A/S이력을 찾을 수 없음: $customerNumber');
        return [];
      } else {
        print('최근 방문 및 A/S이력 조회 오류: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('최근 방문 및 A/S이력 조회 API 호출 오류: $e');
      rethrow; // Exception을 다시 던짐
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
