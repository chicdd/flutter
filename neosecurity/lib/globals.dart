// lib/globals.dart
library globals;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

String syscode = ""; //개통코드
String company = ""; //업체명
String sendPhone = ""; //발송전화번호
String monnum = ""; //관제관리번호
String yongnum = ""; //영업관리번호
String state = ""; //고객 경계상태
String certNumber = ""; //인증번호
String message = ""; //인증발송메세지
String phoneCode = ""; //휴대폰번호
String centerPhone = ""; //고객센터전화번호
String selectedOption = "";
DateTime day_start = DateTime.now().subtract(Duration(days: 7)); //조회시작날짜
DateTime day_end = DateTime.now(); //조회끝날짜
String mi_check = ""; //청구구분
int isfirst = 1; //Home에 최초 접속했을 때만 고객리스트, 회사정보 등 불러오기위해 두번째 접속부터 불러오지않기위함.
String isremote = ""; //Home에 최초 접속했을 때만 고객리스트, 회사정보 등 불러오기위해 두번째 접속부터 불러오지않기위함.
int tabSecurityIndex = 0; //하단 바 화면 인덱스
int tabERPIndex = 0; //하단 바 화면 인덱스
int cusIndex = 0; //거래처 선택 인덱스
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
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

String defaultSelectText = "거래처선택";
int selectInt = 0;
int erpselectInt = 0;

//-관제업체들 저장되는 리스트-
List<String> secuBasicList = [];
List<String> erpCusInfoList = [];
List<Map<String, String>> userList = [];
List<Map<String, String>> signalList = [];
List<Map<String, String>> dvrList = [];
List<Map<String, String>> claimList = [];
List<Map<String, String>> billList = [];
List<Map<String, String>> cusList = [];
List<Map<String, String>> erpList = [];
List<Map<String, String>> noticeList = [];
Map<String, String> stateList = {};

final List<String> signList = ['전체신호', '경계', '해제', '문열림'];

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
  '해약정산비',
]; //매출종류
final List<String> claimClassList = ['전체', '미납', '수금']; //청구구분

//관제 및 영업정보 페이징
final List<String> securityPageList = ['가입정보', '신호내역', 'DVR'];
final List<String> cusPageList = ['가입정보', '청구내역', '계산서'];

//라디오버튼
final List<String> periodList = ['지정기간', '전체기간'];
final List<String> sortOrderList = ['최신순', '과거순'];

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

final Map<String, String> stateMatchingModel = {
  '경계': '해제',
  '해제': '경계',
  '문열림': '문닫힘',
  '문닫힘': '문열림',
};

final Map<String, String> remoteModel = {
  '해제': '0',
  '경계': '1',
  '문열림': '7',
  '문닫힘': '8',
};
