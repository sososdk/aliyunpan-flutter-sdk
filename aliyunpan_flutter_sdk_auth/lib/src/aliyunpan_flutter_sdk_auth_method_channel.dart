import 'dart:async';

import 'package:aliyunpan_api/aliyunpan_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'aliyunpan_flutter_sdk_auth_platform_interface.dart';

/// An implementation of [AliyunpanFlutterSdkAuthPlatform] that uses method channels.
class MethodChannelAliyunpanFlutterSdkAuth
    extends AliyunpanFlutterSdkAuthPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel(
    'com.github.sososdk/aliyunpan_flutter_sdk_auth',
  );

  MethodChannelAliyunpanFlutterSdkAuth() {
    methodChannel.setMethodCallHandler((call) {
      if (call.method case 'onAuthcode') {
        final code = call.arguments['code'] as String?;
        final error = call.arguments['error'] as String?;
        if (error != null) {
          authcodeController.addError(
            AuthcodeException(message: error),
          );
        } else if (code == null) {
          authcodeController.addError(
            const AuthcodeException(message: 'auth code is null'),
          );
        } else {
          authcodeController.add(code);
        }
      }
      return Future.value();
    });
  }

  @visibleForTesting
  final authcodeController = StreamController<String>.broadcast();

  @override
  Stream<String> get authcodeStream => authcodeController.stream;

  @override
  Future<bool> isAppInstalled() {
    return methodChannel
        .invokeMethod<bool>('isAppInstalled')
        .then((e) => e ?? false);
  }

  @override
  Future<bool> requestAuthcode(String redirectUri) {
    return methodChannel
        .invokeMethod<bool>('requestAuthcode', redirectUri)
        .then((e) => e ?? false);
  }
}
