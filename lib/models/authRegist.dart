import 'package:securityindex/style.dart';

class AuthRegist {
  final String? phoneNumber; // 휴대폰번호
  final String? userName; // 사용자이름
  final bool? armaStatus; // 원격경계여부
  final bool? disarmaStatus; // 원격해제여부
  final String? registrationDate; // 등록일자
  final String? customerName; // 상호명

  AuthRegist({
    this.phoneNumber,
    this.userName,
    this.armaStatus,
    this.disarmaStatus,
    this.registrationDate,
    this.customerName,
  });

  factory AuthRegist.fromJson(Map<String, dynamic> json) {
    return AuthRegist(
      phoneNumber: json['휴대폰번호'] as String?,
      userName: json['사용자이름'] as String?,
      armaStatus: json['원격경계여부'] as bool?,
      disarmaStatus: json['원격해제여부'] as bool?,
      registrationDate: dateParsing(json['등록일자']),
      customerName: json['상호명'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '휴대폰번호': phoneNumber,
      '사용자이름': userName,
      '원격경계여부': armaStatus,
      '원격해제여부': disarmaStatus,
      '등록일자': registrationDate,
      '상호명': customerName,
    };
  }

  /// 원격경계여부를 텍스트로 반환
  String get armaStatusText {
    if (armaStatus == null) return '-';
    return armaStatus! ? '허용' : '불허';
  }

  /// 원격해제여부를 텍스트로 반환
  String get disarmaStatusText {
    if (disarmaStatus == null) return '-';
    return disarmaStatus! ? '허용' : '불허';
  }

  @override
  String toString() {
    return 'AuthRegist(phoneNumber: $phoneNumber, userName: $userName, armaStatus: $armaStatus, disarmaStatus: $disarmaStatus, registrationDate: $registrationDate)';
  }
}
