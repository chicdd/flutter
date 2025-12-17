import '../style.dart';

class DocumentInfo {
  final String? controlManagementNumber; // 관제관리번호
  final String? documentSerialNumber; // 문서일련번호
  final String? documentName; // 문서명
  final String? documentExtension; // 문서확장자
  final String? documentDescription; // 문서설명
  final String? attachmentDate; // 첨부일자
  final String? attacher; // 첨부자
  final String? documentType; // 문서종류
  //드롭다운
  final String? documentTypeCode; // 문서종류코드
  final String? documentTypeName; // 문서종류코드명

  DocumentInfo({
    this.controlManagementNumber,
    this.documentSerialNumber,
    this.documentName,
    this.documentExtension,
    this.documentDescription,
    this.attachmentDate,
    this.attacher,
    this.documentType,
    this.documentTypeCode,
    this.documentTypeName,
  });

  factory DocumentInfo.fromJson(Map<String, dynamic> json) {
    return DocumentInfo(
      controlManagementNumber: json['관제관리번호'] as String?,
      documentSerialNumber: json['문서일련번호'] as String?,
      documentName: json['문서명'] as String?,
      documentExtension: json['문서확장자'] as String?,
      documentDescription: json['문서설명'] as String?,
      attachmentDate: detailDateParsing(json['첨부일자']),
      attacher: json['첨부자'] as String?,
      documentType: json['문서종류'] as String?,
      documentTypeCode: json['문서종류코드'] as String?,
      documentTypeName: json['문서종류코드명'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '관제관리번호': controlManagementNumber,
      '문서일련번호': documentSerialNumber,
      '문서명': documentName,
      '문서확장자': documentExtension,
      '문서설명': documentDescription,
      '첨부일자': attachmentDate,
      '첨부자': attacher,
      '문서종류': documentType,
      '문서종류코드': documentTypeCode,
      '문서종류코드명': documentTypeName,
    };
  }
}
