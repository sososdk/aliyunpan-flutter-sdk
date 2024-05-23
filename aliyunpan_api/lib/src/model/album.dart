class AlbumInfo {
  /// 共享相册唯一ID
  final String sharedAlbumId;

  /// 共相册名称
  final String name;

  /// 共享相册简介
  final String? description;

  /// 封面图地址
  final String? coverThumbnail;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AlbumInfo({
    required this.sharedAlbumId,
    required this.name,
    required this.description,
    required this.coverThumbnail,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AlbumInfo.fromJson(Map<String, dynamic> json) => AlbumInfo(
        sharedAlbumId: json['sharedAlbumId'],
        name: json['name'],
        description: json['description'],
        coverThumbnail: json['coverThumbnail'],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );

  Map<String, dynamic> toJson() => {
        'sharedAlbumId': sharedAlbumId,
        'name': name,
        'description': description,
        'coverThumbnail': coverThumbnail,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class AlbumFileDownloadUrl {
  /// 下载地址，如果文件是livp时为空
  final String? url;

  /// 文件是livp时有值
  final AlbumFileStreamsUrl? streamsUrl;

  /// 下载地址有效时间
  final DateTime expiration;

  /// 文件大小
  final int size;

  /// 文件哈希
  final String contentHash;

  const AlbumFileDownloadUrl({
    required this.url,
    required this.streamsUrl,
    required this.expiration,
    required this.size,
    required this.contentHash,
  });

  factory AlbumFileDownloadUrl.fromJson(Map<String, dynamic> json) =>
      AlbumFileDownloadUrl(
        url: json['url'],
        streamsUrl: json['streams_url'] != null
            ? AlbumFileStreamsUrl.fromJson(json['streams_url'])
            : null,
        expiration: DateTime.parse(json['expiration']),
        size: json['size'],
        contentHash: json['content_hash'],
      );

  Map<String, dynamic> toJson() => {
        'url': url,
        'streams_url': streamsUrl?.toJson(),
        'expiration': expiration.toIso8601String(),
        'size': size,
        'content_hash': contentHash,
      };
}

class AlbumFileStreamsUrl {
  /// livp图片
  final String heic;

  /// livp动画
  final String mov;

  AlbumFileStreamsUrl({required this.heic, required this.mov});

  factory AlbumFileStreamsUrl.fromJson(Map<String, dynamic> json) =>
      AlbumFileStreamsUrl(
        heic: json['heic'],
        mov: json['mov'],
      );

  Map<String, dynamic> toJson() => {
        'heic': heic,
        'mov': mov,
      };
}
