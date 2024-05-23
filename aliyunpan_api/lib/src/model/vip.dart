class Vip {
  final VipIdentity identity;

  /// 20TB、8TB
  final String? level;

  /// 过期时间，时间戳，单位秒
  final int? expire;

  /// “三方权益包”是否生效
  final bool? thirdPartyVip;

  /// 	“三方权益包”过期时间
  final int? thirdPartyVipExpire;

  const Vip({
    required this.identity,
    this.level,
    this.expire,
    this.thirdPartyVip,
    this.thirdPartyVipExpire,
  });

  factory Vip.fromJson(Map<String, dynamic> json) => Vip(
        identity: VipIdentity.fromName(json['identity']),
        level: json['level'],
        expire: json['expire'],
        thirdPartyVip: json['third_party_vip'],
        thirdPartyVipExpire: json['third_party_vip_expire'],
      );

  Map<String, dynamic> toJson() => {
        'identity': identity.name,
        'level': level,
        'expire': expire,
        'third_party_vip': thirdPartyVip,
        'third_party_vip_expire': thirdPartyVipExpire,
      };
}

enum VipIdentity {
  member,
  vip,
  svip;

  static VipIdentity fromName(String name) {
    return VipIdentity.values.firstWhere((e) => e.name == name);
  }
}
