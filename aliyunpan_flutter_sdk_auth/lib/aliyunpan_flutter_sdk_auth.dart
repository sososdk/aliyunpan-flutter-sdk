import 'dart:async';

import 'package:aliyunpan_api/aliyunpan_api.dart';
import 'package:flutter/foundation.dart';

import 'src/aliyunpan_flutter_sdk_auth.dart';

export 'src/aliyunpan_flutter_sdk_auth.dart';

typedef AuthRedirect = Future<String?> Function(
    Uri uri, bool Function(String url) accept);

class FlutterAuthenticator implements Authenticator {
  const FlutterAuthenticator(
    void Function(VoidCallback callback) this.onSubscribe,
    this.onAuthRedirect, {
    this.forceSSO = false,
  });

  const FlutterAuthenticator.sso(this.onAuthRedirect)
      : onSubscribe = null,
        forceSSO = true;

  final void Function(VoidCallback callback)? onSubscribe;
  final AuthRedirect onAuthRedirect;
  final bool forceSSO;

  @override
  Future<void> preauthorize() async {
    if (kIsWeb) throw UnsupportedError('Web is not supported.');
  }

  @override
  Future<String> authorize(String redirectUri) async {
    // 检查阿里云盘客户端是否安装. (仅支持 android, ios)
    final useSSO = forceSSO || !await AliyunpanFlutterSdkAuth.isAppInstalled();
    if (useSSO) {
      final uri = Uri.parse(redirectUri);
      final url = await onAuthRedirect(
          uri.replace(
            scheme: 'https',
            host: 'www.alipan.com',
            path: '/o/oauth/authorize',
            queryParameters: Map.of(uri.queryParameters)
              ..['source'] = 'app_link',
          ),
          (url) => url.startsWith('smartdrive://'));
      if (url == null) {
        throw const AuthcodeException(message: 'AccessDenied');
      }
      final params = Uri.parse(url).queryParameters;
      final code = params['code'];
      final error = params['error'];
      if (error != null) {
        throw AuthcodeException(message: error);
      } else if (code == null) {
        throw const AuthcodeException(message: 'auth code is null');
      }
      return code;
    } else {
      if (!await AliyunpanFlutterSdkAuth.requestAuthcode(redirectUri)) {
        throw const AuthcodeException(
          message: 'request aliyunpan app authcode failed',
        );
      }
      final completer = Completer<String>.sync();
      final subscription = AliyunpanFlutterSdkAuth.authcodeStream.listen(
        completer.complete,
        onError: completer.completeError,
        onDone: () => completer.completeError(const AuthcodeException(
          message: 'request aliyunpan app authcode closed',
        )),
        cancelOnError: true,
      );
      onSubscribe!(() async {
        await subscription.cancel();
        if (!completer.isCompleted) {
          completer.completeError(const AuthcodeException(
            message: 'request aliyunpan app authcode canceled',
          ));
        }
      });
      return completer.future.whenComplete(subscription.cancel);
    }
  }
}
