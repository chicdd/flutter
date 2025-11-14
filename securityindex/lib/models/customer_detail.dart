class CustomerDetail {
  // 기본 정보
  final String controlManagementNumber; // 관제관리번호
  final String? controlCustomerStatusName; // 관제고객상태코드명
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
  final String? openingDate; // 개통일자

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
  final String? monthlyAggregation; // 월간집계
  final String? controlAction; // 관제액션
  final String? keyReceiptStatus; // 키인수여부
  final String? acquisition; // 인수수량
  final String? keyBoxes; // 키BOX
  final String? unguardedClassificationCode; // 미경계분류코드
  final String? unguardedClassificationName; // 미경계분류코드명
  final String? serviceTypeCode; // 서비스종류코드
  final String? serviceTypeName; // 서비스종류코드명
  final String? customerStatusCode; // 관제고객상태코드
  final String? customerStatusName; // 관제고객상태코드명
  final String? dvrStatus; // dvr여부
  final String? remotePort; // 원격포트
  final String? customerBusinessName; // 고객용상호
  final String? memo1; // 메모1
  final String? memo2; // 메모2

  CustomerDetail({
    required this.controlManagementNumber,
    this.controlCustomerStatusName,
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
    this.openingDate,
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
    this.remotePort,
    this.customerBusinessName,
    this.memo1,
    this.memo2,
  });

  factory CustomerDetail.fromJson(Map<String, dynamic> json) {
    return CustomerDetail(
      controlManagementNumber: json['관제관리번호']?.toString() ?? '',
      controlCustomerStatusName: json['관제고객상태코드명']?.toString(),
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
      openingDate: json['개통일자']?.toString(),
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
      usageLineTypeCode: json['사용회선종류']?.toString(),
      usageLineTypeName: json['사용회선종류명']?.toString(),
      deviceTypeCode: json['기기종류코드']?.toString(),
      deviceTypeName: json['기기종류명']?.toString(),
      unguardedTypeCode: json['미경계종류코드']?.toString(),
      unguardedTypeName: json['미경계종류코드명']?.toString(),
      remotePassword: json['원격암호']?.toString(),
      monthlyAggregation: json['월간집계']?.toString(),
      controlAction: json['관제액션']?.toString(),
      keyReceiptStatus: json['키인수여부']?.toString(),
      acquisition: json['tmP1']?.toString(),
      keyBoxes: json['키박스번호']?.toString(),
      unguardedClassificationCode: json['미경계분류코드']?.toString(),
      unguardedClassificationName: json['미경계분류코드명']?.toString(),
      serviceTypeCode: json['서비스종류코드']?.toString(),
      serviceTypeName: json['서비스종류코드명']?.toString(),
      customerStatusCode: json['관제고객상태코드']?.toString(),
      customerStatusName: json['관제고객상태코드명']?.toString(),
      dvrStatus: json['dvr여부']?.toString(),
      remotePort: json['원격포트']?.toString(),
      customerBusinessName: json['고객용상호']?.toString(),
      memo1: json['메모1']?.toString(),
      memo2: json['메모2']?.toString(),
    );
  }

  // 집계와 키인수여부를 Y/N으로 변환
  String get monthlyAggregationDisplay {
    if (monthlyAggregation == null) return 'N';
    return monthlyAggregation == '1' ? 'Y' : 'N';
  }

  String get keyReceiptStatusDisplay {
    if (keyReceiptStatus == null) return 'N';
    return keyReceiptStatus == '1' ? 'Y' : 'N';
  }

  // DVR 체크 여부
  bool get dvrChecked {
    if (dvrStatus == null) return false;
    return dvrStatus == '1';
  }

  // 개통일자 포맷 (2025-11-04 형식)
  String get openingDateFormatted {
    if (openingDate == null || openingDate!.isEmpty) return '';

    try {
      // ISO 8601 형식 (2015-03-21T00:00:00) 처리
      if (openingDate!.contains('T')) {
        final dateTime = DateTime.parse(openingDate!);
        return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      }

      // YYYYMMDD 형식 (8자리 숫자) 처리
      if (openingDate!.length == 8 && !openingDate!.contains('-')) {
        return '${openingDate!.substring(0, 4)}-${openingDate!.substring(4, 6)}-${openingDate!.substring(6, 8)}';
      }

      // 이미 YYYY-MM-DD 형식이면 그대로 반환
      return openingDate!;
    } catch (e) {
      print('날짜 파싱 오류: $e');
      return openingDate!;
    }
  }
}
