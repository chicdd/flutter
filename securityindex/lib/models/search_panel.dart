class SearchPanel {
  final String controlManagementNumber;
  final String controlBusinessName;
  final String? customerStatusName; // nullable로 변경
  final String propertyAddress;
  final String? representative;
  final String? phoneNumber;
  final String? userMobile;

  SearchPanel({
    required this.controlManagementNumber,
    required this.controlBusinessName,
    this.customerStatusName, // required 제거
    required this.propertyAddress,
    this.representative,
    required this.phoneNumber,
    this.userMobile,
  });

  factory SearchPanel.fromJson(Map<String, dynamic> json) {
    return SearchPanel(
      controlManagementNumber: json['관제관리번호']?.toString() ?? '',
      controlBusinessName: json['관제상호']?.toString() ?? '',
      customerStatusName: json['관제고객상태코드명']?.toString() ?? '',
      propertyAddress: json['물건주소']?.toString() ?? '',
      representative: json['대표자']?.toString(),
      phoneNumber: json['관제연락처1']?.toString() ?? '',
      userMobile: json['사용자HP']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '관제관리번호': controlManagementNumber,
      '관제상호': controlBusinessName,
      '관제고객상태코드명': customerStatusName,
      '물건주소': propertyAddress,
      '대표자': representative,
      '관제연락처1': phoneNumber,
      '사용자HP': userMobile,
    };
  }

  bool matchesFilter(String filterType, String query) {
    if (query.isEmpty) return true;

    final lowerQuery = query.toLowerCase();

    switch (filterType) {
      case '고객번호':
        return controlManagementNumber.toLowerCase().contains(lowerQuery);
      case '상호':
        return controlBusinessName.toLowerCase().contains(lowerQuery);
      case '대표자':
        return (representative ?? '').toLowerCase().contains(lowerQuery);
      case '주소':
        return propertyAddress.toLowerCase().contains(lowerQuery);
      case '전화번호':
        return (phoneNumber ?? '').toLowerCase().contains(lowerQuery);
      case '사용자HP':
        return (userMobile ?? '').toLowerCase().contains(lowerQuery);
      default:
        return true;
    }
  }
}
