import Flutter
import UIKit

public class AliyunpanFlutterSdkAuthPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.github.sososdk/aliyunpan_flutter_sdk_auth", binaryMessenger: registrar.messenger())
    let instance = AliyunpanFlutterSdkAuthPlugin(channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addApplicationDelegate(instance)
  }

  init(channel: FlutterMethodChannel) {
    self.channel = channel
  }

  var channel: FlutterMethodChannel;

  public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    if (url.scheme?.starts(with: "smartdrive") == true || url.scheme?.starts(with: "ypauth") == true) {
      let queryItems = url.queryItems
      self.channel.invokeMethod("onAuthcode", arguments: ["code": queryItems.first(where: { $0.name == "code" })?.value, "error": queryItems.first(where: { $0.name == "error" })?.value])
      return true
    } else {
      return false
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isAppInstalled":
      result(isInstalled)
    case "requestAuthcode":
      guard let url = URL(string: call.arguments as! String) else {
        result(FlutterError(code: "RequestAuthcode", message: "URL create failed", details: nil))
        return
      }
      UIApplication.shared.open(url) { success in
        result(success)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public var isInstalled: Bool {
    guard let url = URL(string: "smartdrive://") else {
      return false
    }
    return UIApplication.shared.canOpenURL(url)
  }
}

extension URL {
    var queryItems: [URLQueryItem] {
        guard let urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return []
        }
        return urlComponents.queryItems ?? []
    }
}
