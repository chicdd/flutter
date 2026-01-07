import 'dart:convert';
import 'dart:typed_data';

/// 약도 데이터 모델
class MapDiagramData {
  final String? controlManagementNumber;
  final DateTime? registrationDate;
  final String? sequenceNumber;
  final String? dataTypeCode;
  final Uint8List? mapDiagramImage;
  final Uint8List? visioImage;
  final Uint8List? wmfImage;

  MapDiagramData({
    this.controlManagementNumber,
    this.registrationDate,
    this.sequenceNumber,
    this.dataTypeCode,
    this.mapDiagramImage,
    this.visioImage,
    this.wmfImage,
  });

  /// JSON에서 객체 생성
  factory MapDiagramData.fromJson(Map<String, dynamic> json) {
    return MapDiagramData(
      controlManagementNumber: json['관제관리번호'] as String?,
      registrationDate: json['등록일자'] != null
          ? DateTime.parse(json['등록일자'] as String)
          : null,
      sequenceNumber: json['순번'] as String?,
      dataTypeCode: json['DATA구분코드'] as String?,
      mapDiagramImage: json['약도데이터'] != null
          ? _base64ToUint8List(json['약도데이터'])
          : null,
      visioImage: json['비지오'] != null
          ? _base64ToUint8List(json['비지오'])
          : null,
      wmfImage: json['WMF'] != null ? _base64ToUint8List(json['WMF']) : null,
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
      '등록일자': registrationDate?.toIso8601String(),
      '순번': sequenceNumber,
      'DATA구분코드': dataTypeCode,
      '약도데이터': mapDiagramImage,
      '비지오': visioImage,
      'WMF': wmfImage,
    };
  }

  /// 약도 이미지가 있는지 확인
  bool get hasMapDiagram => mapDiagramImage != null && mapDiagramImage!.isNotEmpty;

  /// 비지오 이미지가 있는지 확인
  bool get hasVisio => visioImage != null && visioImage!.isNotEmpty;

  /// WMF 이미지가 있는지 확인
  bool get hasWmf => wmfImage != null && wmfImage!.isNotEmpty;
}
