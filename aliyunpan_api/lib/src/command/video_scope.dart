import '../model/file.dart';
import '../model/video.dart';
import 'command.dart';

/// [获取文件播放详情](https://www.yuque.com/aliyundrive/zpfszx/xegh9q#ffiZB)
class GetVideoPlayInfo extends Command<VideoInfo> {
  const GetVideoPlayInfo({
    required this.driveId,
    required this.fileId,
    this.category = 'live_transcoding',
    this.getSubtitleInfo = true,
    this.templates = VideoTemplate.values,
    this.urlExpire = const Duration(minutes: 15),
    this.onlyVip = false,
    this.withPlayCursor = false,
  });

  final String driveId;
  final String fileId;
  final String category;
  final bool getSubtitleInfo;

  /// 默认所有类型
  final List<VideoTemplate> templates;
  final Duration urlExpire;

  /// 仅会员可以查看所有内容
  final bool onlyVip;

  /// 是否获取视频的播放进度
  final bool withPlayCursor;

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  String get uri => '/adrive/v1.0/openFile/getVideoPreviewPlayInfo';

  @override
  dynamic get data => {
        'drive_id': driveId,
        'file_id': fileId,
        'category': category,
        'get_subtitle_info': getSubtitleInfo,
        'template_id': templates.map((e) => e.name).join(','),
        'url_expire_sec': urlExpire.inSeconds,
        'only_vip': onlyVip,
        'with_play_cursor': withPlayCursor,
      };

  @override
  VideoInfo parse(json) => VideoInfo.fromJson(json);
}

/// [获取文件播放元数据](https://www.yuque.com/aliyundrive/zpfszx/xegh9q#QqYj1)
class GetVideoPlayMeta extends Command<VideoInfo> {
  const GetVideoPlayMeta({
    required this.driveId,
    required this.fileId,
    this.category = 'live_transcoding',
    this.templates = VideoTemplate.values,
  });

  final String driveId;
  final String fileId;
  final String category;

  /// 默认所有类型
  final List<VideoTemplate> templates;

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  String get uri => '/adrive/v1.0/openFile/getVideoPreviewPlayMeta';

  @override
  dynamic get data => {
        'drive_id': driveId,
        'file_id': fileId,
        'category': category,
        'template_id': templates.map((e) => e.name).join(','),
      };

  @override
  VideoInfo parse(json) => VideoInfo.fromJson(json);
}

/// [更新播放进度](https://www.yuque.com/aliyundrive/zpfszx/xegh9q#blGYD)
class UpdateVideoRecord extends Command<UpdateVideoRecordResult> {
  const UpdateVideoRecord({
    required this.driveId,
    required this.fileId,
    required this.playCursor,
    required this.duration,
  });

  final String driveId;
  final String fileId;

  /// 播放进度，单位s，可为小数
  final Duration playCursor;

  /// 视频总时长，单位s，可为小数
  final Duration duration;

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  String get uri => '/adrive/v1.0/openFile/video/updateRecord';

  @override
  dynamic get data => {
        'drive_id': driveId,
        'file_id': fileId,
        'play_cursor': playCursor.inMilliseconds / 1000,
        'duration': duration.inMilliseconds / 1000,
      };

  @override
  UpdateVideoRecordResult parse(json) => UpdateVideoRecordResult.fromJson(json);
}

/// [获取最近播放列表](https://www.yuque.com/aliyundrive/zpfszx/xegh9q#Pa37C)
class GetRecentVideos extends Command<List<FileInfo>> {
  const GetRecentVideos({this.videoThumbnailWidth = 480});

  /// 缩略图宽度
  final int videoThumbnailWidth;

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  String get uri => '/adrive/v1.1/openFile/video/recentList';

  @override
  dynamic get data => {
        'video_thumbnail_width': videoThumbnailWidth,
      };

  @override
  List<FileInfo> parse(json) {
    return (json['items'] as List).map((e) => FileInfo.fromJson(e)).toList();
  }
}
