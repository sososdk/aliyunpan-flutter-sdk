import 'dart:convert';
import 'dart:io';

import 'package:aliyunpan_flutter_sdk_auth/aliyunpan_flutter_sdk_auth.dart';
import 'package:aliyunpan_sdk/aliyunpan_sdk.dart';
import 'package:dio/dio.dart';
import 'package:flash/flash_helper.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'drive_page.dart';

const appId = String.fromEnvironment('APP_ID');
const appSecret = String.fromEnvironment('APP_SECRET');
const bundleId = String.fromEnvironment('BUNDLE_ID');

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final navigatorKey = GlobalKey<NavigatorState>();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      builder: (context, child) {
        // Wrap with toast.
        child = Toast(navigatorKey: navigatorKey, child: child!);
        return child;
      },
      home: const MyHomePage(title: 'Aliyunpan SDK'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final client = AliyunpanClient(
    appId,
    refreshTokenFunction: refreshToken,
    debug: false,
    onTokenChange: (token) => SharedPreferences.getInstance().then((e) {
      if (token == null) {
        e.remove('key_token');
      } else {
        e.setString('key_token', jsonEncode(token));
      }
    }),
  );

  Drive? drive;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((e) {
      final object = e.getString('key_token');
      if (object != null) {
        setState(() {
          client.token = Token.fromJson(jsonDecode(object));
        });
      }
    });
  }
  
  @override
  void dispose() {
    client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        actions: [
          if (client.authorized)
            IconButton(
              onPressed: () async {
                client.token = null;
                drive = null;
                setState(() {});
              },
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: !client.authorized
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('认证'),
                  FlutterPkceOAuth(
                    client: client,
                    onStateChange: () => setState(() {}),
                  ),
                  FlutterServerOAuth(
                    client: client,
                    onStateChange: () => setState(() {}),
                  ),
                  FlutterSecretOAuth(
                    client: client,
                    onStateChange: () => setState(() {}),
                  ),
                  QrcodeOAuth(
                    title: 'OAuth - QRCODE - PKCE',
                    client: client,
                    credentials: QrcodeCredentials.pkce(
                      challenge: CodeChallenge.random(
                        CodeChallengeMethod.s256,
                      ),
                    ),
                    onStateChange: () => setState(() {}),
                  ),
                  QrcodeOAuth(
                    title: 'OAuth - QRCODE - SERVER',
                    client: client,
                    credentials: const QrcodeCredentials.server(
                      requestTokenFunction: requestToken,
                    ),
                    onStateChange: () => setState(() {}),
                  ),
                  QrcodeOAuth(
                    title: 'OAuth - QRCODE - SECRET',
                    client: client,
                    credentials: const QrcodeCredentials.secret(
                      appSecret: appSecret,
                    ),
                    onStateChange: () => setState(() {}),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final credentials = WebCredentials.secret(
                        appSecret: appSecret,
                        authenticator: FlutterAuthenticator.sso(
                          (uri, accept) => Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    WebViewPage(uri: uri, accept: accept),
                              )),
                        ),
                      );
                      await client.authorize(credentials);
                      if (context.mounted) {
                        Toast.show(context, const Text('授权成功'));
                      }
                      setState(() {});
                    },
                    child: const Text('OAuth - WEB - SECRET'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final credentials = WebCredentials.server(
                        requestTokenFunction: requestToken,
                        authenticator: FlutterAuthenticator.sso(
                          (uri, accept) => Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    WebViewPage(uri: uri, accept: accept),
                              )),
                        ),
                      );
                      await client.authorize(credentials);
                      if (context.mounted) {
                        Toast.show(context, const Text('授权成功'));
                      }
                      setState(() {});
                    },
                    child: const Text('OAuth - WEB - SERVER'),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('用户'),
                  ElevatedButton(
                    onPressed: () => client.send(const GetUser()).then((e) {
                      debugPrint(e.toString());
                    }),
                    child: const Text('获取用户信息'),
                  ),
                  ElevatedButton(
                    onPressed: () => client.send(const GetDrive()).then((e) {
                      debugPrint(e.toString());
                      setState(() => drive = e);
                    }),
                    child: const Text('获取用户drive信息'),
                  ),
                  ElevatedButton(
                    onPressed: () => client.send(const GetSpace()).then((e) {
                      debugPrint(e.toString());
                    }),
                    child: const Text('获取用户空间信息'),
                  ),
                  ElevatedButton(
                    onPressed: () => client.send(const GetVip()).then((e) {
                      debugPrint(e.toString());
                    }),
                    child: const Text('获取用户vip信息'),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        client.send(const GetVipFeatures()).then((e) {
                      debugPrint(e.toString());
                      final feature = e.firstOrNull;
                      if (feature != null) {
                        client
                            .send(GetVipFeatureTrial(featureCode: feature.code))
                            .then((e) {
                          debugPrint(e.toString());
                        });
                      }
                    }),
                    child: const Text('付费功能列表'),
                  ),
                  if (drive != null) FileScope(client: client, drive: drive!),
                ],
              ),
      ),
    );
  }
}

class FlutterPkceOAuth extends StatefulWidget {
  const FlutterPkceOAuth({
    super.key,
    required this.client,
    required this.onStateChange,
  });

  final AliyunpanClient client;
  final VoidCallback onStateChange;

  @override
  State<FlutterPkceOAuth> createState() => _FlutterPkceOAuthState();
}

class _FlutterPkceOAuthState extends State<FlutterPkceOAuth> {
  VoidCallback? authcodeSubscription;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton(
          onPressed: authcodeSubscription != null
              ? null
              : () async {
                  final credentials = FlutterCredentials.pkce(
                      bundleId: bundleId,
                      challenge: CodeChallenge.random(CodeChallengeMethod.s256),
                      authenticator: FlutterAuthenticator(
                        (subscription) {
                          setState(() {
                            authcodeSubscription = subscription;
                          });
                        },
                        (uri, accept) => Navigator.push<String>(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  WebViewPage(uri: uri, accept: accept),
                            )),
                        forceSSO: false,
                      ));
                  await widget.client
                      .authorize(credentials)
                      .whenComplete(() => setState(() {
                            authcodeSubscription = null;
                          }));
                  if (context.mounted) {
                    Toast.show(context, const Text('授权成功'));
                  }
                  widget.onStateChange();
                },
          child: const Text('OAuth - APP - PKCE'),
        ),
        if (authcodeSubscription != null)
          ElevatedButton(
            onPressed: authcodeSubscription,
            child: const Text('OAuth - CANCEL'),
          ),
      ],
    );
  }
}

class FlutterServerOAuth extends StatefulWidget {
  const FlutterServerOAuth({
    super.key,
    required this.client,
    required this.onStateChange,
  });

  final AliyunpanClient client;
  final VoidCallback onStateChange;

  @override
  State<FlutterServerOAuth> createState() => _FlutterServerOAuthState();
}

class _FlutterServerOAuthState extends State<FlutterServerOAuth> {
  VoidCallback? authcodeSubscription;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton(
          onPressed: authcodeSubscription != null
              ? null
              : () async {
                  final credentials = FlutterCredentials.server(
                      bundleId: bundleId,
                      authenticator: FlutterAuthenticator(
                        (subscription) {
                          setState(() {
                            authcodeSubscription = subscription;
                          });
                        },
                        (uri, accept) => Navigator.push<String>(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  WebViewPage(uri: uri, accept: accept),
                            )),
                        forceSSO: false,
                      ),
                      requestTokenFunction: requestToken);
                  await widget.client
                      .authorize(credentials)
                      .whenComplete(() => setState(() {
                            authcodeSubscription = null;
                          }));
                  if (context.mounted) {
                    Toast.show(context, const Text('授权成功'));
                  }
                  widget.onStateChange();
                },
          child: const Text('OAuth - APP - SERVER'),
        ),
        if (authcodeSubscription != null)
          ElevatedButton(
            onPressed: authcodeSubscription,
            child: const Text('OAuth - CANCEL'),
          ),
      ],
    );
  }
}

class FlutterSecretOAuth extends StatefulWidget {
  const FlutterSecretOAuth({
    super.key,
    required this.client,
    required this.onStateChange,
  });

  final AliyunpanClient client;
  final VoidCallback onStateChange;

  @override
  State<FlutterSecretOAuth> createState() => _FlutterSecretOAuthState();
}

class _FlutterSecretOAuthState extends State<FlutterSecretOAuth> {
  VoidCallback? authcodeSubscription;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton(
          onPressed: authcodeSubscription != null
              ? null
              : () async {
                  final credentials = FlutterCredentials.secret(
                      bundleId: bundleId,
                      appSecret: appSecret,
                      authenticator: FlutterAuthenticator(
                        (subscription) {
                          setState(() {
                            authcodeSubscription = subscription;
                          });
                        },
                        (uri, accept) => Navigator.push<String>(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  WebViewPage(uri: uri, accept: accept),
                            )),
                        forceSSO: false,
                      ));
                  await widget.client
                      .authorize(credentials)
                      .whenComplete(() => setState(() {
                            authcodeSubscription = null;
                          }));
                  if (context.mounted) {
                    Toast.show(context, const Text('授权成功'));
                  }
                  widget.onStateChange();
                },
          child: const Text('OAuth - APP - SECRET'),
        ),
        if (authcodeSubscription != null)
          ElevatedButton(
            onPressed: authcodeSubscription,
            child: const Text('OAuth - CANCEL'),
          ),
      ],
    );
  }
}

class QrcodeOAuth extends StatefulWidget {
  const QrcodeOAuth({
    super.key,
    required this.title,
    required this.credentials,
    required this.client,
    required this.onStateChange,
  });

  final String title;
  final Credentials credentials;
  final AliyunpanClient client;
  final VoidCallback onStateChange;

  @override
  State<QrcodeOAuth> createState() => _QrcodeOAuthState();
}

class _QrcodeOAuthState extends State<QrcodeOAuth> {
  var qrcodeRequest = false;
  var qrcodeCancelToken = true;
  String? qrcodeUrl;
  AuthorizeState? qrcodeState;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ElevatedButton(
              onPressed: () async {
                qrcodeRequest = true;
                qrcodeCancelToken = false;
                await widget.client
                    .authorize(
                      widget.credentials,
                      onStateChange: (state) {
                        if (state is QrcodeAuthorizeReady) {
                          setState(() => qrcodeUrl = state.qrcodeUrl);
                        }
                        setState(() => qrcodeState = state);
                      },
                      canceled: () => qrcodeCancelToken,
                    )
                    .whenComplete(() => setState(() {
                          qrcodeRequest = false;
                          qrcodeUrl = null;
                          qrcodeState = null;
                        }));
                if (context.mounted) {
                  Toast.show(context, const Text('授权成功'));
                }
                widget.onStateChange();
              },
              child: Text(widget.title),
            ),
            if (qrcodeRequest)
              ElevatedButton(
                onPressed: () => qrcodeCancelToken = true,
                child: const Text('Cancel'),
              ),
          ],
        ),
        if (qrcodeState != null) Text('state: $qrcodeState'),
        if (qrcodeUrl != null) Image.network(qrcodeUrl!),
      ],
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key, required this.uri, this.accept});

  final Uri uri;
  final bool Function(String url)? accept;

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(const Color(0x00000000))
    ..setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          // Update loading bar.
        },
        onPageStarted: (String url) {
          if (widget.accept?.call(url) ?? false) {
            Navigator.pop(context, url);
          }
        },
      ),
    )
    ..loadRequest(widget.uri);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OAuth')),
      body: Platform.isIOS || Platform.isAndroid
          ? WebViewWidget(controller: controller)
          : const Center(
              child: Text(
                'WebView 仅支持 Android 和 Ios',
                style: TextStyle(fontSize: 48),
              ),
            ),
    );
  }
}

Dio get dio => Dio(BaseOptions(receiveDataWhenStatusError: true))
  ..interceptors.add(
    LogInterceptor(requestBody: true, responseBody: true),
  );

/// 可以将接口换成私有服务器, 将 secret 保存在私有服务器中
Future<Token> requestToken(String code) {
  return dio.post('https://openapi.alipan.com/oauth/access_token', data: {
    'client_id': appId,
    'client_secret': appSecret,
    'grant_type': 'authorization_code',
    'code': code,
  }).then((e) => Token.fromJson(e.data));
}

/// 可以将接口换成私有服务器, 将 secret 保存在私有服务器中
Future<Token> refreshToken(refreshToken) {
  return dio.post('https://openapi.alipan.com/oauth/access_token', data: {
    'client_id': appId,
    'client_secret': appSecret,
    'grant_type': 'refresh_token',
    'refresh_token': refreshToken,
  }).then((e) => Token.fromJson(e.data));
}

class FileScope extends StatelessWidget {
  const FileScope({super.key, required this.client, required this.drive});

  final AliyunpanClient client;
  final Drive drive;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('文件'),
        if (drive.backupDriveId != null)
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => DrivesPage(
                  title: '备份盘', client: client, driveId: drive.backupDriveId!),
            )),
            child: const Text('打开备份盘'),
          ),
        if (drive.resourceDriveId != null)
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) {
                return DrivesPage(
                    title: '资源库',
                    client: client,
                    driveId: drive.resourceDriveId!);
              },
            )),
            child: const Text('打开资源库'),
          ),
        if (drive.albumDriveId != null)
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return DrivesPage(
                    title: '相册', client: client, driveId: drive.albumDriveId!);
              },
            )),
            child: const Text('打开相册'),
          ),
      ],
    );
  }
}
