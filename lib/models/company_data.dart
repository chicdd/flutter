class OpeningCompany {
  final int id;
  final String name;
  final String code;
  final String apiUrl;

  OpeningCompany({
    required this.id,
    required this.name,
    required this.code,
    required this.apiUrl,
  });
}

class CompanyRepository {
  static final List<OpeningCompany> _companies = [
    OpeningCompany(
      id: 1,
      name: "제이원",
      code: "53018644",
      apiUrl: "https://j1-api.com",
    ),
    OpeningCompany(
      id: 2,
      name: "시티캅",
      code: "51027112",
      apiUrl: "https://citycop-api.com",
    ),
    OpeningCompany(
      id: 3,
      name: "서대문포콤",
      code: "02031112",
      apiUrl: "https://pocom-sdm.com",
    ),
    OpeningCompany(
      id: 4,
      name: "씨원시큐리티",
      code: "61062298",
      apiUrl: "https://c1-secu.com",
    ),
    OpeningCompany(
      id: 5,
      name: "한세시큐리티",
      code: "62083651",
      apiUrl: "https://hanse-s.com",
    ),
    OpeningCompany(
      id: 6,
      name: "탑스보안 강동",
      code: "31094743",
      apiUrl: "https://tops-gd.com",
    ),
    OpeningCompany(
      id: 7,
      name: "포에스",
      code: "32104112",
      apiUrl: "https://4s-security.com",
    ),
    OpeningCompany(
      id: 8,
      name: "포콤방범시스템",
      code: "02111112",
      apiUrl: "https://pocom-system.com",
    ),
    OpeningCompany(
      id: 9,
      name: "네오",
      code: "02121162",
      apiUrl: "http://localhost:7088",
    ),
    OpeningCompany(
      id: 10,
      name: "SSC",
      code: "31134780",
      apiUrl: "https://ssc-api.com",
    ),
  ];

  // 코드로 업체 찾기
  static OpeningCompany? findByCode(String code) {
    try {
      return _companies.firstWhere((c) => c.code == code);
    } catch (e) {
      return null;
    }
  }
}
