import 'command/command.dart';
import 'model/oauth.dart';

abstract interface class ClientBase {
  String get host;

  String get appId;

  List<Scope> get scopes;

  Future<T> send<T>(Command<T> command);
}

/// 授权状态
sealed class AuthorizeState {
  const AuthorizeState();
}

/// 获取授权码
sealed class AuthorizeRequestAuthcode extends AuthorizeState {
  const AuthorizeRequestAuthcode();
}

/// Redirect 模式: 获取 auth code 状态
sealed class RedirectAuthorizeRequestAuthcode extends AuthorizeRequestAuthcode {
  const RedirectAuthorizeRequestAuthcode();
}

/// 扫码授权模式: 获取 auth code 状态
sealed class QrcodeAuthorizeRequestAuthcode extends AuthorizeRequestAuthcode {
  const QrcodeAuthorizeRequestAuthcode();
}

/// 获取二维码成功
class QrcodeAuthorizeReady extends QrcodeAuthorizeRequestAuthcode {
  const QrcodeAuthorizeReady(this.qrcodeUrl);

  final String qrcodeUrl;

  @override
  String toString() => 'QrcodeAuthorizeReady{qrcodeUrl: $qrcodeUrl}';
}

/// 等待登录
class QrcodeAuthorizeWaitLogin extends QrcodeAuthorizeRequestAuthcode {
  const QrcodeAuthorizeWaitLogin();
}

/// 扫码成功
class QrcodeAuthorizeScanSuccess extends QrcodeAuthorizeRequestAuthcode {
  const QrcodeAuthorizeScanSuccess();
}

/// 获取 auth code 成功
class AuthorizeCodeReady extends AuthorizeState {
  const AuthorizeCodeReady();
}
