import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let configChannel = FlutterMethodChannel(name: "com.neo.config/channel",
                                           binaryMessenger: controller.binaryMessenger)

    configChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
      switch call.method {
      case "getAppName":
        if let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String {
          result(appName)
        } else {
          result("앱 이름 없음")
        }
      case "getGaetongCode":
        if let gaetongCode = Bundle.main.infoDictionary?["FLUTTER_GAETONG_CODE"] as? String {
          result(gaetongCode)
        } else {
          result("개통코드 없음")
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
