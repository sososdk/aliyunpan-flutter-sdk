import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'aliyunpan_flutter_sdk_auth_method_channel.dart';

abstract class AliyunpanFlutterSdkAuthPlatform extends PlatformInterface {
  /// Constructs a AliyunpanFlutterSdkAuthPlatform.
  AliyunpanFlutterSdkAuthPlatform() : super(token: _token);

  static final Object _token = Object();

  static AliyunpanFlutterSdkAuthPlatform _instance =
      MethodChannelAliyunpanFlutterSdkAuth();

  /// The default instance of [AliyunpanFlutterSdkAuthPlatform] to use.
  ///
  /// Defaults to [MethodChannelAliyunpanFlutterSdkAuth].
  static AliyunpanFlutterSdkAuthPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AliyunpanFlutterSdkAuthPlatform] when
  /// they register themselves.
  static set instance(AliyunpanFlutterSdkAuthPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> isAppInstalled() {
    throw UnimplementedError('isAppInstalled() has not been implemented.');
  }

  Future<bool> requestAuthcode(String redirectUri) {
    throw UnimplementedError('requestAuthcode() has not been implemented.');
  }

  Stream<String> get authcodeStream {
    throw UnimplementedError('authcodeStream has not been implemented.');
  }
}
