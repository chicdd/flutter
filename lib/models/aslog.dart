import '../style.dart';

/// AS 접수 정보 모델
class AsLog {
  final String? controlBusinessName; //관제상호
  final String? customerName; //고객이름
  final String? customerHP; //고객연락처
  final String? requireDate; //요청일자
  final String? requireTime; //요청시간
  final String? requireSubject; //요청제목
  final String? receiptDate; //접수일자
  final String? receiptTime; //접수시간
  final String? details; //세부내용
  final String? contactCodeName; //담당자코드명
  final String? isProcessed; //처리여부
  final String? receptionist; // 접수자
  final String? processingetc; //처리비고

  AsLog({
    this.controlBusinessName,
    this.customerName,
    this.customerHP,
    this.requireDate,
    this.requireTime,
    this.requireSubject,
    this.receiptDate,
    this.receiptTime,
    this.details,
    this.contactCodeName,
    this.isProcessed,
    this.receptionist,
    this.processingetc,
  });

  /// JSON에서 AsLog 객체 생성
  factory AsLog.fromJson(Map<String, dynamic> json) {
    return AsLog(
      controlBusinessName: json['관제상호'] as String?,
      customerName: json['고객이름'] as String?,
      customerHP: json['고객연락처'] as String?,
      requireDate: dateParsing(json['요청일자'] as String),
      requireTime: json['요청시간'] as String?,
      requireSubject: json['요청제목'] as String?,
      receiptDate: dateParsing(json['접수일자'] as String),
      receiptTime: json['접수시간'] as String?,
      details: json['세부내용'] as String?,
      contactCodeName: json['담당자코드명'] as String?,
      isProcessed: json['처리여부'] as String?,
      receptionist: json['성명'] as String?,
      processingetc: json['processingetc'] as String?,
    );
  }

  /// AsLog 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'controlBusinessName': controlBusinessName,
      'customerName': customerName,
      'customerHP': customerHP,
      'requireDate': requireDate,
      'requireTime': requireTime,
      'requireSubject': requireSubject,
      'receiptDate': receiptDate,
      'receiptTime': receiptTime,
      'details': details,
      'contactCodeName': contactCodeName,
      'isProcessed': isProcessed,
      'receptionist': receptionist,
      'processingetc': processingetc,
    };
  }

  /// 디버깅용 문자열 표현
  @override
  String toString() {
    return 'AsLog(controlBusinessName: $controlBusinessName, customerName: $customerName, requireSubject: $requireSubject, isProcessed: $isProcessed)';
  }
}
