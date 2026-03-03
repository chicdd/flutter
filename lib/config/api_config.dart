import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // 싱글톤 인스턴스
  static final ApiConfig _instance = ApiConfig._internal();
  factory ApiConfig() => _instance;
  ApiConfig._internal();

  // 앱 전체에서 사용할 변수들
  String Url = 'https://localhost:7088'; // 기본값
  String companyName = '';

  // 앱 구동 시 처음에 한 번만 호출해서 저장된 값을 불러옴
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    Url = prefs.getString('api_url') ?? 'https://localhost:7088';
    companyName = prefs.getString('company_name') ?? '미설정';
    print("API 주소 로드 완료: $Url");
  }

  // 개통 시 주소를 새로 고침할 때 사용
  Future<void> updateConfig(String newUrl, String newName) async {
    Url = newUrl;
    companyName = newName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_url', newUrl);
    await prefs.setString('company_name', newName);
  }
}
