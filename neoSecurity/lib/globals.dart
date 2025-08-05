// lib/globals.dart
library globals;

import 'package:xml/xml.dart';

//개통코드
String syscode = "62083651";
//발송전화번호
String sendPhone = "16669112";
String monnum = "KJ5897-00";
String yongnum = "202300002";
String certNumber = "";
String message = "";
String phoneCode = "01057108861";
String centerPhone = "";
DateTime day_start = DateTime.now().subtract(Duration(days: 7));
DateTime day_end = DateTime.now();
String mi_check = "";

int tabSecurityIndex = 0; //하단 바 화면 인덱스
int tabERPIndex = 0; //하단 바 화면 인덱스
int cusIndex = 0; //거래처 선택 인덱스

//신호검색필터
int periodIndex = 0;
int sortOrderIndex = 0;
int signIndex = 0; //신호 선택 인덱스(모달 창 적용 누르기 전)
int signalClassIndex = 0;

//청구내역필터
int claimPeriodIndex = 0;
int claimSortOrderIndex = 0;
int claimClassIndex = 0;

int salesIndex = 0;
int salesClassIndex = 0;
int depositIndex = 0;
int depositClassIndex = 0;

int billPeriodIndex = 0;
int billSortOrderIndex = 0;
int billIndex = 0; //신호 선택 인덱스(모달 창 적용 누르기 전)
int billClassIndex = 0;

//사용안함
int claimIndex = 0;

class SMSReceive {
  final String check;

  SMSReceive({required this.check});

  factory SMSReceive.fromXml(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    final element = document.getElement('string');
    final value = element?.innerText ?? '';
    return SMSReceive(check: value);
  }
}

class Customer {
  final String code;
  final String name;

  Customer({required this.code, required this.name});

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      code: json['거래처코드'] as String? ?? '',
      name: json['거래처명'] as String? ?? '',
    );
  }
}

class Manager {
  final String code;
  final String name;

  Manager({required this.code, required this.name});

  factory Manager.fromJson(Map<String, dynamic> json) {
    return Manager(
      code: json['담당자코드'] as String? ?? '',
      name: json['담당자명'] as String? ?? '',
    );
  }
}

class BasicInfo {
  final String customer;
  final String date;

  BasicInfo({required this.customer, required this.date});
}

// class UserInfo {
//   final String name;
//   final String phone;
//
//   UserInfo({required this.name, required this.phone});
// }

String defaultSelectText = "거래처선택";
int selectInt = 0;

//-관제업체들 저장되는 리스트-
List<String> secuBasicList = [];
List<Map<String, String>> userList = [];
List<Map<String, String>> signalList = [];
List<Map<String, String>> dvrList = [];
List<String> erpCusInfoList = [];
List<Map<String, String>> claimList = [];
List<Map<String, String>> billList = [];
List<Customer> customerList = [];
List<Manager> managerList = [];
List<Map<String, String>> cusList = [];
//유저내역
//List<Map<String, String>> userList = [];
//신호내역
// List<Map<String, String>> signalList = [];

List<String> signList = [];

final List<String> billClassList = ['전체', '월정료', '공사비', '위약금'];
final List<String> depositList = [
  '전체',
  'CMS',
  '무통장입금',
  '카드결제',
  '방문수금',
  '요금면제',
]; //입금방법
final List<String> salesList = [
  '전체',
  '월정료',
  '위약금',
  'CCTV공사비',
  '해지철거비',
  '보증금',
]; //매출종류
final List<String> claimClassList = ['전체', '미납', '수금']; //청구구분

//관제 및 영업정보 페이징
final List<String> securityPageList = ['가입정보', '신호내역', 'DVR'];
final List<String> cusPageList = ['가입정보', '청구내역', '계산서'];

//라디오버튼
final List<String> periodList = ['지정기간', '전체기간'];
final List<String> sortOrderList = ['최신순', '과거순'];
