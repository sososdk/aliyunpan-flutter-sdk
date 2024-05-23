import '../exception.dart';
import '../model/oauth.dart';
import 'command.dart';

/// [获取授权链接](https://www.yuque.com/aliyundrive/zpfszx/eam8ls1lmawwwksv#extsw)
class GetAuthorize extends Command<String> {
  const GetAuthorize({
    required this.appId,
    this.appSecret,
    required this.bundleId,
    required this.scopes,
    this.challenge,
    this.state,
    this.relogin = false,
    this.autoLogin = false,
  });

  final String appId;
  final String? appSecret;
  final String bundleId;
  final String redirectUri = 'oob';
  final List<Scope> scopes;
  final String responseType = 'code';
  final CodeChallenge? challenge;
  final String? state;
  final bool relogin;
  final bool autoLogin;
  final String source = 'app';

  @override
  bool get authorized => false;

  @override
  HttpMethod get method => HttpMethod.get;

  @override
  String get uri => Uri(path: '/oauth/authorize', queryParameters: {
        'client_id': appId,
        'client_secret': appSecret,
        'bundle_id': bundleId,
        'redirect_uri': redirectUri,
        'scope': scopes.map((e) => e.name).join(','),
        'response_type': responseType,
        'code_challenge': challenge?.challenge(),
        'code_challenge_method': challenge?.method.name,
        'state': state,
        'relogin': relogin.toString(),
        'autoLogin': autoLogin.toString(),
        'source': source,
      }).toString();

  @override
  dynamic get data => null;

  @override
  String parse(json) {
    if (state?.isNotEmpty == true &&
        state != Uri.parse(json['redirectUri']).queryParameters['state']) {
      throw const AuthcodeException(message: 'state mismatch');
    }
    return json['redirectUri'];
  }
}

/// [获取授权二维码](https://www.yuque.com/aliyundrive/zpfszx/ttfoy0xt2pza8lof#XuClO)
class GetQrcodeAuthorize extends Command<String> {
  const GetQrcodeAuthorize({
    required this.appId,
    required this.scopes,
    this.width = 430,
    this.height = 430,
    this.challenge,
  });

  final String appId;
  final List<Scope> scopes;
  final int width;
  final int height;
  final CodeChallenge? challenge;
  final String source = 'app';

  @override
  bool get authorized => false;

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  String get uri => '/oauth/authorize/qrcode';

  @override
  dynamic get data => {
        'client_id': appId,
        'scopes': scopes.map((e) => e.name).toList(),
        'width': width,
        'height': height,
        'code_challenge': challenge?.challenge(),
        'code_challenge_method': challenge?.method.name,
        'source': source,
      };

  @override
  String parse(json) => json['sid'];
}

/// [获取二维码登录状态](https://www.yuque.com/aliyundrive/zpfszx/ttfoy0xt2pza8lof#MW79B)
class GetQrcodeAuthorizeStatus extends Command<QrcodeAuthorizeStatusResult> {
  GetQrcodeAuthorizeStatus({required this.sid});

  final String sid;

  @override
  bool get authorized => false;

  @override
  HttpMethod get method => HttpMethod.get;

  @override
  String get uri => '/oauth/qrcode/$sid/status';

  @override
  dynamic get data => null;

  @override
  QrcodeAuthorizeStatusResult parse(json) {
    return QrcodeAuthorizeStatusResult.fromJson(json);
  }
}

/// [获取访问令牌](https://www.yuque.com/aliyundrive/zpfszx/eam8ls1lmawwwksv#XoLn9)
class GetAccessToken extends Command<Token> {
  const GetAccessToken.code({
    required this.appId,
    this.appSecret,
    required String this.code,
    this.challenge,
  })  : refreshToken = null,
        grantType = 'authorization_code';

  const GetAccessToken.refresh({
    required this.appId,
    required this.appSecret,
    required String this.refreshToken,
  })  : challenge = null,
        code = null,
        grantType = 'refresh_token';

  final String appId;
  final String grantType;
  final String? appSecret;
  final String? code;
  final String? refreshToken;
  final CodeChallenge? challenge;

  @override
  bool get authorized => false;

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  String get uri => '/oauth/access_token';

  @override
  dynamic get data => {
        'client_id': appId,
        'client_secret': appSecret,
        'grant_type': grantType,
        'code': code,
        'refresh_token': refreshToken,
        'code_verifier': challenge?.verifier,
      };

  @override
  Token parse(json) => Token.fromJson(json);
}
