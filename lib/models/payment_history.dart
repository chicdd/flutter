/// 최근수금이력 모델
class PaymentHistory {
  final String? salesDate; // 매출년월
  final String? billingAmount; // 청구금액
  final String? actualPaymentAmount; // 실입금액
  final String? paymentMethod; // 입금방법
  final String? paymentDate; // 입금일자
  final bool? collectionStatus; // 수금상태
  final String? processor; // 처리자
  final String? note; // 비고

  PaymentHistory({
    this.salesDate,
    this.billingAmount,
    this.actualPaymentAmount,
    this.paymentMethod,
    this.paymentDate,
    this.collectionStatus,
    this.processor,
    this.note,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    return PaymentHistory(
      salesDate: json['매출년월'].toString(),
      billingAmount: json['청구금액'].toString(),
      actualPaymentAmount: json['실입금액'].toString(),
      paymentMethod: json['입금방법']?.toString(),
      paymentDate: json['납입일자'].toString(),
      collectionStatus: json['수금상태'] as bool?,
      processor: json['처리자']?.toString(),
      note: json['비고']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '매출년월': salesDate,
      '청구금액': billingAmount,
      '실입금액': actualPaymentAmount,
      '입금방법': paymentMethod,
      '입금일자': paymentDate,
      '수금상태': collectionStatus,
      '처리자': processor,
      '비고': note,
    };
  }

  /// 수금상태를 텍스트로 반환
  String get collectionStatusText {
    return collectionStatus == true ? '수금완료' : '-';
  }

  String get meachulformatted {
    if (salesDate == null || salesDate!.length < 6) return '-';
    return '${salesDate!.substring(0, 4)}-${salesDate!.substring(4, 6)}';
  }
}
