/// 로그인 사용자 정보 모델
class LoginUser {
  final int index;
  final String userName;
  final String id;
  final String resionCode;
  final DateTime? lastLogin;

  LoginUser({
    required this.index,
    required this.userName,
    required this.id,
    required this.resionCode,
    this.lastLogin,
  });

  factory LoginUser.fromJson(Map<String, dynamic> json) {
    return LoginUser(
      index: json['로그인id'] as int,
      userName: json['성명'] as String? ?? '',
      id: json['ID'] as String? ?? '',
      resionCode: json['지역코드'] as String? ?? '',
      lastLogin: json['최종로그인'] != null
          ? DateTime.parse(json['최종로그인'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '로그인id': index,
      '성명': userName,
      'ID': id,
      '지역코드': resionCode,
      '최종로그인': lastLogin?.toIso8601String(),
    };
  }
}
