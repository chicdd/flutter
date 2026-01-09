// enum Flavor { seodaemunPocom, suncheonC1, hankukAnjeon }
//
// class FlavorConfig {
//   final Flavor flavor;
//   final String name;
//   final String apiBaseUrl;
//   final bool showDebugBanner;
//   final String? sentryDsn;
//   final bool reportErrors;
//
//   // 기타 환경별 설정들...
//
//   static FlavorConfig? _instance;
//
//   factory FlavorConfig({
//     required Flavor flavor,
//     required String name,
//     required String apiBaseUrl,
//     bool showDebugBanner = true,
//     String? sentryDsn,
//     bool reportErrors = false,
//   }) {
//     _instance ??= FlavorConfig._internal(
//       flavor: flavor,
//       name: name,
//       apiBaseUrl: apiBaseUrl,
//       showDebugBanner: showDebugBanner,
//       sentryDsn: sentryDsn,
//       reportErrors: reportErrors,
//     );
//
//     return _instance!;
//   }
//
//   FlavorConfig._internal({
//     required this.flavor,
//     required this.name,
//     required this.apiBaseUrl,
//     required this.showDebugBanner,
//     required this.sentryDsn,
//     required this.reportErrors,
//   });
//
//   static FlavorConfig get instance {
//     return _instance!;
//   }
//
//   static bool get isDevelopment => instance.flavor == Flavor.development;
//   static bool get isStaging => instance.flavor == Flavor.staging;
//   static bool get isProduction => instance.flavor == Flavor.production;
// }
