// 계정 식별자. 비밀번호와 힌트답변은 클라이언트가 보관하지 않는다(Nakama 계정 시스템 +
// 잠긴 서버 스토리지가 처리, lib/net/auth_service.dart 참고).
class Account {
  final String id; // 로그인 ID = Nakama username (평문)
  final String nickname; // 표시명 = Nakama displayName (평문)

  const Account({required this.id, required this.nickname});
}
