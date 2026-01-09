import '../style.dart';

/// 최근 방문 및 A/S이력 모델
class VisitAsHistory {
  final String? requestDate; // 요청일자
  final String? areaName; // 권역명
  final String? requestTitle; // 요청제목
  final bool? processingStatus; // 처리여부
  final String? processingDateTime; // 처리일시
  final String? processingNote; // 처리비고
  final String? receptionist; // 접수자
  final String? processor; // 처리자
  final String? personalAsProcessor; // 개인AS처리자

  VisitAsHistory({
    this.requestDate,
    this.areaName,
    this.requestTitle,
    this.processingStatus,
    this.processingDateTime,
    this.processingNote,
    this.receptionist,
    this.processor,
    this.personalAsProcessor,
  });

  factory VisitAsHistory.fromJson(Map<String, dynamic> json) {
    return VisitAsHistory(
      requestDate: dateParsing(json['요청일자']),
      areaName: json['권역명']?.toString(),
      requestTitle: json['요청제목']?.toString(),
      processingStatus: json['처리여부'] as bool?,
      processingDateTime: dateParsing(json['처리일시']),
      processingNote: json['처리비고']?.toString(),
      receptionist: json['접수자']?.toString(),
      processor: json['처리자']?.toString(),
      personalAsProcessor: json['개인AS처리자']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '요청일자': requestDate,
      '권역명': areaName,
      '요청제목': requestTitle,
      '처리여부': processingStatus,
      '처리일시': processingDateTime,
      '처리비고': processingNote,
      '접수자': receptionist,
      '처리자': processor,
      '개인AS처리자': personalAsProcessor,
    };
  }

  /// 처리여부를 텍스트로 반환
  String get processingStatusText {
    return processingStatus == true ? '완료' : '미처리';
  }
}
