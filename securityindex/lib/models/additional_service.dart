import 'package:securityindex/style.dart';

class AdditionalService {
  final String? controlManagementNumber; // 관제관리번호
  final String? serviceName; // 부가서비스코드명
  final String? provisionType; // 부가서비스제공코드명
  final String? provisionDate; // 부가서비스일자
  final String? memo; // 추가메모

  AdditionalService({
    this.controlManagementNumber,
    this.serviceName,
    this.provisionType,
    this.provisionDate,
    this.memo,
  });

  factory AdditionalService.fromJson(Map<String, dynamic> json) {
    return AdditionalService(
      controlManagementNumber: json['관제관리번호'] as String?,
      serviceName: json['부가서비스코드명'] as String?,
      provisionType: json['부가서비스제공코드명'] as String?,
      provisionDate: dateParsing(json['부가서비스일자'] as String),
      memo: json['추가메모'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '관제관리번호': controlManagementNumber,
      '부가서비스코드명': serviceName,
      '부가서비스제공코드명': provisionType,
      '부가서비스일자': provisionDate,
      '추가메모': memo,
    };
  }

  @override
  String toString() {
    return 'AdditionalService(serviceName: $serviceName, provisionType: $provisionType, provisionDate: ${dateParsing(provisionDate)})';
  }
}
