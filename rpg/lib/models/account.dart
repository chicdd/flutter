// 계정 모델 — ID/닉네임은 평문, 비밀번호와 힌트 답변은 솔트+SHA-256 해시로 보관.
// 비밀번호는 복호화 불가(찾기 = 복구가 아닌 재설정). 추후 서버 인증으로 교체 시에도 이 형태 유지 권장.
class Account {
  final String id; // 로그인 ID (평문)
  final String nickname; // 표시명 + 아이디 찾기 키 (평문)
  final String salt; // 계정별 솔트(비밀번호/힌트답변 해시에 공통 사용)
  final String passwordHash; // SHA-256(salt::password)
  final String hintQuestion; // 비밀번호 힌트 질문 (평문)
  final String hintAnswerHash; // SHA-256(salt::정규화된 힌트답변)

  const Account({
    required this.id,
    required this.nickname,
    required this.salt,
    required this.passwordHash,
    required this.hintQuestion,
    required this.hintAnswerHash,
  });

  // 비밀번호 재설정(솔트는 유지 — 힌트답변 해시가 같은 솔트를 쓰므로).
  Account copyWith({String? passwordHash}) => Account(
        id: id,
        nickname: nickname,
        salt: salt,
        passwordHash: passwordHash ?? this.passwordHash,
        hintQuestion: hintQuestion,
        hintAnswerHash: hintAnswerHash,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        'salt': salt,
        'passwordHash': passwordHash,
        'hintQuestion': hintQuestion,
        'hintAnswerHash': hintAnswerHash,
      };

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: j['id'] as String,
        nickname: (j['nickname'] as String?) ?? j['id'] as String,
        salt: (j['salt'] as String?) ?? '',
        passwordHash: (j['passwordHash'] as String?) ?? '',
        hintQuestion: (j['hintQuestion'] as String?) ?? '',
        hintAnswerHash: (j['hintAnswerHash'] as String?) ?? '',
      );
}
