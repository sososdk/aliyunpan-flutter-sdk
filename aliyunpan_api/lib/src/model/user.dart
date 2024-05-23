class User {
  ///	用户ID，具有唯一性
  final String id;

  /// 昵称
  final String name;

  /// 头像地址（没有头像返回空）
  final String avatar;

  /// 需要联系运营申请 user:phone 权限
  final String? phone;

  const User({
    required this.id,
    required this.name,
    required this.avatar,
    this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        name: json['name'],
        avatar: json['avatar'],
        phone: json['phone'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar': avatar,
        'phone': phone,
      };
}
