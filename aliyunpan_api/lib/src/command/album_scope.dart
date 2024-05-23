import '../model/album.dart';
import '../model/file.dart';
import 'command.dart';

/// [获取共享相册列表](https://www.yuque.com/aliyundrive/zpfszx/gnqh5a3aluhd0lbg#NRiFL)
class GetSharedAlbums extends Command<List<AlbumInfo>> {
  @override
  HttpMethod get method => HttpMethod.post;

  @override
  String get uri => '/adrive/v1.0/sharedAlbum/list';

  @override
  dynamic get data => null;

  @override
  List<AlbumInfo> parse(json) {
    return (json['items'] as List).map((e) => AlbumInfo.fromJson(e)).toList();
  }
}

/// [获取共享相册下文件](https://www.yuque.com/aliyundrive/zpfszx/gnqh5a3aluhd0lbg#iPmGb)
class GetAlbumFiles extends Command<List<FileInfo>> {
  const GetAlbumFiles({
    required this.sharedAlbumId,
    this.orderBy = 'joined_at',
    this.orderDirection = FileOrderDirection.desc,
    this.marker,
    this.limit = 50,
    this.imageThumbnailWidth = 480,
  });

  /// 共享相册ID
  final String sharedAlbumId;
  final String orderBy;
  final FileOrderDirection orderDirection;

  /// 分页标记
  final String? marker;
  final int limit;

  /// 生成的图片缩略图宽度
  final int imageThumbnailWidth;

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  String get uri => '/adrive/v1.0/sharedAlbum/listFile';

  @override
  dynamic get data => {
        'sharedAlbumId': sharedAlbumId,
        'order_by': orderBy,
        'order_direction': orderDirection.name,
        'marker': marker,
        'limit': limit,
        'image_thumbnail_width': imageThumbnailWidth,
      };

  @override
  List<FileInfo> parse(json) {
    return (json['items'] as List).map((e) => FileInfo.fromJson(e)).toList();
  }
}

/// [获取共享相册下文件下载地址](https://www.yuque.com/aliyundrive/zpfszx/gnqh5a3aluhd0lbg#mHX7s)
class GetAlbumFileDownloadUrl extends Command<AlbumFileDownloadUrl> {
  const GetAlbumFileDownloadUrl({
    required this.sharedAlbumId,
    required this.driveId,
    required this.fileId,
  });

  /// 共享相册ID
  final String sharedAlbumId;
  final String driveId;
  final String fileId;

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  String get uri => '/adrive/v1.0/sharedAlbum/getDownloadUrl';

  @override
  dynamic get data => {
        'sharedAlbumId': sharedAlbumId,
        'drive_id': driveId,
        'file_id': fileId,
      };

  @override
  AlbumFileDownloadUrl parse(json) => AlbumFileDownloadUrl.fromJson(json);
}
