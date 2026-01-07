class UserZoneInfo {
  final String? registrationNumber; // 등록번호
  final String? userName; // 사용자명
  final String? position; // 직급
  final String? phoneNumber; // 휴대전화
  final String? relationWithContractor; // 계약자와관계
  final String? residentNumber; // 주민번호
  final String? ocUser; // OC사용자
  final String? note; // 비고
  final bool? unauthorizedReleaseAllowed; // 무단해제허용
  final bool? smsSent; // SMS발송
  final bool? agentCard; // 요원카드
  final bool? unattendedSms; // 미경계SMS
  final bool? reserveCard; // 예비카드여부

  UserZoneInfo({
    this.registrationNumber,
    this.userName,
    this.position,
    this.phoneNumber,
    this.relationWithContractor,
    this.residentNumber,
    this.ocUser,
    this.note,
    this.unauthorizedReleaseAllowed,
    this.smsSent,
    this.agentCard,
    this.unattendedSms,
    this.reserveCard,
  });

  factory UserZoneInfo.fromJson(Map<String, dynamic> json) {
    return UserZoneInfo(
      registrationNumber: json['등록번호'] as String?,
      userName: json['사용자명'] as String?,
      position: json['직급'] as String?,
      phoneNumber: json['휴대전화'] as String?,
      relationWithContractor: json['계약자와관계'] as String?,
      residentNumber: json['주민번호'] as String?,
      ocUser: json['OC사용자'] as String?,
      note: json['비고'] as String?,
      unauthorizedReleaseAllowed: json['무단해제허용'] as bool?,
      smsSent: json['SMS발송'] as bool?,
      agentCard: json['요원카드'] as bool?,
      unattendedSms: json['미경계SMS'] as bool?,
      reserveCard: json['예비카드여부'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '등록번호': registrationNumber,
      '사용자명': userName,
      '직급': position,
      '휴대전화': phoneNumber,
      '계약자와관계': relationWithContractor,
      '주민번호': residentNumber,
      'OC사용자': ocUser,
      '비고': note,
      '무단해제허용': unauthorizedReleaseAllowed,
      'SMS발송': smsSent,
      '요원카드': agentCard,
      '미경계SMS': unattendedSms,
      '예비카드여부': reserveCard,
    };
  }
}

class ZoneInfo {
  final String? zoneNumber; // 존번호
  final String? detectorInstallLocation; // 감지기설치위치
  final String? detectorName; // 감지기명
  final String? note; // 비고

  ZoneInfo({
    this.zoneNumber,
    this.detectorInstallLocation,
    this.detectorName,
    this.note,
  });

  factory ZoneInfo.fromJson(Map<String, dynamic> json) {
    return ZoneInfo(
      zoneNumber: json['존번호'] as String?,
      detectorInstallLocation: json['감지기설치위치'] as String?,
      detectorName: json['감지기명'] as String?,
      note: json['비고'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '존번호': zoneNumber,
      '감지기설치위치': detectorInstallLocation,
      '감지기명': detectorName,
      '비고': note,
    };
  }
}
