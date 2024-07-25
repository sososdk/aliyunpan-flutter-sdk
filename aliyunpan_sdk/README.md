# [非官方] 阿里云盘开放平台 SDK

[![pub](https://img.shields.io/pub/v/aliyunpan_sdk?style=flat)](https://pub.dev/packages/aliyunpan_sdk)

## 准备工作

[👉 如何注册三方开发者](https://www.yuque.com/aliyundrive/zpfszx/btw0tw)

## 快速开始

### 添加依赖:
```yaml
dependencies:
  aliyunpan_sdk: ^1.0.12
  # 使用阿里云盘客户端登录时, 需要添加此依赖
  aliyunpan_flutter_sdk_auth: ^1.0.6
```

### 配置:

> 如果不使用阿里云盘客户端登录, 请跳过配置步骤.

在`pubspec.yaml`的`aliyunpan`进行一些配置. 具体可以参考[pubspec.yaml](../example/pubspec.yaml#L24).

- app_id. 推荐. 它将用于生成iOS的url_scheme和LSApplicationQueriesSchemes.
- flutter_activity. 可选. 这个通常是用于Android的冷启动。如果不设置任何值，`aliyunpan sdk`将尝试启动launcher activity.

* For iOS

  如果你在iOS上遇到了 `cannot load such file -- plist`, 请按照以下步骤进行操作：
    ```shell
    # step.1 安装必要依赖
    sudo gem install plist
    # step.2 进行iOS文件夹(example/ios/,ios/)
    cd example/ios/
    # step.3 执行脚本
    pod install
    ```

* For Android

  修改`applicationId`为你在阿里云盘开放平台注册时填写的`应用包名`。参考[build.gradle](../example/android/app/build.gradle#L45).

## 使用

### 认证

```dart
import 'package:aliyunpan_flutter_sdk_auth/aliyunpan_flutter_sdk_auth.dart';
import 'package:aliyunpan_sdk/aliyunpan_sdk.dart';

/// 创建阿里云盘客户端
final client = AliyunpanClient(
  appId,
  refreshTokenFunction: refreshToken,
  debug: true,
  onTokenChange: (token) => SharedPreferences.getInstance().then((e) {
    if (token == null) {
      e.remove('key_token');
    } else {
      e.setString('key_token', jsonEncode(token));
    }
  }),
);

/// 读取本地存储的token
SharedPreferences.getInstance().then((e) {
  final object = e.getString('key_token');
  if (object != null) {
    client.token = Token.fromJson(jsonDecode(object));
  }
});

/// 认证
final credentials = FlutterCredentials.pkce(...);
await client.authorize(credentials);
```

支持多种认证方式:

- FlutterCredentials.pkce
- FlutterCredentials.server
- FlutterCredentials.secret

> Flutter Credentials 使用`阿里云盘客户端`或者`WebView`获取授权码, 然后获取 token.

- QrcodeCredentials.pkce
- QrcodeCredentials.server
- QrcodeCredentials.secret

> Qrcode Credentials 获取授权二维码, 通过`阿里云盘客户端`扫二维码获取授权码, 然后获取 token.

- WebCredentials.server
- WebCredentials.secret

> Web Credentials 使用`WebView`获取授权码, 然后获取 token.

> - [pkce(无后端服务授权模式)](https://www.yuque.com/aliyundrive/zpfszx/eam8ls1lmawwwksv) 不需要 `app_secret` 和 `服务端`, 但是不会返回`refresh_token`
> - server 模式需要服务端, 可以获取到`refresh_token`
> - secret 模式需要`app_secret`, 有暴露`app_secret`的风险, 可以获取到`refresh_token`

### 发送命令

使用 SDK，你可以轻松使用所有已提供的 OpenAPI 和它们的请求体、返回体模型

```dart
await client.send(...);
```

### 上传
```dart
await client.uploader.enqueue(UploadTask);
```

### 监听上传状态
```dart
client.uploader.updates.listen((event) {});
```

### 下载

```dart
await client.downloader.enqueue(DownloadTask);
```

### 监听下载状态
```dart
client.downloader.updates.listen((event) {});
```

## 谁在使用

- [知书](https://github.com/zhishuapp/zhishuapp.github.io)
