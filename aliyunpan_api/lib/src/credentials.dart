import 'dart:async';

import 'client.dart';
import 'command/oauth_scope.dart';
import 'exception.dart';
import 'model/oauth.dart';

typedef RequestTokenFunction = Future<Token> Function(String code);

typedef RefreshTokenFunction = Future<Token> Function(String refreshToken);

abstract interface class Authenticator {
  Future<void> preauthorize();

  Future<String> authorize(String redirectUri);
}

abstract class Credentials {
  const Credentials();

  Future<Token> authorize(
    ClientBase client,
    void Function(AuthorizeState state) onStateChange,
    bool Function() canceled,
  );
}

class FlutterCredentials extends Credentials {
  const FlutterCredentials.pkce({
    required this.bundleId,
    required CodeChallenge this.challenge,
    this.state,
    this.relogin = false,
    this.autoLogin = false,
    required this.authenticator,
  })  : appSecret = null,
        requestTokenFunction = null;

  const FlutterCredentials.server({
    required this.bundleId,
    this.state,
    this.relogin = false,
    this.autoLogin = false,
    required RequestTokenFunction this.requestTokenFunction,
    required this.authenticator,
  })  : challenge = null,
        appSecret = null;

  const FlutterCredentials.secret({
    required this.bundleId,
    required String this.appSecret,
    this.state,
    this.relogin = false,
    this.autoLogin = false,
    required this.authenticator,
  })  : challenge = null,
        requestTokenFunction = null;

  final String bundleId;
  final String? appSecret;
  final String redirectUri = 'oob';
  final String responseType = 'code';
  final CodeChallenge? challenge;
  final String? state;
  final bool relogin;
  final String source = 'app';
  final bool autoLogin;
  final RequestTokenFunction? requestTokenFunction;
  final Authenticator authenticator;

  @override
  Future<Token> authorize(
    ClientBase client,
    void Function(AuthorizeState state) onStateChange,
    bool Function() canceled,
  ) async {
    // 1. 检查条件是满足
    await authenticator.preauthorize();
    // 2. 获取转向链接
    final redirectUri = await client.send(GetAuthorize(
      appId: client.appId,
      bundleId: bundleId,
      scopes: client.scopes,
      challenge: challenge,
      state: state,
      relogin: relogin,
      autoLogin: autoLogin,
    ));
    // 3. 获取授权码
    final code = await authenticator.authorize(redirectUri);
    onStateChange(const RedirectAuthorizeReady());
    // 4. 获取 token
    if (requestTokenFunction != null) {
      return requestTokenFunction!(code);
    } else {
      return client.send(GetAccessToken.code(
        appId: client.appId,
        appSecret: appSecret,
        code: code,
        challenge: challenge,
      ));
    }
  }
}

class QrcodeCredentials extends Credentials {
  const QrcodeCredentials.pkce({
    required CodeChallenge this.challenge,
    this.width = 430,
    this.height = 430,
  })  : appSecret = null,
        requestTokenFunction = null;

  const QrcodeCredentials.server({
    required RequestTokenFunction this.requestTokenFunction,
    this.width = 430,
    this.height = 430,
  })  : challenge = null,
        appSecret = null;

  const QrcodeCredentials.secret({
    required String this.appSecret,
    this.width = 430,
    this.height = 430,
  })  : challenge = null,
        requestTokenFunction = null;

  final String redirectUri = 'oob';
  final int width;
  final int height;
  final String? appSecret;
  final CodeChallenge? challenge;
  final String source = 'app';
  final RequestTokenFunction? requestTokenFunction;

  @override
  Future<Token> authorize(
    ClientBase client,
    void Function(AuthorizeState state) onStateChange,
    bool Function() canceled,
  ) async {
    // 获取授权二维码
    final sid = await client.send(GetQrcodeAuthorize(
      appId: client.appId,
      scopes: client.scopes,
      width: width,
      height: height,
      challenge: challenge,
    ));
    onStateChange(QrcodeAuthorizeReady('${client.host}/oauth/qrcode/$sid'));
    var timeout = false;
    return Future<Token>(() async {
      while (true) {
        if (timeout) {
          assert(false, 'IMPOSSIBLE');
          throw const AuthorizeException(message: 'qrcode expired');
        }
        if (canceled()) {
          throw const AuthorizeException(message: 'user canceled');
        }
        QrcodeAuthorizeStatusResult result;
        try {
          // 获取二维码登录状态
          result = await client.send(GetQrcodeAuthorizeStatus(sid: sid));
        } catch (e) {
          continue;
        }
        switch (result.status) {
          case QrcodeAuthorizeStatus.waitLogin:
            onStateChange(const QrcodeAuthorizeWaitLogin());
          case QrcodeAuthorizeStatus.scanSuccess:
            onStateChange(const QrcodeAuthorizeScanSuccess());
          case QrcodeAuthorizeStatus.loginSuccess:
            final code = result.authCode!;
            if (requestTokenFunction != null) {
              return requestTokenFunction!(code);
            } else {
              return client.send(GetAccessToken.code(
                appId: client.appId,
                appSecret: appSecret,
                code: code,
                challenge: challenge,
              ));
            }
          case QrcodeAuthorizeStatus.qrcodeExpired:
            throw const AuthorizeException(message: 'qrcode expired');
        }
      }
    }).timeout(const Duration(minutes: 3), onTimeout: () {
      timeout = true;
      throw const AuthorizeException(message: 'qrcode expired');
    });
  }
}

class WebCredentials extends Credentials {
  const WebCredentials.secret({
    required this.appSecret,
    this.state,
    this.relogin = false,
    this.autoLogin = false,
    required this.authenticator,
  }) : requestTokenFunction = null;

  const WebCredentials.server({
    required this.requestTokenFunction,
    this.state,
    this.relogin = false,
    this.autoLogin = false,
    required this.authenticator,
  }) : appSecret = null;

  final String? appSecret;
  final String redirectUri = 'oob';
  final String responseType = 'code';
  final String? state;
  final bool relogin;
  final String source = 'web';
  final bool autoLogin;
  final RequestTokenFunction? requestTokenFunction;
  final Authenticator authenticator;

  @override
  Future<Token> authorize(
    ClientBase client,
    void Function(AuthorizeState state) onStateChange,
    bool Function() canceled,
  ) async {
    // 1. 检查条件是满足
    await authenticator.preauthorize();
    // 2. 获取转向链接
    final redirectUri = Uri.parse(client.host).replace(queryParameters: {
      'client_id': client.appId,
      'redirect_uri': this.redirectUri,
      'scope': client.scopes.map((e) => e.name).join(','),
      'response_type': responseType,
      'state': state,
      'relogin': '$relogin',
      'autoLogin': '$autoLogin',
      'source': source,
    }).toString();
    if (state?.isNotEmpty == true &&
        state != Uri.parse(redirectUri).queryParameters['state']) {
      throw const AuthcodeException(message: 'state mismatch');
    }
    // 3. 获取授权码
    final code = await authenticator.authorize(redirectUri);
    onStateChange(const RedirectAuthorizeReady());
    // 4. 获取 token
    if (requestTokenFunction != null) {
      return requestTokenFunction!(code);
    } else {
      return client.send(GetAccessToken.code(
        appId: client.appId,
        appSecret: appSecret,
        code: code,
      ));
    }
  }
}
