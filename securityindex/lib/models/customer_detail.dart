import '../style.dart';

class CustomerDetail {
  // 기본 정보
  final String controlManagementNumber; // 관제관리번호
  final String? erpCusNumber; // 영업관리번호
  final String? publicLine; // 공중회선
  final String? dedicatedLine; // 전용회선
  final String? internetLine; // 인터넷회선

  // 고객 정보
  final String? controlBusinessName; // 관제상호
  final String? controlContact1; // 관제연락처1
  final String? controlContact2; // 관제연락처2
  final String? propertyAddress; // 물건주소
  final String? responsePath1; // 대처경로1
  final String? representative; // 대표자
  final String? representativeHP; // 대표자HP

  // 일자 정보
  final String? securityStartDate; // 개통일자

  // 관리 정보
  final String? managementAreaCode; // 관리구역코드
  final String? managementAreaName; // 관리구역코드명
  final String? dispatchAreaCode; // 출동권역코드
  final String? dispatchAreaName; // 출동권역코드명
  final String? vehicleCode; // 차량코드
  final String? vehicleCodeName; // 차량코드명
  final String? policeStationCode; // 경찰서코드
  final String? policeStationName; // 경찰서코드명
  final String? policeSubstationCode; // 지구대코드
  final String? policeSubstationName; // 지구대코드명
  final String? businessTypeLargeCode; // 업종대코드
  final String? businessTypeLargeName; // 업종대코드명

  // 추가 정보
  final String? arsPhoneNumber; // ARS전화번호
  final String? remotePhoneNumber; // 원격전화번호
  final String? usageLineTypeCode; // 사용회선종류코드
  final String? usageLineTypeName; // 사용회선종류명
  final String? deviceTypeCode; // 기기종류코드
  final String? deviceTypeName; // 기기종류명
  final String? unguardedTypeCode; // 미경계종류코드
  final String? unguardedTypeName; // 미경계종류코드명
  final String? remotePassword; // 원격암호
  final bool? monthlyAggregation; // 월간집계
  final String? controlAction; // 관제액션
  final bool? keyReceiptStatus; // 키인수여부
  final String? acquisition; // 인수수량
  final String? keyBoxes; // 키BOX
  final String? unguardedClassificationCode; // 미경계분류코드
  final String? unguardedClassificationName; // 미경계분류코드명
  final String? serviceTypeCode; // 서비스종류코드
  final String? serviceTypeName; // 서비스종류코드명
  final String? customerStatusCode; // 관제고객상태코드
  final String? customerStatusName; // 관제고객상태코드명
  final bool? dvrStatus; // dvr여부
  final String? gpsX1; // gpsX좌표1
  final String? gpsY1; // gpsY좌표1
  final String? gpsX2; // gpsX좌표2
  final String? gpsY2; // gpsY좌표2
  final String? wirelessSetStatus; // 무선센서설치여부
  final String? remotePort; // 원격포트
  final String? customerBusinessName; // 고객용상호
  final String? memo1; // 메모1
  final String? memo2; // 메모2
  final String? openingPhone; // 개통전화번호
  final String? modemSerial; // 모뎀일련번호
  final String? openingDate; // 개통일자
  final String? additionalMemo; // 추가메모

  // 경계/해제 시간
  final String? weekdayGuardTime; // 평일경계
  final String? weekdayReleaseTime; // 평일해제
  final String? weekendGuardTime; // 주말경계
  final String? weekendReleaseTime; // 주말해제
  final String? holidayGuardTime; // 휴일경계
  final String? holidayReleaseTime; // 휴일해제

  // 무단 범위
  final String? weekdayUnauthorizedRange; // 평일무단범위
  final String? weekendUnauthorizedRange; // 주말무단범위
  final String? holidayUnauthorizedRange; // 휴일무단범위

  // 무단 사용
  final bool? weekdayUnauthorizedUse; // 평일무단사용
  final bool? weekendUnauthorizedUse; // 주말무단사용
  final bool? holidayUnauthorizedUse; // 휴일무단사용

  //확장고객정보 드롭다운
  final String? companyTypeCode;
  final String? companyTypeName;
  final String? branchTypeCode;
  final String? branchTypeName;
  final String? dedicatedNumber;
  final String? dedicatedMemo;

  CustomerDetail({
    required this.controlManagementNumber,
    this.erpCusNumber,
    this.publicLine,
    this.dedicatedLine,
    this.internetLine,
    this.controlBusinessName,
    this.controlContact1,
    this.controlContact2,
    this.propertyAddress,
    this.responsePath1,
    this.representative,
    this.representativeHP,
    this.securityStartDate,
    this.managementAreaCode,
    this.managementAreaName,
    this.dispatchAreaCode,
    this.dispatchAreaName,
    this.vehicleCode,
    this.vehicleCodeName,
    this.policeStationCode,
    this.policeStationName,
    this.policeSubstationCode,
    this.policeSubstationName,
    this.businessTypeLargeCode,
    this.businessTypeLargeName,
    this.arsPhoneNumber,
    this.remotePhoneNumber,
    this.usageLineTypeCode,
    this.usageLineTypeName,
    this.deviceTypeCode,
    this.deviceTypeName,
    this.unguardedTypeCode,
    this.unguardedTypeName,
    this.remotePassword,
    this.monthlyAggregation,
    this.controlAction,
    this.keyReceiptStatus,
    this.acquisition,
    this.keyBoxes,
    this.unguardedClassificationCode,
    this.unguardedClassificationName,
    this.serviceTypeCode,
    this.serviceTypeName,
    this.customerStatusCode,
    this.customerStatusName,
    this.dvrStatus,
    this.gpsX1,
    this.gpsY1,
    this.gpsX2,
    this.gpsY2,
    this.wirelessSetStatus,
    this.remotePort,
    this.customerBusinessName,
    this.memo1,
    this.memo2,
    this.openingPhone, //개통전화번호
    this.modemSerial, //모뎀일련번호
    this.openingDate, //개통일자
    this.additionalMemo,
    this.weekdayGuardTime,
    this.weekdayReleaseTime,
    this.weekendGuardTime,
    this.weekendReleaseTime,
    this.holidayGuardTime,
    this.holidayReleaseTime,
    this.weekdayUnauthorizedRange,
    this.weekendUnauthorizedRange,
    this.holidayUnauthorizedRange,
    this.weekdayUnauthorizedUse,
    this.weekendUnauthorizedUse,
    this.holidayUnauthorizedUse,

    this.companyTypeCode,
    this.companyTypeName,
    this.branchTypeCode,
    this.branchTypeName,
    this.dedicatedNumber,
    this.dedicatedMemo,
  });

  factory CustomerDetail.fromJson(Map<String, dynamic> json) {
    return CustomerDetail(
      controlManagementNumber: json['관제관리번호']?.toString() ?? '',
      erpCusNumber: json['고객관리번호']?.toString() ?? '',
      usageLineTypeCode: json['사용회선종류']?.toString(),
      usageLineTypeName: json['사용회선종류명']?.toString(),
      publicLine: json['공중회선']?.toString(),
      dedicatedLine: json['전용회선']?.toString(),
      internetLine: json['인터넷회선']?.toString(),
      controlBusinessName: json['관제상호']?.toString(),
      controlContact1: json['관제연락처1']?.toString(),
      controlContact2: json['관제연락처2']?.toString(),
      propertyAddress: json['물건주소']?.toString(),
      responsePath1: json['대처경로1']?.toString(),
      representative: json['대표자']?.toString(),
      representativeHP: json['대표자HP']?.toString(),
      securityStartDate: dateToString(json['개통일자']?.toString()),
      managementAreaCode: json['관리구역코드']?.toString(),
      managementAreaName: json['관리구역코드명']?.toString(),
      dispatchAreaCode: json['출동권역코드']?.toString(),
      dispatchAreaName: json['출동권역코드명']?.toString(),
      vehicleCode: json['차량코드']?.toString(),
      vehicleCodeName: json['차량코드명']?.toString(),
      policeStationCode: json['경찰서코드']?.toString(),
      policeStationName: json['경찰서코드명']?.toString(),
      policeSubstationCode: json['지구대코드']?.toString(),
      policeSubstationName: json['지구대코드명']?.toString(),
      businessTypeLargeCode: json['업종대코드']?.toString(),
      businessTypeLargeName: json['업종대코드명']?.toString(),
      arsPhoneNumber: json['ARS전화번호']?.toString(),
      remotePhoneNumber: json['원격전화번호']?.toString(),
      deviceTypeCode: json['기기종류코드']?.toString(),
      deviceTypeName: json['기기종류명']?.toString(),
      unguardedTypeCode: json['미경계종류코드']?.toString(),
      unguardedTypeName: json['미경계종류코드명']?.toString(),
      remotePassword: json['원격암호']?.toString(),
      monthlyAggregation: json['월간집계'] as bool?,
      controlAction: json['관제액션']?.toString(),
      keyReceiptStatus: json['키인수여부'] as bool?,
      acquisition: json['tmP1']?.toString(),
      keyBoxes: json['키박스번호']?.toString(),
      unguardedClassificationCode: json['미경계분류코드']?.toString(),
      unguardedClassificationName: json['미경계분류코드명']?.toString(),
      serviceTypeCode: json['서비스종류코드']?.toString(),
      serviceTypeName: json['서비스종류코드명']?.toString(),
      customerStatusCode: json['관제고객상태코드']?.toString(),
      customerStatusName: json['관제고객상태코드명']?.toString(),
      dvrStatus: json['dvr여부'] as bool?,
      gpsX1: json['tmP4']?.toString(),
      gpsY1: json['tmP5']?.toString(),
      gpsX2: json['tmP6']?.toString(),
      gpsY2: json['tmP7']?.toString(),
      wirelessSetStatus: json['tmP8']?.toString(),
      remotePort: json['원격포트']?.toString(),
      customerBusinessName: json['고객용상호']?.toString(),
      memo1: json['메모1']?.toString(),
      memo2: json['메모2']?.toString(),
      openingPhone: json['cu1']?.toString(),
      modemSerial: json['cu2']?.toString(),
      openingDate: json['cu3']?.toString(),
      additionalMemo: json['cu4']?.toString(),
      weekdayGuardTime: json['평일경계']?.toString(),
      weekdayReleaseTime: json['평일해제']?.toString(),
      weekendGuardTime: json['주말경계']?.toString(),
      weekendReleaseTime: json['주말해제']?.toString(),
      holidayGuardTime: json['휴일경계']?.toString(),
      holidayReleaseTime: json['휴일해제']?.toString(),
      weekdayUnauthorizedRange: json['평일무단범위']?.toString(),
      weekendUnauthorizedRange: json['주말무단범위']?.toString(),
      holidayUnauthorizedRange: json['휴일무단범위']?.toString(),
      weekdayUnauthorizedUse: json['평일무단사용'] as bool?,
      weekendUnauthorizedUse: json['주말무단사용'] as bool?,
      holidayUnauthorizedUse: json['휴일무단사용'] as bool?,
      companyTypeCode: json['회사구분코드']?.toString(),
      companyTypeName: json['회사구분코드명']?.toString(),
      branchTypeCode: json['지사구분코드']?.toString(),
      branchTypeName: json['지사구분코드명']?.toString(),
      dedicatedNumber: json['전용자번호']?.toString(),
      dedicatedMemo: json['전용자메모']?.toString(),
    );
  }

  // 월간집계 여부 (기본값 false)
  bool get monthlyAggregationChecked => monthlyAggregation ?? false;

  // 키인수여부 (기본값 false)
  bool get keyReceiptStatusChecked => keyReceiptStatus ?? false;

  // DVR 체크 여부 (기본값 false)
  bool get dvrChecked => dvrStatus ?? false;

  // 무선센서설치 여부 (혹시나 null이면 0)
  String get wirelessChecked => wirelessSetStatus ?? '0';

  // 개통일자 포맷 (2025-11-04 형식)
  String get securityStartDateFormatted {
    if (securityStartDate == null || securityStartDate!.isEmpty) return '';

    try {
      // ISO 8601 형식 (2015-03-21T00:00:00) 처리
      if (securityStartDate!.contains('T')) {
        final dateTime = DateTime.parse(securityStartDate!);
        return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      }

      // YYYYMMDD 형식 (8자리 숫자) 처리
      if (securityStartDate!.length == 8 && !securityStartDate!.contains('-')) {
        return '${securityStartDate!.substring(0, 4)}-${securityStartDate!.substring(4, 6)}-${openingDate!.substring(6, 8)}';
      }

      // 이미 YYYY-MM-DD 형식이면 그대로 반환
      return securityStartDate!;
    } catch (e) {
      print('날짜 파싱 오류: $e');
      return securityStartDate!;
    }
  }
}
