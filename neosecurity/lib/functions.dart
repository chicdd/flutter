import 'package:xml/xml.dart';
import 'RestAPI.dart';
import 'globals.dart';

List<Map<String, dynamic>> buildGrouped(List<Map<String, String>> list, works) {
  final List<Map<String, dynamic>> result = [];
  String? lastMonth;

  for (var item in list) {
    final date = item[works] ?? '';
    String month = '';

    if (date.length >= 7) {
      month = date.substring(0, 7).replaceAll('-', '.');
    } else {
      // 납입일자가 없거나 짧을 경우 매출년월 기준으로 표시
      final ym = item[works] ?? '';
      if (ym.length == 6) {
        // '202507' -> '2025.07'
        month = '${ym.substring(0, 4)}.${ym.substring(4, 6)}';
      } else {
        month = '미정'; // 기타 fallback
      }
    }

    // 월이 달라지면 헤더 추가
    if (lastMonth != month) {
      result.add({'type': 'header', 'month': month});
      lastMonth = month;
    }

    // 항목 추가
    result.add({'type': 'item', 'data': item});
  }

  return result;
}

String dateconvert(String? isoDate) {
  if (isoDate == null || isoDate.trim().isEmpty) return '';
  return isoDate.split('T').first; // "2025-07-13T00:00:00+09:00" → "2025-07-13"
}

Future<void> getState() async {
  stateList = await RestApiService().currentStateRequest(
    syscode,
    monnum,
    phoneCode,
  );
  //print('globals.stateList현재값${stateList}');
  //print('새로고침됨');
  //state = stateList['state'] ?? '';
  //print('stateList[state]$state');
}

Future<void> getCenterPhone() async {
  centerPhone = await RestApiService().smartSettingRequest(syscode, phoneCode);
}

// Future<void> getCustomer() async {
//   cusList = await RestApiService().customerRequest(syscode, phoneCode);
//   // if (cusList.isNotEmpty) {
//   //   selectCusList = cusList[selectInt];
//   //   print(cusList);
//   //   monnum = selectCusList['monnum'] ?? '';
//   //   isremote = selectCusList['isremote'] ?? '';
//   //   print('monnum${monnum}');
//   // } else {
//   //   // 빈 리스트일 경우 기본값 처리
//   //   selectCusList = {};
//   //   monnum = '';
//   // }
//   print('cusList$cusList');
// }

// Future<void> getErpCustomer() async {
//   try {
//     final result = await RestApiService().erpCusListRequest(syscode, phoneCode);
//     erpList = result;
//     print('result$result');
//     selectErpList = erpList[erpselectInt];
//     yongnum = selectErpList['yongnum'] ?? '';
//   } catch (e) {
//     print("API 호출 오류: $e");
//   }
//
//   print('yongnum${yongnum}');
// }

Future<String> receiveRemote() async {
  XmlDocument result;
  result = await RestApiService().remoteRequest(
    syscode,
    monnum,
    remoteModel[state] ?? '',
    "",
    phoneCode,
  );
  print('result.toXmlString()${result.toXmlString()}');
  return parsing(result.toXmlString());
}

String getImagePath(String? state) {
  switch (state) {
    case '경계':
      return 'image/alert.jpg';
    case '해제':
      return 'image/disalert.jpg';
    //case '문열림':
    //return 'image/문열림3.jpg';
    //case '문닫힘':
    //return 'image/문닫힘3.jpg';
    default:
      return 'image/default.jpg'; // fallback 이미지
  }
}

String parsing(final xmlString) {
  final document = XmlDocument.parse(xmlString);
  final element = document.rootElement; // <string> 태그

  final text = element.text; // "반영갯수[1] 저장되었습니다."

  final regex = RegExp(r'\[(\d+)\]');
  final match = regex.firstMatch(text);

  if (match != null) {
    final numberStr = match.group(1); // "1"
    final number = int.parse(numberStr!);
    print('number.toString()$number');
    return number.toString();
  } else {
    return '원격 오류';
  }
}

Future<void> initializeData() async {
  try {
    // 1단계: 먼저 고객 리스트 가져오기
    final customers = await RestApiService().customerRequest(
      syscode,
      phoneCode,
    );
    print('customers$customers');
    cusList = customers;
    isremote = cusList[selectInt]['isremote'] ?? "";
    monnum = cusList[selectInt]['monnum'] ?? "";
    print('cusList$cusList');

    // 2단계: 첫 번째 고객 또는 선택된 고객의 상태 정보 가져오기
    if (customers.isNotEmpty) {
      final monnum = customers[0]['monnum'] ?? '';
      if (monnum.isNotEmpty) {
        stateList = await RestApiService().currentStateRequest(
          syscode,
          monnum,
          phoneCode,
        );
        // state 정보 사용
        state = stateList['state'] ?? '';
        print('state$state');
        print('monnum$monnum');
        print('isremote$isremote');
      }
    }
  } catch (e) {
    print('오류: $e');
  }
}

String getImageForGaetongCode(String syscode) {
  switch (syscode) {
    case '02111112':
      return 'image/Pocom_Logo.png';
    case '61062298':
      return 'image/C1_Logo.png';
    case '53220129':
      return 'image/Kone_Logo.png';
    case '62083651':
      return 'image/Hanse_Logo.png';
    default:
      return 'image/default.png';
  }
}
