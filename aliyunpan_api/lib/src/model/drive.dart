class Drive {
  // 用户ID，具有唯一性
  final String userId;

  /// 昵称
  final String name;

  /// 头像地址
  final String avatar;

  /// 默认drive
  final String defaultDriveId;

  /// 资源库。用户选择了授权才会返回
  final String? resourceDriveId;

  /// 备份盘。用户选择了授权才会返回
  final String? backupDriveId;

  /// 相册盘。用户选择了授权才会返回
  final String? albumDriveId;

  const Drive({
    required this.userId,
    required this.name,
    required this.avatar,
    required this.defaultDriveId,
    this.resourceDriveId,
    this.backupDriveId,
    this.albumDriveId,
  });

  factory Drive.fromJson(Map<String, dynamic> json) => Drive(
        userId: json['user_id'],
        name: json['name'],
        avatar: json['avatar'],
        defaultDriveId: json['default_drive_id'],
        resourceDriveId: json['resource_drive_id'],
        backupDriveId: json['backup_drive_id'],
        albumDriveId: json['album_drive_id'],
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'name': name,
        'avatar': avatar,
        'default_drive_id': defaultDriveId,
        'resource_drive_id': resourceDriveId,
        'backup_drive_id': backupDriveId,
        'album_drive_id': albumDriveId,
      };
}
