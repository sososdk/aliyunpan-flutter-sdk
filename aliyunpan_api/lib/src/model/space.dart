class Space {
  final SpaceInfo personalSpaceInfo;

  const Space({required this.personalSpaceInfo});

  factory Space.fromJson(Map<String, dynamic> json) => Space(
        personalSpaceInfo: SpaceInfo.fromJson(json['personal_space_info']),
      );
}

class SpaceInfo {
  /// 使用容量，单位bytes
  final int usedSize;

  /// 总容量，单位bytes
  final int totalSize;

  const SpaceInfo({
    required this.usedSize,
    required this.totalSize,
  });

  factory SpaceInfo.fromJson(Map<String, dynamic> json) => SpaceInfo(
        usedSize: json['used_size'],
        totalSize: json['total_size'],
      );

  Map<String, dynamic> toJson() => {
        'used_size': usedSize,
        'total_size': totalSize,
      };
}
