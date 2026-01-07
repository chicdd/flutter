/// 영업정보 모델
class SalesInfo {
  // 기본정보
  final String? customerNumber; // 고객번호
  final String? businessName; // 상호명
  final String? representative; // 대표자
  final String? businessPhone; // 상호전화
  final String? faxNumber; // 팩스번호
  final String? mobilePhone; // 휴대전화
  final String? customerStatus; // 고객상태
  final String? paymentMethod; // 납입방법
  final String? responsibleArea; // 담당권역
  final String? salesManager; // 신규판매자

  // 사업자정보
  final String? businessRegNumber; // 사업자등록번호
  final String? businessRegName; // 사업자상호
  final String? businessRepresentative; // 사업자대표자
  final String? businessAddress; // 사업장주소
  final String? businessType; // 업태
  final String? businessCategory; // 종목
  final String? invoiceEmail; // 계산서이메일

  // 월정료 정보
  final double? monthlyFee; // 월정료
  final double? vat; // VAT
  final double? totalAmount; // 총금액
  final double? deposit; // 보증금
  final int integratedCount; // 통합관리건수
  final int? unpaidMonths; // 미납월분
  final double? unpaidAmount; // 미납총금액

  SalesInfo({
    // 기본정보
    this.customerNumber,
    this.businessName,
    this.representative,
    this.businessPhone,
    this.faxNumber,
    this.mobilePhone,
    this.customerStatus,
    this.paymentMethod,
    this.responsibleArea,
    this.salesManager,
    // 사업자정보
    this.businessRegNumber,
    this.businessRegName,
    this.businessRepresentative,
    this.businessAddress,
    this.businessType,
    this.businessCategory,
    this.invoiceEmail,
    // 월정료 정보
    this.monthlyFee,
    this.vat,
    this.totalAmount,
    this.deposit,
    this.integratedCount = 0,
    this.unpaidMonths,
    this.unpaidAmount,
  });

  factory SalesInfo.fromJson(Map<String, dynamic> json) {
    return SalesInfo(
      // 기본정보
      customerNumber: json['고객번호'] as String?,
      businessName: json['상호명'] as String?,
      representative: json['대표자'] as String?,
      businessPhone: json['상호전화'] as String?,
      faxNumber: json['팩스번호'] as String?,
      mobilePhone: json['휴대전화'] as String?,
      customerStatus: json['고객상태'] as String?,
      paymentMethod: json['납입방법'] as String?,
      responsibleArea: json['담당권역'] as String?,
      salesManager: json['신규판매자'] as String?,
      // 사업자정보
      businessRegNumber: json['사업자등록번호'] as String?,
      businessRegName: json['사업자상호'] as String?,
      businessRepresentative: json['사업자대표자'] as String?,
      businessAddress: json['사업장주소'] as String?,
      businessType: json['업태'] as String?,
      businessCategory: json['종목'] as String?,
      invoiceEmail: json['계산서이메일'] as String?,
      // 월정료 정보
      monthlyFee: json['월정료'] != null
          ? (json['월정료'] is int
                ? (json['월정료'] as int).toDouble()
                : json['월정료'] as double)
          : null,
      vat: json['vat'] != null
          ? (json['vat'] is int
                ? (json['vat'] as int).toDouble()
                : json['vat'] as double)
          : null,
      totalAmount: json['총금액'] != null
          ? (json['총금액'] is int
                ? (json['총금액'] as int).toDouble()
                : json['총금액'] as double)
          : null,
      deposit: json['보증금'] != null
          ? (json['보증금'] is int
                ? (json['보증금'] as int).toDouble()
                : json['보증금'] as double)
          : null,
      integratedCount: json['통합관리건수'] as int? ?? 0,
      unpaidMonths: json['미납월분'] as int?,
      unpaidAmount: json['미납총금액'] != null
          ? (json['미납총금액'] is int
                ? (json['미납총금액'] as int).toDouble()
                : json['미납총금액'] as double)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // 기본정보
      '고객번호': customerNumber,
      '상호명': businessName,
      '대표자': representative,
      '상호전화': businessPhone,
      '팩스번호': faxNumber,
      '휴대전화': mobilePhone,
      '고객상태': customerStatus,
      '납입방법': paymentMethod,
      '담당권역': responsibleArea,
      '신규판매자': salesManager,
      // 사업자정보
      '사업자등록번호': businessRegNumber,
      '사업자상호': businessRegName,
      '사업자대표자': businessRepresentative,
      '사업장주소': businessAddress,
      '업태': businessType,
      '종목': businessCategory,
      '계산서이메일': invoiceEmail,
      // 월정료 정보
      '월정료': monthlyFee,
      'VAT': vat,
      '총금액': totalAmount,
      '보증금': deposit,
      '통합관리건수': integratedCount,
      '미납월분': unpaidMonths,
      '미납총금액': unpaidAmount,
    };
  }
}
