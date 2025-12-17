import '../style.dart';

class RecentSignalInfo {
  final String? controlManagementNumber; // 관제관리번호
  final String? controlBusinessName; // 관제상호
  final String? receiveDate; // 수신일자
  final String? receiveTime; // 수신시간
  final String? signalName; // 신호명
  final String? signalCode; // 신호코드 (메인코드)
  final String? remark; // 비고
  final String? controllerName; // 관제자
  final String? publicLine; // 공중회선
  final String? dedicatedLine; // 전용회선
  final String? inputContent; // 입력내용 (로그데이터)
  final String? textColor; // 글자색
  final String? backgroundColor; // 바탕색

  RecentSignalInfo({
    this.controlManagementNumber,
    this.controlBusinessName,
    this.receiveDate,
    this.receiveTime,
    this.signalName,
    this.signalCode,
    this.remark,
    this.controllerName,
    this.publicLine,
    this.dedicatedLine,
    this.inputContent,
    this.textColor,
    this.backgroundColor,
  });

  factory RecentSignalInfo.fromJson(Map<String, dynamic> json) {
    return RecentSignalInfo(
      controlManagementNumber: json['관제관리번호']?.toString(),
      controlBusinessName: json['관제상호']?.toString(),
      receiveDate: dateToString(json['수신일자'] as String),
      receiveTime: json['수신시간']?.toString(),
      signalName: json['신호명']?.toString(),
      signalCode: json['신호코드']?.toString(),
      remark: json['비고']?.toString(),
      controllerName: json['관제자']?.toString(),
      publicLine: json['공중회선']?.toString(),
      dedicatedLine: json['전용회선']?.toString(),
      inputContent: json['입력내용']?.toString(),
      textColor: json['글자색']?.toString(),
      backgroundColor: json['바탕색']?.toString(),
    );
  }

  // 수신일자 포맷 (YYYY-MM-DD)
  String get receiveDateFormatted {
    if (receiveDate == null) return '';
    return dateToString(receiveDate.toString());
  }

  // 수신시간 포맷 (HH:mm:ss)
  String get receiveTimeFormatted {
    if (receiveTime == null || receiveTime!.isEmpty) return '';
    return receiveTime!;
  }
}
