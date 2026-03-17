import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../config/api_config.dart';
import '../models/search_panel.dart';
import '../models/customer_detail.dart';
import '../models/customerHoliday.dart';
import '../models/additional_service.dart';
import '../models/dvr_info.dart';
import '../models/authRegist.dart';
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
import 'user_service.dart';

class DatabaseService {
  static String url = ApiConfig().Url;
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

      // 현재 로그인한 사용자의 지역코드 조회
      final regionCode = await UserService.getRegionCode();

      // 지역코드가 있으면 쿼리 파라미터에 추가
      final uri = regionCode != null && regionCode.isNotEmpty
          ? Uri.parse(
              '$url/api/top',
            ).replace(queryParameters: {'regionCode': regionCode})
          : Uri.parse('$url/api/top');

      final request = await httpClient.getUrl(uri);
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
      final uri = Uri.parse('$url/api/Update/$managementNumber');
      print('기본 고객 정보 수정 API 호출: $uri');

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

  /// 확장 고객 정보 수정 (기본 고객 정보와 동일한 API 사용)
  static Future<bool> updateExtendedCustomerInfo({
    required String managementNumber,
    required Map<String, dynamic> data,
  }) async {
    try {
      final httpClient = DatabaseService._createHttpClient();
      final uri = Uri.parse('$url/api/Update/$managementNumber');
      print(data);
      print('확장 고객 정보 수정 API 호출: $uri');

      final request = await httpClient.putUrl(uri);
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.write(json.encode(data));
      print(json.encode(data));
      final response = await request.close();
      final String responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        print('확장 고객 정보 수정 성공');
        return true;
      } else {
        print('확장 고객 정보 수정 실패: ${response.statusCode}, $responseBody');
        return false;
      }
    } catch (e) {
      print('확장 고객 정보 수정 API 호출 오류: $e');
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

      // 현재 로그인한 사용자의 지역코드 조회
      final regionCode = await UserService.getRegionCode();

      // URL 인코딩을 위한 파라미터 구성
      final queryParams = {
        'filterType': filterType,
        'query': query,
        'sortType': sortType,
        'count': count.toString(),
      };

      // 지역코드가 있으면 추가
      if (regionCode != null && regionCode.isNotEmpty) {
        queryParams['regionCode'] = regionCode;
      }

      final uri = Uri.parse(
        '$url/api/search',
      ).replace(queryParameters: queryParams);
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
      final uri = Uri.parse('$url/api/$encodedNumber');

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

  // 관제관리번호로 고객 정보 저장
  static Future<bool> insertCustomer({
    required String managementNumber,
    required Map<String, dynamic> data,
  }) async {
    try {
      final httpClient = _createHttpClient();
      final encodedNumber = Uri.encodeComponent(managementNumber);
      final uri = Uri.parse('$url/api/Insert/$encodedNumber');

      print('관제 고객 저장 API 호출: $uri');

      final request = await httpClient.postUrl(uri);
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.write(json.encode(data));
      print(json.encode(data));
      final response = await request.close();
      final String responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        print('관제 고객 저장 성공');
        return true;
      } else {
        print('관제 고객 저장 실패: ${response.statusCode}, $responseBody');
        return false;
      }
    } catch (e) {
      print('관제 고객 저장 API 호출 오류: $e');
      return false;
    }
  }

  // 관제관리번호로 휴일주간 정보 조회
  static Future<List<CustomerHoliday>> getHoliday(
    String managementNumber,
  ) async {
    try {
      final httpClient = _createHttpClient();
      final encodedNumber = Uri.encodeComponent(managementNumber);
      final uri = Uri.parse('$url/api/휴일주간리스트/$encodedNumber');

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
      final uri = Uri.parse('$url/api/부가서비스조회/$encodedNumber');

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
      final uri = Uri.parse('$url/api/DVR조회/$encodedNumber');

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
      final uri = Uri.parse('$url/api/스마트폰인증번호조회/$encodedNumber');

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
      final uri = Uri.parse('$url/api/Dropdown/$codeType');

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
      final uri = Uri.parse('$url/api/사용자정보/$encodedNumber');

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
      final uri = Uri.parse('$url/api/존정보/$encodedNumber');

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
      final uri = Uri.parse('$url/api/문서리스트/$encodedNumber');

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

      final uri = Uri.parse('$url/api/최근신호/$encodedNumber/').replace(
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
      final uri = Uri.parse('$url/api/관제개시조회/$encodedNumber');

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
      final request = await httpClient.postUrl(Uri.parse('$url/api/관제개시정보추가'));

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
      final uri = Uri.parse('$url/api/보수점검조회/$encodedNumber');

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
      final request = await httpClient.postUrl(Uri.parse('$url/api/보수점검추가'));

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

      final uri = Uri.parse('$url/api/검색로그내역조회/$encodedNumber').replace(
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

      final uri = Uri.parse('$url/api/고객정보변동이력/$encodedNumber').replace(
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
      final uri = Uri.parse('$url/api/약도조회/$encodedNumber');

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

  /// 약도 이미지 업데이트 & 업데이트 안 됐으면 인서트
  ///
  /// [managementNumber] - 관제관리번호
  /// [mapDiagramImage] - 약도 이미지 바이트 데이터
  /// 반환: bool - 성공 여부
  static Future<bool> updateMapDiagram({
    required String managementNumber,
    required Uint8List mapDiagramImage,
  }) async {
    try {
      print('약도 업데이트 요청: 관제관리번호=$managementNumber');

      final encodedNumber = Uri.encodeComponent(managementNumber);
      final uri = Uri.parse('$url/api/Update/약도업데이트/$encodedNumber');

      final client = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final request = await client.putUrl(uri);
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      // 이미지를 Base64로 인코딩하여 JSON으로 전송
      final base64Image = base64Encode(mapDiagramImage);
      final body = json.encode({
        '관제관리번호': managementNumber,
        '약도데이터': base64Image,
      });

      request.write(body);

      final response = await request.close();

      if (response.statusCode == 200) {
        print('약도 업데이트 성공: 관제관리번호=$managementNumber');
        return true;
      } else {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        print('약도 업데이트 오류: ${response.statusCode}, $responseBody');
        return false;
      }
    } catch (e) {
      print('약도 업데이트 API 호출 오류: $e');
      return false;
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
      final uri = Uri.parse('$url/api/도면조회/$encodedNumber');

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

  /// 도면 이미지 업데이트 & 업데이트 안 됐으면 인서트
  ///
  /// [managementNumber] - 관제관리번호
  /// [blueprintImage] - 도면 이미지 바이트 데이터
  /// [blueprintType] - 도면 타입 ('1': 도면마스터, '2': 도면마스터2)
  /// 반환: bool - 성공 여부
  static Future<bool> updateBlueprint({
    required String managementNumber,
    required Uint8List blueprintImage,
    required String blueprintType,
  }) async {
    try {
      print('도면 업데이트 요청: 관제관리번호=$managementNumber, 도면타입=$blueprintType');

      final encodedNumber = Uri.encodeComponent(managementNumber);
      final uri = Uri.parse('$url/api/Update/도면업데이트/$encodedNumber');

      final client = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final request = await client.putUrl(uri);
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      // 이미지를 Base64로 인코딩하여 JSON으로 전송
      final base64Image = base64Encode(blueprintImage);
      final body = json.encode({
        '관제관리번호': managementNumber,
        '도면데이터': base64Image,
        '도면타입': blueprintType,
      });

      request.write(body);

      final response = await request.close();

      if (response.statusCode == 200) {
        print('도면 업데이트 성공: 관제관리번호=$managementNumber, 도면타입=$blueprintType');
        return true;
      } else {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        print('도면 업데이트 오류: ${response.statusCode}, $responseBody');
        return false;
      }
    } catch (e) {
      print('도면 업데이트 API 호출 오류: $e');
      return false;
    }
  }

  /// AS접수 정보 조회
  /// 관제관리번호로 AS접수 정보를 조회합니다.
  static Future<List<AsLog>> getASLog(String managementNumber) async {
    try {
      final httpClient = _createHttpClient();
      final encodedNumber = Uri.encodeComponent(managementNumber);
      final uri = Uri.parse('$url/api/AS조회/$encodedNumber');

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
        Uri.parse('$url/api/Insert/aslog'),
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
      final uri = Uri.parse('$url/api/영업정보/$encodedNumber');

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
      final uri = Uri.parse('$url/api/최근수금이력/$encodedNumber');

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
      final uri = Uri.parse('$url/api/방문AS조회/$encodedNumber');

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

  /// 개통코드 검증
  /// 개통코드로 개통업체 정보를 검증합니다.
  static Future<Map<String, dynamic>?> verifyOpeningCode(String code) async {
    try {
      final httpClient = _createHttpClient();
      final encodedCode = Uri.encodeComponent(code);
      final uri = Uri.parse('$url/api/개통코드인증/$encodedCode');

      print('개통코드 검증 API 호출: $uri');

      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        final Map<String, dynamic> jsonData = json.decode(responseBody);
        print('개통코드 검증 성공: ${jsonData['개통업체명']}');
        return jsonData;
      } else if (response.statusCode == 404) {
        print('개통코드가 일치하지 않습니다: $code');
        return null;
      } else {
        print('개통코드 검증 오류: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('개통코드 검증 API 호출 오류: $e');
      return null;
    }
  }

  /// 로그인 검증
  /// ID와 비밀번호로 로그인을 검증합니다.
  static Future<Map<String, dynamic>?> login({
    required String id,
    required String password,
  }) async {
    try {
      final httpClient = _createHttpClient();
      final uri = Uri.parse('$url/api/로그인');

      print('로그인 API 호출: $uri');

      final request = await httpClient.postUrl(uri);
      request.headers.set('Content-Type', 'application/json; charset=utf-8');

      final body = json.encode({'Id': id, 'Password': password});

      request.write(body);
      final response = await request.close();
      final String responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(responseBody);
        print('로그인 성공: ${jsonData['성명']}');
        return jsonData;
      } else if (response.statusCode == 401) {
        final Map<String, dynamic> errorData = json.decode(responseBody);
        print('로그인 실패: ${errorData['message']}');
        return {'error': errorData['message']};
      } else {
        print('로그인 오류: ${response.statusCode}, $responseBody');
        return {'error': '서버 오류가 발생했습니다.'};
      }
    } catch (e) {
      print('로그인 API 호출 오류: $e');
      return {'error': '네트워크 오류가 발생했습니다.'};
    }
  }

  /// 부가서비스 추가
  static Future<bool> insertAdditionalService({
    required String controlManagementNumber,
    required String serviceCode,
    String? serviceEtcCode,
    required String serviceDate,
    String? memo,
  }) async {
    try {
      final httpClient = DatabaseService._createHttpClient();
      final uri = Uri.parse('$url/api/Insert/additionalservice');

      print('부가서비스 추가 API 호출: $uri');
      print('관제관리번호: $controlManagementNumber, 부가서비스코드: $serviceCode');

      final request = await httpClient.postUrl(uri);
      request.headers.set('Content-Type', 'application/json; charset=utf-8');

      // 날짜를 DateTime으로 파싱하여 전송
      DateTime? parsedDate;
      try {
        parsedDate = DateTime.parse(serviceDate);
      } catch (e) {
        print('날짜 파싱 오류: $e');
        return false;
      }

      final body = json.encode({
        '관제관리번호': controlManagementNumber,
        '부가서비스코드': serviceCode,
        '부가서비스제공코드': serviceEtcCode,
        '부가서비스일자': parsedDate.toIso8601String(),
        '추가메모': memo,
      });

      request.write(body);
      final response = await request.close();

      if (response.statusCode == 201) {
        print('부가서비스 추가 성공');
        return true;
      } else {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        print('부가서비스 추가 오류: ${response.statusCode}, $responseBody');
        return false;
      }
    } catch (e) {
      print('부가서비스 추가 API 호출 오류: $e');
      return false;
    }
  }

  /// DVR 연동 정보 추가
  static Future<bool> insertDVR({
    required String controlManagementNumber,
    required int connectionMethod, // 0: CS방식, 1: 웹방식
    required String dvrTypeCode,
    required String connectionAddress,
    String? connectionPort,
    String? connectionId,
    String? connectionPassword,
    String? serialNumber,
  }) async {
    try {
      final httpClient = DatabaseService._createHttpClient();
      final uri = Uri.parse('$url/api/Insert/dvr');

      print('DVR 연동 정보 추가 API 호출: $uri');
      print('관제관리번호: $controlManagementNumber, 접속방식: $connectionMethod');

      final request = await httpClient.postUrl(uri);
      request.headers.set('Content-Type', 'application/json; charset=utf-8');

      final body = json.encode({
        '관제관리번호': controlManagementNumber,
        '접속방식': connectionMethod,
        'DVR종류코드': dvrTypeCode,
        '접속주소': connectionAddress,
        '접속포트': connectionPort,
        '접속ID': connectionId,
        '접속암호': connectionPassword,
        '일련번호': serialNumber,
      });

      request.write(body);
      final response = await request.close();

      if (response.statusCode == 201) {
        print('DVR 연동 정보 추가 성공');
        return true;
      } else {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        print('DVR 연동 정보 추가 오류: ${response.statusCode}, $responseBody');
        return false;
      }
    } catch (e) {
      print('DVR 연동 정보 추가 API 호출 오류: $e');
      return false;
    }
  }

  /// 부가서비스 삭제
  static Future<bool> deleteAdditionalService({
    required int managementId,
  }) async {
    try {
      final httpClient = DatabaseService._createHttpClient();
      final uri = Uri.parse('$url/api/Delete/additionalservice/$managementId');

      print('부가서비스 삭제 API 호출: $uri');

      final request = await httpClient.deleteUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        print('부가서비스 삭제 성공');
        return true;
      } else {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        print('부가서비스 삭제 오류: ${response.statusCode}, $responseBody');
        return false;
      }
    } catch (e) {
      print('부가서비스 삭제 API 호출 오류: $e');
      return false;
    }
  }

  /// DVR 삭제
  static Future<bool> deleteDVR({required int serialNumber}) async {
    try {
      final httpClient = DatabaseService._createHttpClient();
      final uri = Uri.parse('$url/api/Delete/dvr/$serialNumber');

      print('DVR 삭제 API 호출: $uri');

      final request = await httpClient.deleteUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        print('DVR 삭제 성공');
        return true;
      } else {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        print('DVR 삭제 오류: ${response.statusCode}, $responseBody');
        return false;
      }
    } catch (e) {
      print('DVR 삭제 API 호출 오류: $e');
      return false;
    }
  }

  /// 주간휴일설정 저장
  static Future<bool> updateHolidayWeek({
    required String managementNumber,
    required List<String> holidayCodes,
  }) async {
    try {
      final httpClient = DatabaseService._createHttpClient();
      final uri = Uri.parse('$url/api/Update/holiday');

      print('주간휴일설정 저장 API 호출: $uri');
      print('관제관리번호: $managementNumber, 휴일코드수: ${holidayCodes.length}');

      final request = await httpClient.postUrl(uri);
      request.headers.set('Content-Type', 'application/json; charset=utf-8');

      final body = json.encode({
        '관제관리번호': managementNumber,
        '휴일주간코드목록': holidayCodes,
      });

      request.write(body);
      final response = await request.close();

      if (response.statusCode == 200) {
        print('주간휴일설정 저장 성공');
        return true;
      } else {
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();
        print('주간휴일설정 저장 오류: ${response.statusCode}, $responseBody');
        return false;
      }
    } catch (e) {
      print('주간휴일설정 저장 API 호출 오류: $e');
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
      final uri = Uri.parse('$url/api/Import/document');

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
      final uri = Uri.parse('$url/api/Insert/auth');

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
  static String url = ApiConfig().Url;

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
      final uri = Uri.parse('$url/api/Insert/$typeName');

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
        '$url/api/Delete/$typeName',
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
}
