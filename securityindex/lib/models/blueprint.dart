import 'dart:convert';
import 'dart:typed_data';

/// 도면 데이터 모델
class BlueprintData {
  final String? controlManagementNumber;
  final String? dataTypeCode;
  final DateTime? registrationDate;
  final Uint8List? blueprintImage;
  final Uint8List? visioImage;
  final String? tableName;

  BlueprintData({
    this.controlManagementNumber,
    this.dataTypeCode,
    this.registrationDate,
    this.blueprintImage,
    this.visioImage,
    this.tableName,
  });

  /// JSON에서 객체 생성
  factory BlueprintData.fromJson(Map<String, dynamic> json) {
    return BlueprintData(
      controlManagementNumber: json['관제관리번호'] as String?,
      dataTypeCode: json['DATA구분코드'] as String?,
      registrationDate: json['등록일자'] != null
          ? DateTime.parse(json['등록일자'] as String)
          : null,
      blueprintImage: json['도면데이터'] != null
          ? _base64ToUint8List(json['도면데이터'])
          : null,
      visioImage: json['비지오'] != null
          ? _base64ToUint8List(json['비지오'])
          : null,
      tableName: json['테이블명'] as String?,
    );
  }

  /// Base64 문자열을 Uint8List로 변환
  static Uint8List? _base64ToUint8List(dynamic data) {
    if (data == null) return null;

    if (data is String) {
      // Base64 문자열 디코딩
      try {
        return base64.decode(data);
      } catch (e) {
        print('Base64 디코딩 오류: $e');
        return null;
      }
    } else if (data is List) {
      // 바이트 배열인 경우
      return Uint8List.fromList(data.cast<int>());
    }

    return null;
  }

  /// 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      '관제관리번호': controlManagementNumber,
      'DATA구분코드': dataTypeCode,
      '등록일자': registrationDate?.toIso8601String(),
      '도면데이터': blueprintImage,
      '비지오': visioImage,
      '테이블명': tableName,
    };
  }

  /// 도면 이미지가 있는지 확인
  bool get hasBlueprint => blueprintImage != null && blueprintImage!.isNotEmpty;

  /// 비지오 이미지가 있는지 확인
  bool get hasVisio => visioImage != null && visioImage!.isNotEmpty;

  /// 도면2 여부 (도면마스터2 테이블)
  bool get isBlueprint2 => tableName == '도면마스터2';
}
