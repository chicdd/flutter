import '../style.dart';

/// DVR 연동 정보 모델
class DVRInfo {
  final int serialNumber; // 일련번호
  final String? controlManagementNumber; // 관제관리번호
  final bool? connectionMethod; // 접속방식
  final String? dvrTypeCode; // DVR종류코드
  final String? dvrTypeName; // DVR종류코드명
  final String? connectionAddress; // 접속주소
  final String? connectionPort; // 접속포트
  final String? connectionId; // 접속ID
  final String? connectionPassword; // 접속암호
  final String? addedDate; // 추가일자 (yyyy-MM-dd 형식)

  DVRInfo({
    required this.serialNumber,
    this.controlManagementNumber,
    this.connectionMethod,
    this.dvrTypeCode,
    this.dvrTypeName,
    this.connectionAddress,
    this.connectionPort,
    this.connectionId,
    this.connectionPassword,
    this.addedDate,
  });

  /// JSON에서 DVRInfo 객체 생성
  factory DVRInfo.fromJson(Map<String, dynamic> json) {
    return DVRInfo(
      serialNumber: json['일련번호'] ?? 0,
      controlManagementNumber: json['관제관리번호']?.toString(),
      connectionMethod: json['접속방식'],
      dvrTypeCode: json['dvR종류코드']?.toString(),
      dvrTypeName: json['dvR종류코드명']?.toString(),
      connectionAddress: json['접속주소']?.toString(),
      connectionPort: json['접속포트']?.toString(),
      connectionId: json['접속ID']?.toString(),
      connectionPassword: json['접속암호']?.toString(),
      addedDate: dateParsing(json['추가일자']),
    );
  }

  /// 접속방식 텍스트 반환 (0: 웹, 1: 프로그램 등)
  String get connectionMethodText {
    if (connectionMethod == null) return '-';
    switch (connectionMethod) {
      case false:
        return 'CS';
      case true:
        return 'WEB';
      default:
        return connectionMethod.toString();
    }
  }
}
