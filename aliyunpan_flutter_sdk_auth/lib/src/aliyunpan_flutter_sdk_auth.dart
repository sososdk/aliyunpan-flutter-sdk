import 'aliyunpan_flutter_sdk_auth_platform_interface.dart';

class AliyunpanFlutterSdkAuth {
  static Future<bool> isAppInstalled() {
    return AliyunpanFlutterSdkAuthPlatform.instance
        .isAppInstalled()
        .onError((p0, p1) => false);
  }

  static Future<bool> requestAuthcode(String redirectUri) {
    return AliyunpanFlutterSdkAuthPlatform.instance
        .requestAuthcode(redirectUri);
  }

  static Stream<String> get authcodeStream {
    return AliyunpanFlutterSdkAuthPlatform.instance.authcodeStream;
  }
}
