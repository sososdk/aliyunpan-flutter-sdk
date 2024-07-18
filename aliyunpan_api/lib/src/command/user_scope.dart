import '../model/drive.dart';
import '../model/space.dart';
import '../model/user.dart';
import '../model/vip.dart';
import 'command.dart';

/// [获取用户信息](https://www.yuque.com/aliyundrive/zpfszx/mbb50w#xZ6HQ)
class GetUser extends Command<User> {
  const GetUser();

  @override
  HttpMethod get method => HttpMethod.get;

  @override
  String get uri => '/oauth/users/info';

  @override
  dynamic get data => null;

  @override
  User parse(dynamic json) => User.fromJson(json);
}

/// [获取用户drive信息](https://www.yuque.com/aliyundrive/zpfszx/mbb50w#i8saM)
class GetDrive extends Command<Drive> {
  const GetDrive();

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  String get uri => '/adrive/v1.0/user/getDriveInfo';

  @override
  dynamic get data => null;

  @override
  Drive parse(dynamic json) => Drive.fromJson(json);
}

/// [获取用户空间信息](https://www.yuque.com/aliyundrive/zpfszx/mbb50w#PzzWh)
class GetSpace extends Command<Space> {
  const GetSpace();

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  String get uri => '/adrive/v1.0/user/getSpaceInfo';

  @override
  dynamic get data => null;

  @override
  Space parse(dynamic json) => Space.fromJson(json);
}

/// [获取用户vip信息](https://www.yuque.com/aliyundrive/zpfszx/mbb50w#uz912)
class GetVip extends Command<Vip> {
  const GetVip();

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  String get uri => '/business/v1.0/user/getVipInfo';

  @override
  dynamic get data => null;

  @override
  Vip parse(dynamic json) => Vip.fromJson(json);
}
