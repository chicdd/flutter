class CustomerHoliday {
  final int managementId;
  final String controlManagementNumber;
  final String holidayCode;

  CustomerHoliday({
    required this.managementId,
    required this.controlManagementNumber,
    required this.holidayCode,
  });

  factory CustomerHoliday.fromJson(Map<String, dynamic> json) {
    return CustomerHoliday(
      managementId: json['관리id'] ?? 0,
      controlManagementNumber: json['관제관리번호'] ?? '',
      holidayCode: json['휴일주간코드'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'managementId': managementId,
      'controlManagementNumber': controlManagementNumber,
      'holidayCode': holidayCode,
    };
  }
}
