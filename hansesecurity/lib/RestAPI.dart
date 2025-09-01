import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'functions.dart';

class RestApiService {
  static final RestApiService _instance = RestApiService._internal();
  factory RestApiService() => _instance;
  RestApiService._internal();

  Future<String> sendSMS(
    String syscode,
    String send_phone,
    String receive_phone,
    String message,
  ) async {
    final String baseUrl =
        "http://neodecisions.com/androidwebservice/WebPage/ServiceCustomerTest.asmx";
    final String page = "sms_certification";

    final url = Uri.parse(
      "$baseUrl/$page?syscode=$syscode&send_phone=$send_phone&receive_phone=$receive_phone&message=$message",
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final document = XmlDocument.parse(response.body);
      final result = document.findAllElements('string').first.innerText;
      print('응답 결과: $result');
      return result; // 예: "1" 또는 오류 메시지
    } else {
      throw Exception('SMS 전송 실패: ${response.statusCode}');
    }
  }

  Future<List<String>> secuBasicRequest(
    String syscode,
    String monnum,
    String phonecode,
  ) async {
    final String baseUrl =
        "http://neodecisions.com/androidwebservice/WebPage/ServiceCustomerTest.asmx";
    final String page = "moncustsearch";

    final url = Uri.parse(
      "$baseUrl/$page?syscode=$syscode&monnum=$monnum&phonecode=$phonecode",
    );
    final response = await http.get(url);
    print(url);
    if (response.statusCode == 200) {
      final document = XmlDocument.parse(response.body);
      final result = document.findAllElements('리턴관제마스터').first;
      final secuName = result.getElement('관제상호')?.innerText.trim() ?? '';
      //데이트 파싱하고 다시 문자열로
      final date = dateconvert(
        result.getElement('개통일자')?.innerText.trim() ?? '',
      );
      return [secuName, date];
    } else {
      throw Exception('API 호출 실패: ${response.statusCode}');
    }
  }

  Future<List<Map<String, String>>> userListRequest(
    String syscode,
    String custnum,
    String phonecode,
  ) async {
    final String baseUrl =
        "http://neodecisions.com/androidwebservice/WebPage/ServiceCustomerTest.asmx";
    final String page = "monuser";

    final url = Uri.parse(
      "$baseUrl/$page?syscode=$syscode&custnum=$custnum&phonecode=$phonecode",
    );
    ////print(url);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final document = XmlDocument.parse(response.body);
      final elements = document.findAllElements('리턴유저마스터');

      List<Map<String, String>> userList =
          elements.map((element) {
            final name = element.getElement('사용자명')?.innerText.trim() ?? '';
            final phone = element.getElement('휴대전화')?.innerText.trim() ?? '';
            return {'name': name, 'phone': phone};
          }).toList();

      return userList;
    } else {
      throw Exception('API 호출 실패: ${response.statusCode}');
    }
  }

  Future<List<Map<String, String>>> signListRequest(
    String syscode,
    String monnum,
    String day_start,
    String day_end,
    String phonecode,
  ) async {
    day_start = dateconvert(day_start);
    day_end = dateconvert(day_end);
    //print("day_start = " + day_start);
    //print("day_end = " + day_end);
    final String baseUrl =
        "http://neodecisions.com/androidwebservice/WebPage/ServiceCustomerTest.asmx";
    final String page = "monsinho";

    final url = Uri.parse(
      "$baseUrl/$page?syscode=$syscode&monnum=$monnum&day_start=$day_start&day_end=$day_end&phonecode=$phonecode",
    );
    //print(url);
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final document = XmlDocument.parse(response.body);
      final elements = document.findAllElements('리턴신호마스터');

      List<Map<String, String>> signalList =
          elements.map((element) {
            final date = dateconvert(
              element.getElement('수신일자')?.innerText.trim() ?? '',
            );
            final time = element.getElement('수신시간')?.innerText.trim() ?? '';
            final signalName =
                element.getElement('신호명')?.innerText.trim() ?? '';
            final user = element.getElement('관제자')?.innerText.trim() ?? '';
            return {
              'date': date,
              'time': time,
              'signalName': signalName,
              'user': user,
            };
          }).toList();
      return signalList;
    } else {
      throw Exception('API 호출 실패: ${response.statusCode}');
    }
  }

  Future<List<Map<String, String>>> dvrListRequest(
    String syscode,
    String monnum,
    String phonecode,
  ) async {
    final String baseUrl =
        "http://neodecisions.com/androidwebservice/WebPage/ServiceCustomerTest.asmx";
    final String page = "mondvr";

    final url = Uri.parse(
      "$baseUrl/$page?syscode=$syscode&monnum=$monnum&phonecode=$phonecode",
    );
    final response = await http.get(url);
    //print(url);
    if (response.statusCode == 200) {
      final document = XmlDocument.parse(response.body);
      final elements = document.findAllElements('리턴DVR마스터');

      List<Map<String, String>> dvrList =
          elements.map((element) {
            final dvrClass =
                element.getElement('DVR종류')?.innerText.trim() ?? '';
            final connectionIP =
                element.getElement('접속주소')?.innerText.trim() ?? '';
            return {'dvrClass': dvrClass, 'connectionIP': connectionIP};
          }).toList();

      return dvrList;
    } else {
      throw Exception('API 호출 실패: ${response.statusCode}');
    }
  }

  //영업고객리스트 불러오기
  Future<List<Map<String, String>>> erpCusListRequest(
    String syscode,
    String phonecode,
  ) async {
    final String baseUrl =
        "http://neodecisions.com/androidwebservice/WebPage/ServiceCustomerTest.asmx";
    final String page = "yong_custlist_V1";

    final url = Uri.parse(
      "$baseUrl/$page?syscode=$syscode&phonecode=$phonecode",
    );
    print(url);
    final response = await http
        .get(url)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('API 호출 타임아웃');
          },
        );

    if (response.statusCode == 200) {
      final document = XmlDocument.parse(response.body);
      final elements = document.findAllElements('리턴고객마스터');

      List<Map<String, String>> erpCusList =
          elements.map((element) {
            final yongnum = element.getElement('고객번호')?.innerText.trim() ?? '';
            final name = element.getElement('상호명')?.innerText.trim() ?? '';
            return {'yongnum': yongnum, 'name': name};
          }).toList();
      print('erpCusList$erpCusList');
      return erpCusList;
    } else {
      throw Exception('API 호출 실패: ${response.statusCode}');
    }
  }

  Future<List<String>> erpCusInfoRequest(
    String syscode,
    String yongnum,
    String phonecode,
  ) async {
    final String baseUrl =
        "http://neodecisions.com/androidwebservice/WebPage/ServiceCustomerTest.asmx";
    final String page = "yongcustsearch";

    final url = Uri.parse(
      "$baseUrl/$page?syscode=$syscode&yongnum=$yongnum&phonecode=$phonecode",
    );
    print(url);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final document = XmlDocument.parse(response.body);
      final result = document.findAllElements('리턴고객마스터').first;

      final cusName = result.getElement('상호명')?.innerText.trim() ?? '';
      final setDate = dateconvert(
        result.getElement('설치일자')?.innerText.trim() ?? '',
      );
      final cusPhoneNum = result.getElement('상호전화')?.innerText.trim() ?? '';
      final payment = result.getElement('납입방법')?.innerText.trim() ?? '';
      final monthlyFee = result.getElement('월정료')?.innerText.trim() ?? '';
      final bizNum = result.getElement('공급받는자번호')?.innerText.trim() ?? '';
      final bizName = result.getElement('사업자상호')?.innerText.trim() ?? '';
      final ceoName = result.getElement('사업자대표자')?.innerText.trim() ?? '';
      final regnAdress = result.getElement('사업자주소')?.innerText.trim() ?? '';
      final bizType = result.getElement('업태')?.innerText.trim() ?? '';
      final bizClass = result.getElement('업종')?.innerText.trim() ?? '';
      final InvoiceManager = result.getElement('전자담당자')?.innerText.trim() ?? '';
      final InvoicePhone = result.getElement('전자휴대전화')?.innerText.trim() ?? '';
      final InvoiceMail = result.getElement('전자이메일')?.innerText.trim() ?? '';

      return [
        cusName,
        setDate,
        cusPhoneNum,
        payment,
        monthlyFee,
        bizNum,
        bizName,
        ceoName,
        regnAdress,
        bizType,
        bizClass,
        InvoiceManager,
        InvoicePhone,
        InvoiceMail,
      ];
    } else {
      throw Exception('API 호출 실패: ${response.statusCode}');
    }
  }

  Future<List<Map<String, String>>> claimListRequest(
    String syscode,
    String yongnum,
    String mi_check,
    String phonecode,
  ) async {
    final String baseUrl =
        "http://neodecisions.com/androidwebservice/WebPage/ServiceCustomerTest.asmx";
    final String page = "yongchargesearch";

    final url = Uri.parse(
      "$baseUrl/$page?syscode=$syscode&yongnum=$yongnum&mi_check=$mi_check&phonecode=$phonecode",
    );
    final response = await http.get(url);
    //print(url);
    if (response.statusCode == 200) {
      final document = XmlDocument.parse(response.body);
      final elements = document.findAllElements('리턴매출마스터');

      List<Map<String, String>> claimList =
          elements.map((element) {
            final claimdate =
                element.getElement('매출년월')?.innerText.trim() ?? '';
            final type = element.getElement('매출종류')?.innerText.trim() ?? '';
            final amount = element.getElement('청구금액')?.innerText.trim() ?? '';
            final date = dateconvert(
              element.getElement('납입일자')?.innerText.trim() ?? '',
            );
            final way = element.getElement('입금방법')?.innerText.trim() ?? '';
            return {
              'claimdate': claimdate,
              'type': type,
              'amount': amount,
              'date': date,
              'way': way,
            };
          }).toList();

      return claimList;
    } else {
      throw Exception('API 호출 실패: ${response.statusCode}');
    }
  }

  Future<List<Map<String, String>>> billListRequest(
    String syscode,
    String yongnum,
    String phonecode,
  ) async {
    final String baseUrl =
        "http://neodecisions.com/androidwebservice/WebPage/ServiceCustomerTest.asmx";
    final String page = "yongtaxsearch";

    final url = Uri.parse(
      "$baseUrl/$page?syscode=$syscode&yongnum=$yongnum&phonecode=$phonecode",
    );
    final response = await http.get(url);
    //print(url);
    if (response.statusCode == 200) {
      final document = XmlDocument.parse(response.body);
      final elements = document.findAllElements('리턴계산서마스터');

      List<Map<String, String>> claimList =
          elements.map((element) {
            final billdate = element.getElement('발행일자')?.innerText.trim() ?? '';
            final name = element.getElement('상호')?.innerText.trim() ?? '';
            final amount = element.getElement('합계금액')?.innerText.trim() ?? '';
            final type = element.getElement('품목')?.innerText.trim() ?? '';
            return {
              'billdate': billdate,
              'name': name,
              'amount': amount,
              'type': type,
            };
          }).toList();

      return claimList;
    } else {
      throw Exception('API 호출 실패: ${response.statusCode}');
    }
  }

  //관제고객리스트 불러오기
  Future<List<Map<String, String>>> customerRequest(
    String syscode,
    String phonecode,
  ) async {
    final String baseUrl =
        "http://neodecisions.com/androidwebservice/WebPage/ServiceCustomerTest.asmx";
    final String page = "mon_custlist_V1";

    final url = Uri.parse(
      "$baseUrl/$page?syscode=$syscode&phonecode=$phonecode",
    );
    print(url);
    //print('phonecode$phonecode');
    final response = await http
        .get(url)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('API 호출 타임아웃');
          },
        );

    if (response.statusCode == 200) {
      final document = XmlDocument.parse(response.body);
      final elements = document.findAllElements('리턴관제마스터');

      List<Map<String, String>> cusList =
          elements.map((element) {
            final monnum = element.getElement('관제관리번호')?.innerText.trim() ?? '';
            final date = element.getElement('개통일자')?.innerText.trim() ?? '';
            final line = element.getElement('사용회선종류')?.innerText.trim() ?? '';
            final name = element.getElement('관제상호')?.innerText.trim() ?? '';
            final isremote =
                element.getElement('원격경계여부')?.innerText.trim() ?? '';
            return {
              'monnum': monnum,
              'date': date,
              'line': line,
              'name': name,
              'isremote': isremote,
            };
          }).toList();

      return cusList;
    } else {
      throw Exception('API 호출 실패: ${response.statusCode}');
    }
  }

  Future<String> smartSettingRequest(String syscode, String phonecode) async {
    final String baseUrl =
        "http://neodecisions.com/androidwebservice/WebPage/ServiceCustomerTest.asmx";
    final String page = "searchsetting";

    final url = Uri.parse(
      "$baseUrl/$page?syscode=$syscode&phonecode=$phonecode",
    );
    final response = await http
        .get(url)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('API 호출 타임아웃');
          },
        );
    ;

    if (response.statusCode == 200) {
      final document = XmlDocument.parse(response.body);
      final result = document.findAllElements('리턴스마트설정마스터').first;

      final centerPhone = result.getElement('고객센터전화번호')?.innerText.trim() ?? '';
      print('centerPhone 값 : $centerPhone');
      return centerPhone;
    } else {
      throw Exception('API 호출 실패: ${response.statusCode}');
    }
  }

  //관제고객현재상태 불러오기
  Future<Map<String, String>> currentStateRequest(
    String syscode,
    String monnum,
    String phonecode,
  ) async {
    final String baseUrl =
        "http://neodecisions.com/androidwebservice/WebPage/ServiceCustomerTest.asmx";
    final String page = "moncuststatesearch";

    final url = Uri.parse(
      "$baseUrl/$page?syscode=$syscode&monnum=$monnum&phonecode=$phonecode",
    );
    print(url);
    final response = await http
        .get(url)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('API 호출 타임아웃');
          },
        );
    if (response.statusCode == 200) {
      final document = XmlDocument.parse(response.body);
      final elements = document.findAllElements('리턴상태마스터');

      // 요소가 있을 경우 첫 번째 값만 Map으로 추출
      if (elements.isNotEmpty) {
        final element = elements.first;
        final state = element.getElement('현재상태')?.innerText.trim() ?? '';
        final useline = element.getElement('사용회선종류')?.innerText.trim() ?? '';
        final remoteDeviceCode =
            element.getElement('자동원격기기코드')?.innerText.trim() ?? '';
        print(
          'state' +
              state +
              'useline' +
              useline +
              'remoteDeviceCode' +
              remoteDeviceCode,
        );
        return {
          'state': state,
          'useline': useline,
          'remoteDeviceCode': remoteDeviceCode,
        };
      } else {
        // 빈 결과 처리
        return {'state': '', 'useline': '', 'remoteDeviceCode': ''};
      }
    } else {
      throw Exception('API 호출 실패: ${response.statusCode}');
    }
  }

  //원격요청
  Future<XmlDocument> remoteRequest(
    String syscode,
    String monnum,
    String state,
    String requestreason,
    String phonecode,
  ) async {
    final String baseUrl =
        "http://neodecisions.com/androidwebservice/WebPage/ServiceCustomerTest.asmx";
    final String page = "remoterequest";
    print(
      'syscode : ' +
          syscode +
          ', monnum : ' +
          monnum +
          ', state : ' +
          state +
          ', requestreason : ' +
          requestreason +
          ', phonecode : ' +
          phonecode,
    );
    final url = Uri.parse(
      "$baseUrl/$page?syscode=$syscode&monnum=$monnum&state=$state&requestreason=$requestreason&phonecode=$phonecode",
    );
    //print(url);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final document = XmlDocument.parse(response.body);
      return document;
    } else {
      throw Exception('API 호출 실패: ${response.statusCode}');
    }
  }

  //관제고객이 맞는지 확인
  Future<bool> isUserConfirm(String syscode, String phonecode) async {
    final String baseUrl =
        "http://neodecisions.com/androidwebservice/WebPage/ServiceCustomerTest.asmx";
    final String page = "mon_custlist_V1";

    final url = Uri.parse(
      "$baseUrl/$page?syscode=$syscode&phonecode=$phonecode",
    );
    final response = await http.get(url);
    //print(url);

    if (response.statusCode == 200) {
      final document = XmlDocument.parse(response.body);

      // ✅ <NewDataSet xmlns=""> 태그가 존재하는지 여부 확인 후 true / false 반환
      final newDataSetExists = document
          .findAllElements('NewDataSet')
          .any((element) => element.getAttribute('xmlns') == '');

      return newDataSetExists;
    } else {
      throw Exception('API 호출 실패: ${response.statusCode}');
    }
  }
}

//공지사항 불러오기
Future<List<Map<String, String>>> noticeRequest(
  String syscode,
  String phonecode,
) async {
  final String baseUrl =
      "http://neodecisions.com/androidwebservice/WebPage/ServiceCustomerTest.asmx";
  final String page = "searchnotice";

  final url = Uri.parse("$baseUrl/$page?syscode=$syscode&phonecode=$phonecode");
  print(url);
  final response = await http
      .get(url)
      .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('API 호출 타임아웃');
        },
      );

  if (response.statusCode == 200) {
    final document = XmlDocument.parse(response.body);
    final elements = document.findAllElements('리턴공지마스터');

    List<Map<String, String>> noticeList =
        elements.map((element) {
          final number = element.getElement('ID')?.innerText.trim() ?? '';
          final body = element.getElement('내용')?.innerText.trim() ?? '';
          final time = element.getElement('입력시간')?.innerText.trim() ?? '';
          return {'number': number, 'body': body, 'time': time};
        }).toList();

    return noticeList;
  } else {
    throw Exception('API 호출 실패: ${response.statusCode}');
  }
}

// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// class Product {
//   final String remoterequestResult;
//
//   Product({required this.remoterequestResult});
//
//   factory Product.fromJson(Map<String, dynamic> json) {
//     return Product(remoterequestResult: json['remoterequestResult']);
//   }
// }
//
// class RestApiService {
//   static final RestApiService _instance = RestApiService._internal();
//   factory RestApiService() => _instance;
//   RestApiService._internal();
//
//   Future<List<Product>> fetchAlbums() async {
//     final queryParameters = {
//       'syscode': '02121162',
//       'monnum': ' ',
//       'state': '1',
//       'requestreason': ' ',
//       'phonecode': '01057108861',
//     };
//     final response = await http
//         .get(
//           Uri.http(
//             'neodecisions.com',
//             '/androidwebservice/WebPage/ServiceCustomerTest.asmx/remoterequest',
//             queryParameters,
//           ),
//         )
//         .timeout(Duration(seconds: 10));
//     print(Uri.http.toString());
//     print(response.statusCode);
//     print(response.body);
//     if (response.statusCode == 200) {
//       List<dynamic> jsonList = json.decode(response.body);
//       return jsonList.map((e) => Product.fromJson(e)).toList();
//     } else {
//       throw Exception('Failed to fetch albums');
//     }
//   }
//
//   void main() async {
//     List<Product> Products = await fetchAlbums();
//
//     for (var product in Products) {
//       print('remoterequestResult: ${product.remoterequestResult}');
//     }
//   }
// }
//
// // Future<List<Product>> fetchProducts() async {
// //   final queryParameters = {
// //     'syscode': '02121162',
// //     'monnum': '',
// //     'state': '1',
// //     'requestreason': '',
// //     'phonecode': '01057108861',
// //   };
// //
// //   final uri = Uri.http(
// //     'neodecisions.com', // 도메인
// //     '/androidwebservice/WebPage/ServiceCustomerTest.asmx/remoterequest', // 경로
// //     queryParameters,
// //   );
// //
// //   final response = await http.get(uri).timeout(const Duration(seconds: 5));
// //
// //   if (response.statusCode == 200) {
// //     // 결과 처리
// //     print(response.body); // 필요 시 JSON 디코딩 등
// //     return [];
// //   } else {
// //     throw Exception('Failed to fetch products');
// //   }
// // }
