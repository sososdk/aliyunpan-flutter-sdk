import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class Token {
  final String tokenType;

  /// 用来获取用户信息的 access_token. 刷新后, 旧 access_token 不会立即失效.
  final String accessToken;

  /// 单次有效, 用来刷新 access_token, 90 天有效期. 刷新后, 返回新的 refresh_token, 请保存以便下一次刷新使用. PKCE模式下不返回.
  final String? refreshToken;

  /// 过期时间, 单位秒. 默认30天有效期.
  final Duration expiresIn;

  /// 过期时间戳.
  final DateTime expiresAt;

  const Token({
    required this.tokenType,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.expiresAt,
  });

  factory Token.fromJson(Map<String, dynamic> json) => Token(
        tokenType: json['token_type'],
        accessToken: json['access_token'],
        refreshToken: json['refresh_token'],
        expiresIn: Duration(seconds: json['expires_in']),
        expiresAt: json['expires_at'] == null
            ? DateTime.now().add(Duration(seconds: json['expires_in']))
            : DateTime.parse(json['expires_at']),
      );

  Map<String, dynamic> toJson() => {
        'token_type': tokenType,
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_in': expiresIn.inSeconds,
        'expires_at': expiresAt.toIso8601String(),
      };
}

enum Scope {
  /// 获取你的用户ID、头像、昵称
  userBase,

  /// 读取云盘所有文件
  fileAllRead,

  /// 写入云盘所有文件
  fileAllWrite,

  /// 读取共享相薄文件
  albumSharedRead;

  String get name => switch (this) {
        Scope.userBase => 'user:base',
        Scope.fileAllRead => 'file:all:read',
        Scope.fileAllWrite => 'file:all:write',
        Scope.albumSharedRead => 'album:shared:read',
      };
}

enum CodeChallengeMethod {
  plain,
  s256;

  String get name => switch (this) {
        CodeChallengeMethod.plain => 'plain',
        CodeChallengeMethod.s256 => 'S256',
      };
}

class CodeChallenge {
  const CodeChallenge(this.method, this.verifier);

  CodeChallenge.random(this.method) : verifier = genCodeVerifier();

  static String genCodeVerifier() {
    final random = Random.secure();
    return List.generate(
            random.nextInt(128 - 43) + 43, (index) => random.nextInt(0xFF))
        .map(String.fromCharCode)
        .join();
  }

  final CodeChallengeMethod method;
  final String verifier;

  String challenge() => switch (method) {
        CodeChallengeMethod.plain => verifier,
        CodeChallengeMethod.s256 =>
          base64UrlEncode(sha256.convert(utf8.encode(verifier)).bytes),
      };
}

class QrcodeAuthorizeStatusResult {
  final QrcodeAuthorizeStatus status;
  final String? authCode;

  const QrcodeAuthorizeStatusResult({
    required this.status,
    required this.authCode,
  });

  factory QrcodeAuthorizeStatusResult.fromJson(Map<String, dynamic> json) =>
      QrcodeAuthorizeStatusResult(
        status: QrcodeAuthorizeStatus.fromName(json['status']),
        authCode: json['authCode'],
      );
}

enum QrcodeAuthorizeStatus {
  /// 等待登录
  waitLogin,

  /// 扫码成功
  scanSuccess,

  /// 登录成功
  loginSuccess,

  /// 二维码过期
  qrcodeExpired;

  String get name => switch (this) {
        QrcodeAuthorizeStatus.waitLogin => 'WaitLogin',
        QrcodeAuthorizeStatus.scanSuccess => 'ScanSuccess',
        QrcodeAuthorizeStatus.loginSuccess => 'LoginSuccess',
        QrcodeAuthorizeStatus.qrcodeExpired => 'QRCodeExpired',
      };

  static QrcodeAuthorizeStatus fromName(String name) {
    return QrcodeAuthorizeStatus.values.firstWhere((e) => e.name == name);
  }
}
