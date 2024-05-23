import '../model/vip_feature.dart';
import 'command.dart';

/// [付费功能列表](https://www.yuque.com/aliyundrive/zpfszx/ik0exrgmgh159ne0#TCcVY)
class GetVipFeatures extends Command<List<VipFeature>> {
  const GetVipFeatures();

  @override
  HttpMethod get method => HttpMethod.get;

  @override
  String get uri => '/business/v1.0/vip/feature/list';

  @override
  dynamic get data => null;

  @override
  List<VipFeature> parse(dynamic json) {
    return (json['result'] as List).map((e) => VipFeature.fromJson(e)).toList();
  }
}

/// [试用付费功能](https://www.yuque.com/aliyundrive/zpfszx/ik0exrgmgh159ne0#BYlbz)
class GetVipFeatureTrial extends Command<VipFeatureTrial> {
  const GetVipFeatureTrial({required this.featureCode});

  final String featureCode;

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  String get uri => '/business/v1.0/vip/feature/trial';

  @override
  dynamic get data => {'featureCode': featureCode};

  @override
  VipFeatureTrial parse(dynamic json) => VipFeatureTrial.fromJson(json);
}
