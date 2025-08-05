// lib/globals.dart
library globals;

String defaultSelectText = "거래처선택";
String selectIndex = '';

// class Customer {
//   final String code;
//   final String name;
//
//   Customer({required this.code, required this.name});
//
//   factory Customer.fromJson(Map<String, dynamic> json) {
//     return Customer(
//       code: json['거래처코드'] as String? ?? '',
//       name: json['거래처명'] as String? ?? '',
//     );
//   }
// }

late Future<List<DynamicModel>> dynamicList;

class DynamicModel {
  final Map<String, String> data;

  DynamicModel({required this.data});

  factory DynamicModel.fromJson(Map<String, dynamic> json) {
    final parsed = json.map((key, value) => MapEntry(key, value.toString()));
    return DynamicModel(data: parsed);
  }

  static List<DynamicModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => DynamicModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

Map<String, List<Map<String, String>>> globalListMap = {
  'customer': [],
  'manager': [],
};
// final List<String> listSample = [
//   '전체신호',
//   '경계',
//   '해제',
//   '원격경계',
//   '원격해제',
//   '원격경계요청',
//   '원격해제요청',
// ];
// final List<String> target = [
//   '전체신호',
//   '경계',
//   '해제',
//   '원격경계',
//   '원격해제',
//   '원격경계요청',
//   '원격해제요청',
// ];

// final List<String> billList = ['월정료', '공사비', '위약금'];
// final List<String> depositList = ['전체', 'CMS', '무통장입금', '카드결제', '방문수금'];
// final List<String> salesList = ['전체', '월정료', '위약금', 'CCTV공사비', '해지철거비'];
// final List<String> claimList = ['전체', '수금', '미납'];
//
// //관제 및 영업정보 페이징
// final List<String> securityPageList = ['가입정보', '신호내역', 'DVR'];
// final List<String> cusPageList = ['가입정보', '청구내역', '계산서'];
//
// //라디오버튼
// final List<String> periodList = ['전체기간', '지정기간'];
// final List<String> sortOrderList = ['최신순', '과거순'];
//
// final List<Map<String, String>> signalHistory = [
//   {
//     "date": "2025-04-30",
//     "time": "06:52:38",
//     "status": "해제_[04]",
//     "user": "김정석",
//     "icon": "open",
//   },
//   {
//     "date": "2025-04-30",
//     "time": "06:52:33",
//     "status": "경계_[04]",
//     "user": "김정석",
//     "icon": "lock",
//   },
//   {
//     "date": "2025-02-30",
//     "time": "06:52:33",
//     "status": "경계_[04]",
//     "user": "김정석",
//     "icon": "lock",
//   },
//
//   {
//     "date": "2021-09-30",
//     "time": "06:52:33",
//     "status": "경계_[04]",
//     "user": "김정석",
//     "icon": "lock",
//   },
//
//   {
//     "date": "2020-04-30",
//     "time": "06:52:33",
//     "status": "경계_[04]",
//     "user": "김정석",
//     "icon": "lock",
//   },
//
//   {
//     "date": "2025-04-30",
//     "time": "06:52:33",
//     "status": "경계_[04]",
//     "user": "김정석",
//     "icon": "lock",
//   },
// ];
//
// final List<Map<String, String>> claimHistory = [
//   {
//     "date": "2025-08-20",
//     "time": "12:36:26",
//     "amount": "371,100원",
//     "Payment": "무통장입금",
//     "Sales": "위약금",
//   },
//   {
//     "date": "2025-08-12",
//     "time": "12:36:26",
//     "amount": "371,100원",
//     "Payment": "CMS",
//     "Sales": "월정료",
//   },
//   {
//     "date": "2025-07-20",
//     "time": "12:36:26",
//     "amount": "371,100원",
//     "Payment": "무통장입금",
//     "Sales": "위약금",
//   },
//
//   {
//     "date": "2025-07-01",
//     "time": "12:36:26",
//     "amount": "371,100원",
//     "Payment": "무통장입금",
//     "Sales": "위약금",
//   },
//
//   {
//     "date": "2025-06-01",
//     "time": "12:36:26",
//     "amount": "371,100원",
//     "Payment": "무통장입금",
//     "Sales": "위약금",
//   },
//
//   {
//     "date": "2025-05-20",
//     "time": "12:36:26",
//     "amount": "371,100원",
//     "Payment": "무통장입금",
//     "Sales": "위약금",
//   },
//
//   {
//     "date": "2025-01-20",
//     "time": "12:36:26",
//     "amount": "371,100원",
//     "Payment": "무통장입금",
//     "Sales": "위약금",
//   },
// ];
//
// final List<Map<String, String>> billHistory = [
//   {
//     "date": "2025-08-20",
//     "amount": "371,100원",
//     "Payment": "상무악기사",
//     "Sales": "8월 월정료",
//   },
//   {
//     "date": "2025-07-20",
//     "amount": "371,100원",
//     "Payment": "상무악기사",
//     "Sales": "8월 월정료",
//   },
//   {
//     "date": "2025-06-20",
//     "amount": "371,100원",
//     "Payment": "상무악기사",
//     "Sales": "8월 월정료",
//   },
//   {
//     "date": "2025-06-01",
//     "amount": "371,100원",
//     "Payment": "상무악기사",
//     "Sales": "8월 월정료",
//   },
//   {
//     "date": "2025-05-20",
//     "amount": "371,100원",
//     "Payment": "상무악기사",
//     "Sales": "8월 월정료",
//   },
//   {
//     "date": "2025-05-10",
//     "amount": "371,100원",
//     "Payment": "상무악기사",
//     "Sales": "8월 월정료",
//   },
//   {
//     "date": "2025-05-02",
//     "amount": "371,100원",
//     "Payment": "상무악기사",
//     "Sales": "8월 월정료",
//   },
// ];
//
// final List<Map<String, String>> dvrList = [
//   {"class": "포웬시스", "IP": "61.250.157.14"},
//   {"class": "포웬시스", "IP": "61.250.157.14"},
//   {"class": "포웬시스", "IP": "61.250.157.14"},
//   {"class": "포웬시스", "IP": "61.250.157.14"},
//   {"class": "포웬시스", "IP": "61.250.157.14"},
//   {"class": "포웬시스", "IP": "61.250.157.14"},
//   {"class": "포웬시스", "IP": "61.250.157.14"},
//   {"class": "포웬시스", "IP": "61.250.157.14"},
//   {"class": "포웬시스", "IP": "61.250.157.14"},
//   {"class": "포웬시스", "IP": "61.250.157.14"},
// ];
