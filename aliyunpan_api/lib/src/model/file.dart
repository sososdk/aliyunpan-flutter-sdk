class FileInfos {
  final List<FileInfo> items;
  final String? nextMarker;
  final int? totalCount;

  const FileInfos({required this.items, this.nextMarker, this.totalCount});

  factory FileInfos.fromJson(Map<String, dynamic> json) => FileInfos(
        items:
            (json['items'] as List).map((e) => FileInfo.fromJson(e)).toList(),
        nextMarker: json['next_marker'],
        totalCount: json['total_count'],
      );

  Map<String, dynamic> toJson() => {
        'items': items.map((e) => e.toJson()).toList(),
        'next_marker': nextMarker,
        'total_count': totalCount,
      };
}

class FileInfo {
  final String driveId;
  final String fileId;

  /// 根目录是 root
  final String parentFileId;

  /// 文件名
  final String name;
  final int? size;
  final String? fileExtension;

  /// 文件 hash
  final String? contentHash;
  final FileCategory? category;
  final FileType type;
  final String? mimeType;

  /// 缩略图
  final String? thumbnail;

  /// 图片预览图地址、小于 5MB 文件的下载地址。超过5MB 请使用 /getDownloadUrl
  final String? url;

  /// 下载地址
  final String? downloadUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  final bool starred;

  /// 播放进度
  final Duration? playCursor;

  /// 图片信息
  final MediaMetadata? imageMediaMetadata;

  /// 视频信息
  final MediaMetadata? videoMediaMetadata;

  /// 视频预览信息
  final AudioMetaData? videoPreviewMetadata;

  const FileInfo({
    required this.driveId,
    required this.fileId,
    required this.parentFileId,
    required this.name,
    this.size,
    this.fileExtension,
    this.contentHash,
    this.category,
    required this.type,
    this.mimeType,
    this.thumbnail,
    this.url,
    this.downloadUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.starred,
    this.playCursor,
    this.imageMediaMetadata,
    this.videoMediaMetadata,
    this.videoPreviewMetadata,
  });

  factory FileInfo.fromJson(Map<String, dynamic> json) => FileInfo(
        driveId: json['drive_id'],
        fileId: json['file_id'],
        parentFileId: json['parent_file_id'],
        name: json['name'],
        size: json['size'],
        fileExtension: json['file_extension'],
        contentHash: json['content_hash'],
        category: json['category'] == null
            ? null
            : FileCategory.fromString(json['category']),
        type: FileType.fromString(json['type']),
        mimeType: json['mime_type'],
        thumbnail: json['thumbnail'],
        url: json['url'],
        downloadUrl: json['download_url'],
        createdAt: DateTime.parse(json['created_at']).toLocal(),
        updatedAt: DateTime.parse(json['updated_at']).toLocal(),
        starred: json['starred'],
        playCursor: json['play_cursor'] == null
            ? null
            : Duration(
                milliseconds:
                    (double.parse(json['play_cursor']) * 1000).toInt(),
              ),
        imageMediaMetadata: json['image_media_metadata'] == null
            ? null
            : MediaMetadata.fromJson(json['image_media_metadata']),
        videoMediaMetadata: json['video_media_metadata'] == null
            ? null
            : MediaMetadata.fromJson(json['video_media_metadata']),
        videoPreviewMetadata: json['video_preview_metadata'] == null
            ? null
            : AudioMetaData.fromJson(json['video_preview_metadata']),
      );

  Map<String, dynamic> toJson() {
    return {
      'drive_id': driveId,
      'file_id': fileId,
      'parent_file_id': parentFileId,
      'name': name,
      'size': size,
      'file_extension': fileExtension,
      'content_hash': contentHash,
      'category': category?.name,
      'type': type.name,
      'mime_type': mimeType,
      'thumbnail': thumbnail,
      'url': url,
      'download_url': downloadUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'starred': starred,
      'play_cursor':
          playCursor == null ? null : playCursor!.inMilliseconds / 1000,
      'image_media_metadata': imageMediaMetadata?.toJson(),
      'video_media_metadata': videoMediaMetadata?.toJson(),
      'video_preview_metadata': videoPreviewMetadata?.toJson(),
    };
  }
}

enum FileType {
  file,
  folder;

  static FileType fromString(String name) {
    return FileType.values.firstWhere((e) => e.name == name);
  }
}

enum FileCategory {
  video,
  doc,
  audio,
  zip,
  others,
  image;

  static FileCategory fromString(String name) {
    return FileCategory.values.firstWhere((e) => e.name == name);
  }
}

enum VideoTemplate {
  /// 普通清晰度 360P
  ld,

  /// 标清 480P
  sd,

  /// 高清 720P
  hd,

  /// 全高清 1080P
  fdh,

  /// 超清 1440P
  qhd;

  String get name => switch (this) {
        VideoTemplate.ld => 'LD',
        VideoTemplate.sd => 'SD',
        VideoTemplate.hd => 'HD',
        VideoTemplate.fdh => 'FDH',
        VideoTemplate.qhd => 'QHD',
      };

  static VideoTemplate fromName(String name) {
    return VideoTemplate.values.firstWhere((e) => e.name == name);
  }
}

enum VideoTranscodingStatus {
  finished,
  running,
  failed;

  static VideoTranscodingStatus fromName(String name) {
    return VideoTranscodingStatus.values.firstWhere((e) => e.name == name);
  }
}

class MediaMetadata {
  final Duration? duration;
  final int? width;
  final int? height;
  final String? time;
  final String? location;
  final String? country;
  final String? province;
  final String? city;
  final String? district;
  final String? township;
  final String? exif;
  final List<VideoStream>? videoMediaVideoStream;
  final List<AudioStream>? videoMediaAudioStream;

  const MediaMetadata({
    this.duration,
    this.width,
    this.height,
    this.time,
    this.location,
    this.country,
    this.province,
    this.city,
    this.district,
    this.township,
    this.exif,
    this.videoMediaVideoStream,
    this.videoMediaAudioStream,
  });

  factory MediaMetadata.fromJson(Map<String, dynamic> json) => MediaMetadata(
        duration: json['duration'] == null
            ? null
            : Duration(
                milliseconds: (double.parse(json['duration']) * 1000).toInt(),
              ),
        width: json['width'],
        height: json['height'],
        time: json['time'],
        location: json['location'],
        country: json['country'],
        province: json['province'],
        city: json['city'],
        district: json['district'],
        township: json['township'],
        exif: json['exif'],
        videoMediaVideoStream: (json['video_media_video_stream'] as List?)
            ?.map((e) => VideoStream.fromJson(e))
            .toList(),
        videoMediaAudioStream: (json['video_media_audio_stream'] as List?)
            ?.map((e) => AudioStream.fromJson(e))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'duration': duration == null ? null : duration!.inMilliseconds / 1000,
        'width': width,
        'height': height,
        'time': time,
        'location': location,
        'country': country,
        'province': province,
        'city': city,
        'district': district,
        'township': township,
        'exif': exif,
        'video_media_video_stream':
            videoMediaVideoStream?.map((e) => e.toJson()).toList(),
        'video_media_audio_stream':
            videoMediaAudioStream?.map((e) => e.toJson()).toList(),
      };
}

class VideoStream {
  final Duration? duration;
  final String? clarity;
  final String? fps;
  final String? bitrate;
  final String? codeName;

  const VideoStream({
    this.duration,
    this.clarity,
    this.fps,
    this.bitrate,
    this.codeName,
  });

  factory VideoStream.fromJson(Map<String, dynamic> json) => VideoStream(
        duration: json['duration'] == null
            ? null
            : Duration(
                milliseconds: (double.parse(json['duration']) * 1000).toInt(),
              ),
        clarity: json['clarity'],
        fps: json['fps'],
        bitrate: json['bitrate'],
        codeName: json['code_name'],
      );

  Map<String, dynamic> toJson() => {
        'duration': duration == null ? null : duration!.inMilliseconds / 1000,
        'clarity': clarity,
        'fps': fps,
        'bitrate': bitrate,
        'code_name': codeName,
      };
}

class AudioStream {
  final Duration? duration;
  final int? channels;
  final String? channelLayout;
  final String? bitrate;
  final String? codeName;
  final String? sampleRate;

  const AudioStream({
    this.duration,
    this.channels,
    this.channelLayout,
    this.bitrate,
    this.codeName,
    this.sampleRate,
  });

  factory AudioStream.fromJson(Map<String, dynamic> json) => AudioStream(
        duration: json['duration'] == null
            ? null
            : Duration(
                milliseconds: (double.parse(json['duration']) * 1000).toInt(),
              ),
        channels: json['channels'],
        channelLayout: json['channel_layout'],
        bitrate: json['bitrate'],
        codeName: json['code_name'],
        sampleRate: json['sample_rate'],
      );

  Map<String, dynamic> toJson() => {
        'duration': duration == null ? null : duration!.inMilliseconds / 1000,
        'channels': channels,
        'channel_layout': channelLayout,
        'bitrate': bitrate,
        'code_name': codeName,
        'sample_rate': sampleRate,
      };
}

class AudioMetaData {
  const AudioMetaData({
    this.duration,
    this.bitrate,
    this.audioFormat,
    this.audioSampleRate,
    this.audioChannels,
    this.audioMeta,
    this.audioMusicMeta,
    this.templateList,
  });

  final Duration? duration;
  final String? bitrate;
  final String? audioFormat;
  final String? audioSampleRate;
  final int? audioChannels;
  final AudioMeta? audioMeta;
  final MusicMeta? audioMusicMeta;
  final List<Template>? templateList;

  factory AudioMetaData.fromJson(Map<String, dynamic> json) => AudioMetaData(
        duration: json['duration'] == null
            ? null
            : Duration(
                milliseconds: (double.parse(json['duration']) * 1000).toInt(),
              ),
        bitrate: json['bitrate'],
        audioFormat: json['audio_format'],
        audioSampleRate: json['audio_sample_rate'],
        audioChannels: json['audio_channels'],
        audioMeta: json['audio_meta'] == null
            ? null
            : AudioMeta.fromJson(json['audio_meta']),
        audioMusicMeta: json['audio_music_meta'] == null
            ? null
            : MusicMeta.fromJson(json['audio_music_meta']),
        templateList: (json['template_list'] as List?)
            ?.map((e) => Template.fromJson(e))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'duration': duration == null ? null : duration!.inMilliseconds / 1000,
        'bitrate': bitrate,
        'audio_format': audioFormat,
        'audio_sample_rate': audioSampleRate,
        'audio_channels': audioChannels,
        'audio_meta': audioMeta?.toJson(),
        'audio_music_meta': audioMusicMeta?.toJson(),
        'template_list': templateList?.map((e) => e.toJson()).toList(),
      };
}

class AudioMeta {
  const AudioMeta({
    this.duration,
    this.bitrate,
    this.sampleRate,
    this.channels,
  });

  final Duration? duration;
  final String? bitrate;
  final String? sampleRate;
  final int? channels;

  factory AudioMeta.fromJson(Map<String, dynamic> json) => AudioMeta(
        duration: json['duration'] == null
            ? null
            : Duration(
                milliseconds: (double.parse(json['duration']) * 1000).toInt(),
              ),
        bitrate: json['bitrate'],
        sampleRate: json['sample_rate'],
        channels: json['channels'],
      );

  Map<String, dynamic> toJson() => {
        'duration': duration == null ? null : duration!.inMilliseconds / 1000,
        'bitrate': bitrate,
        'sample_rate': sampleRate,
        'channels': channels,
      };
}

class MusicMeta {
  const MusicMeta({
    this.title,
    this.artist,
    this.album,
    this.coverUrl,
  });

  final String? title;
  final String? artist;
  final String? album;
  final String? coverUrl;

  factory MusicMeta.fromJson(Map<String, dynamic> json) => MusicMeta(
        title: json['title'],
        artist: json['artist'],
        album: json['album'],
        coverUrl: json['cover_url'],
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'artist': artist,
        'album': album,
        'cover_url': coverUrl,
      };
}

class Template {
  const Template({
    this.templateId,
    this.status,
    this.url,
    this.previewUrl,
  });

  final VideoTemplate? templateId;
  final VideoTranscodingStatus? status;
  final String? url;
  final String? previewUrl;

  factory Template.fromJson(Map<String, dynamic> json) => Template(
        templateId: VideoTemplate.fromName(json['template_id']),
        status: json['status'] == null
            ? null
            : VideoTranscodingStatus.fromName(json['status']),
        url: json['url'],
        previewUrl: json['preview_url'],
      );

  Map<String, dynamic> toJson() => {
        'template_id': templateId?.name,
        'status': status?.name,
        'url': url,
        'preview_url': previewUrl,
      };
}

/// # 最佳实践
///
/// ## 小文件单次下载
/// 当文件较小（10M以下的小文件）时，从获取到的地址下载文件，如果下载失败，重新下载。
///
/// ## 大文件分段断点续传下载
/// 当文件下载中断后，可基于当前已经下载的位置为起点请求剩余数据，以提供断点续传功能。 在请求的header中设置Range头，如：
/// Range: bytes=100-
/// 设置范围左闭右开，例如100- 表示下载从第 100 字节开始的整个文件。
///
/// ## 大文件分段并发下载
/// 并发下载一个文件的不同分段，最后按分段位置合成文件，以提升下载速度。 分段请求需在请求的header中设置Range头，如：
/// Range:bytes=0-100
/// 设置范围左闭右闭，例如0-100表示下载第 0~100 字节范围的内容。
///
/// > 注意：并发下载线程数不要超过10，否则会有风控检测处罚的风险
class DownloadUrl {
  /// 下载地址
  final String url;

  /// 过期时间
  final DateTime expiration;

  /// 下载方法
  final String method;

  const DownloadUrl({
    required this.url,
    required this.expiration,
    required this.method,
  });

  factory DownloadUrl.fromJson(Map<String, dynamic> json) => DownloadUrl(
        url: json['url'],
        expiration: DateTime.parse(json['expiration']).toLocal(),
        method: json['method'],
      );

  Map<String, dynamic> toJson() => {
        'url': url,
        'expiration': expiration.toIso8601String(),
        'method': method,
      };
}

class PartInfo {
  /// 分片编号
  final int partNumber;

  /// etag， 在上传分片结束后，服务端会返回这个分片的Etag，在complete的时候可以在uploadInfo指定分片的Etag，服务端会在合并时对每个分片Etag做校验
  final String? etag;

  /// 文件的上传地址
  final String? uploadUrl;

  /// 分片大小
  final int? partSize;

  const PartInfo({
    required this.partNumber,
    this.partSize,
    this.etag,
    this.uploadUrl,
  });

  factory PartInfo.fromJson(Map<String, dynamic> json) => PartInfo(
        partNumber: json['part_number'],
        etag: json['etag'],
        uploadUrl: json['upload_url'],
        partSize: json['part_size'],
      );

  Map<String, dynamic> toJson() => {
        'part_number': partNumber,
        if (etag != null) 'etag': etag,
        if (uploadUrl != null) 'upload_url': uploadUrl,
        if (partSize != null) 'part_size': partSize,
      };
}

class StreamsInfo {
  final String? contentHash;
  final String? contentHashName;
  final String? proofVersion;
  final String? contentMd5;
  final String? preHash;
  final String? size;
  final List<PartInfo>? partInfoList;

  const StreamsInfo({
    this.contentHash,
    this.contentHashName,
    this.proofVersion,
    this.contentMd5,
    this.preHash,
    this.size,
    this.partInfoList,
  });

  factory StreamsInfo.fromJson(Map<String, dynamic> json) => StreamsInfo(
        contentHash: json['content_hash'],
        contentHashName: json['content_hash_name'],
        proofVersion: json['proof_version'],
        contentMd5: json['content_md5'],
        preHash: json['pre_hash'],
        size: json['size'],
        partInfoList: (json['part_info_list'] as List<dynamic>?)
            ?.map((item) => PartInfo.fromJson(item))
            .toList(),
      );

  Map<String, dynamic> toJson() {
    return {
      'content_hash': contentHash,
      'content_hash_name': contentHashName,
      'proof_version': proofVersion,
      'content_md5': contentMd5,
      'pre_hash': preHash,
      'size': size,
      'part_info_list': partInfoList?.map((item) => item.toJson()).toList(),
    };
  }
}

class FileCreated {
  final String driveId;
  final String fileId;

  final String? status;
  final String parentFileId;

  /// 创建文件夹返回空
  final String? uploadId;
  final String fileName;
  final bool? available;

  /// 是否存在同名文件
  final bool? exist;

  /// 是否秒传
  final bool? rapidUpload;
  final List<PartInfo>? partInfoList;

  const FileCreated({
    required this.driveId,
    required this.fileId,
    required this.status,
    required this.parentFileId,
    this.uploadId,
    required this.fileName,
    required this.available,
    required this.exist,
    this.rapidUpload,
    required this.partInfoList,
  });

  factory FileCreated.fromJson(Map<String, dynamic> json) => FileCreated(
        driveId: json['drive_id'],
        fileId: json['file_id'],
        status: json['status'],
        parentFileId: json['parent_file_id'],
        uploadId: json['upload_id'],
        fileName: json['file_name'],
        available: json['available'],
        exist: json['exist'],
        rapidUpload: json['rapid_upload'],
        partInfoList: (json['part_info_list'] as List?)
            ?.map((e) => PartInfo.fromJson(e))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'drive_id': driveId,
        'file_id': fileId,
        'status': status,
        'parent_file_id': parentFileId,
        'upload_id': uploadId,
        'file_name': fileName,
        'available': available,
        'exist': exist,
        'rapid_upload': rapidUpload,
        'part_info_list': partInfoList?.map((e) => e.toJson()).toList(),
      };
}

class UploadUrl {
  final String driveId;
  final String fileId;
  final String uploadId;
  final List<PartInfo> partInfoList;

  const UploadUrl({
    required this.driveId,
    required this.fileId,
    required this.uploadId,
    required this.partInfoList,
  });

  factory UploadUrl.fromJson(Map<String, dynamic> json) => UploadUrl(
        driveId: json['drive_id'],
        fileId: json['file_id'],
        uploadId: json['upload_id'],
        partInfoList: (json['part_info_list'] as List)
            .map((e) => PartInfo.fromJson(e))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'drive_id': driveId,
        'file_id': fileId,
        'upload_id': uploadId,
        'part_info_list': partInfoList.map((e) => e.toJson()).toList(),
      };
}

class UploadedParts {
  final bool parallelUpload;
  final List<PartInfo> uploadedParts;
  final String? nextPartNumberMarker;

  const UploadedParts({
    required this.parallelUpload,
    required this.uploadedParts,
    required this.nextPartNumberMarker,
  });

  factory UploadedParts.fromJson(Map<String, dynamic> json) => UploadedParts(
        parallelUpload: json['parallelUpload'],
        uploadedParts: (json['uploaded_parts'] as List)
            .map((e) => PartInfo.fromJson(e))
            .toList(),
        nextPartNumberMarker: json['next_part_number_marker'],
      );

  Map<String, dynamic> toJson() => {
        'parallelUpload': parallelUpload,
        'uploaded_parts': uploadedParts.map((e) => e.toJson()).toList(),
        'next_part_number_marker': nextPartNumberMarker,
      };
}

class FileMoved {
  final String driveId;
  final String fileId;

  /// 异步任务id。如果返回为空字符串，表示直接移动成功。如果返回非空字符串，表示需要经过异步处理。
  final String? asyncTaskId;

  /// 文件是否已存在
  final bool exist;

  const FileMoved({
    required this.driveId,
    required this.fileId,
    required this.asyncTaskId,
    required this.exist,
  });

  factory FileMoved.fromJson(Map<String, dynamic> json) => FileMoved(
        driveId: json['drive_id'],
        fileId: json['file_id'],
        asyncTaskId: json['async_task_id'],
        exist: json['exist'],
      );

  Map<String, dynamic> toJson() => {
        'drive_id': driveId,
        'file_id': fileId,
        'async_task_id': asyncTaskId,
        'exist': exist,
      };
}

class FileCopied {
  final String driveId;
  final String fileId;

  /// 异步任务id。如果返回为空字符串，表示直接移动成功。如果返回非空字符串，表示需要经过异步处理。
  final String? asyncTaskId;

  const FileCopied({
    required this.driveId,
    required this.fileId,
    required this.asyncTaskId,
  });

  factory FileCopied.fromJson(Map<String, dynamic> json) => FileCopied(
        driveId: json['drive_id'],
        fileId: json['file_id'],
        asyncTaskId: json['async_task_id'],
      );

  Map<String, dynamic> toJson() => {
        'drive_id': driveId,
        'file_id': fileId,
        'async_task_id': asyncTaskId,
      };
}

class FileOperated {
  final String? driveId;
  final String? fileId;

  /// 异步任务id。如果返回为空字符串，表示直接移动成功。如果返回非空字符串，表示需要经过异步处理。
  final String? asyncTaskId;

  const FileOperated({
    this.driveId,
    this.fileId,
    this.asyncTaskId,
  });

  factory FileOperated.fromJson(Map<String, dynamic> json) => FileOperated(
        driveId: json['drive_id'],
        fileId: json['file_id'],
        asyncTaskId: json['async_task_id'],
      );

  Map<String, dynamic> toJson() => {
        'drive_id': driveId,
        'file_id': fileId,
        'async_task_id': asyncTaskId,
      };
}

enum OperateState {
  succeed,
  running,
  failed;

  String get name => switch (this) {
        OperateState.succeed => 'Succeed',
        OperateState.running => 'Running',
        OperateState.failed => 'Failed'
      };

  static OperateState fromName(String name) {
    return OperateState.values.firstWhere((e) => e.name == name);
  }
}
