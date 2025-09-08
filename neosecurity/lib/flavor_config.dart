class FlavorConfig {
  final String appName;
  final String gaetongCode;

  static late FlavorConfig _instance;
  static FlavorConfig get instance => _instance;

  FlavorConfig._internal(this.appName, this.gaetongCode);

  static void setup({required String appName, required String gaetongCode}) {
    _instance = FlavorConfig._internal(appName, gaetongCode);
  }
}
