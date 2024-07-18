import '../../aliyunpan_api.dart';

/// [获取文件列表](https://www.yuque.com/aliyundrive/zpfszx/zqkqp6#DEYA4)
class GetFiles extends Command<FileInfos> {
  const GetFiles({
    required this.driveId,
    this.limit = 50,
    this.marker,
    this.orderBy = FileOrder.updatedAt,
    this.orderDirection = FileOrderDirection.asc,
    this.parentFileId,
    this.categories,
    this.type,
    this.videoThumbnailTime = const Duration(seconds: 120),
    this.videoThumbnailWidth = 480,
    this.imageThumbnailWidth = 480,
    this.fields = '*',
  });

  final String driveId;

  /// 返回文件数量，默认 50，最大 100
  final int limit;

  /// 分页标记
  final String? marker;
  final FileOrder orderBy;

  final FileOrderDirection orderDirection;

  /// 父目录id，根目录为root
  final String? parentFileId;
  final List<FileCategory>? categories;
  final FileType? type;

  /// 生成的视频缩略图截帧时间，单位ms，默认120000ms
  final Duration videoThumbnailTime;

  /// 生成的视频缩略图宽度，默认480px
  final int videoThumbnailWidth;

  /// 生成的图片缩略图宽度，默认480px
  final int imageThumbnailWidth;

  /// 当填 * 时，返回文件所有字段。或某些字段，逗号分隔： id_path,name_path
  final String fields;

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  String get uri => '/adrive/v1.0/openFile/list';

  @override
  dynamic get data => {
        'drive_id': driveId,
        'limit': limit,
        'marker': marker,
        'order_by': orderBy.name,
        'order_direction': orderDirection.name,
        'parent_file_id': parentFileId ?? 'root',
        'category': categories?.map((e) => e.name).join(','),
        'type': type?.name,
        'video_thumbnail_time': videoThumbnailTime.inMilliseconds,
        'video_thumbnail_width': videoThumbnailWidth,
        'image_thumbnail_width': imageThumbnailWidth,
        'fields': fields,
      };

  @override
  FileInfos parse(dynamic json) => FileInfos.fromJson(json);
}

/// [文件搜索](https://www.yuque.com/aliyundrive/zpfszx/zqkqp6#MtYnx)
class SearchFiles extends Command<FileInfos> {
  const SearchFiles({
    required this.driveId,
    this.limit = 50,
    this.marker,
    required this.query,
    this.orderBy = FileOrder.updatedAt,
    this.orderDirection = FileOrderDirection.asc,
    this.videoThumbnailTime = const Duration(seconds: 120),
    this.videoThumbnailWidth = 480,
    this.imageThumbnailWidth = 480,
    this.returnTotalCount = false,
  });

  final String driveId;

  /// 返回文件数量，默认 50，最大 100
  final int limit;

  /// 分页标记
  final String? marker;

  /// query拼接的条件 <= 5个
  ///
  /// 查询语句，样例：
  /// 固定目录搜索，只搜索一级 parent_file_id = '123'
  /// 精确查询 name = '123'
  /// 模糊匹配 name match "123"
  /// 搜索指定后缀文件 file_extension = 'apk'
  /// 范围查询 created_at < "2019-01-14T00:00:00"
  /// 复合查询：
  /// type = 'folder' or name = '123'
  /// parent_file_id = 'root' and name = '123' and category = 'video'
  final String query;
  final FileOrder orderBy;
  final FileOrderDirection orderDirection;

  /// 生成的视频缩略图截帧时间，单位ms，默认120000ms
  final Duration videoThumbnailTime;

  /// 生成的视频缩略图宽度，默认480px
  final int videoThumbnailWidth;

  /// 生成的图片缩略图宽度，默认480px
  final int imageThumbnailWidth;

  /// 是否返回总数
  final bool returnTotalCount;

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  String get uri => '/adrive/v1.0/openFile/search';

  @override
  dynamic get data => {
        'drive_id': driveId,
        'limit': limit,
        'marker': marker,
        'query': query,
        'order_by': '${orderBy.name} ${orderDirection.name}',
        'video_thumbnail_time': videoThumbnailTime.inMilliseconds,
        'video_thumbnail_width': videoThumbnailWidth,
        'image_thumbnail_width': imageThumbnailWidth,
        'return_total_count': returnTotalCount,
      };

  @override
  FileInfos parse(json) => FileInfos.fromJson(json);
}

/// [获取收藏文件列表](https://www.yuque.com/aliyundrive/zpfszx/zqkqp6#RpiXF)
class StarredFiles extends Command<FileInfos> {
  const StarredFiles({
    required this.driveId,
    this.limit = 50,
    this.marker,
    this.orderBy = FileOrder.updatedAt,
    this.orderDirection = FileOrderDirection.asc,
    this.type,
    this.videoThumbnailTime = const Duration(seconds: 120),
    this.videoThumbnailWidth = 480,
    this.imageThumbnailWidth = 480,
  });

  final String driveId;

  /// 返回文件数量，默认 50，最大 100
  final int limit;

  /// 分页标记
  final String? marker;
  final FileOrder orderBy;
  final FileOrderDirection orderDirection;
  final FileType? type;

  /// 生成的视频缩略图截帧时间，单位ms，默认120000ms
  final Duration videoThumbnailTime;

  /// 生成的视频缩略图宽度，默认480px
  final int videoThumbnailWidth;

  /// 生成的图片缩略图宽度，默认480px
  final int imageThumbnailWidth;

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  String get uri => '/adrive/v1.0/openFile/starredList';

  @override
  dynamic get data => {
        'drive_id': driveId,
        'limit': limit,
        'marker': marker,
        'order_by': orderBy.name,
        'order_direction': orderDirection.name,
        'type': type?.name,
        'video_thumbnail_time': videoThumbnailTime.inMilliseconds,
        'video_thumbnail_width': videoThumbnailWidth,
        'image_thumbnail_width': imageThumbnailWidth,
      };

  @override
  FileInfos parse(json) => FileInfos.fromJson(json);
}

/// [获取文件详情](https://www.yuque.com/aliyundrive/zpfszx/gogo34oi2gy98w5d#xCOjJ)
class GetFile extends Command<FileInfo> {
  const GetFile({
    required this.driveId,
    required this.fileId,
    this.videoThumbnailTime = const Duration(seconds: 120),
    this.videoThumbnailWidth = 480,
    this.imageThumbnailWidth = 480,
    this.fields,
  });

  final String driveId;
  final String fileId;

  /// 生成的视频缩略图截帧时间，单位ms，默认120000ms
  final Duration videoThumbnailTime;

  /// 生成的视频缩略图宽度，默认480px
  final int videoThumbnailWidth;

  /// 生成的图片缩略图宽度，默认480px
  final int imageThumbnailWidth;

  /// 指定返回某些字段，逗号分隔： id_path,name_path
  final String? fields;

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  String get uri => '/adrive/v1.0/openFile/get';

  @override
  dynamic get data => {
        'drive_id': driveId,
        'file_id': fileId,
        'video_thumbnail_time': videoThumbnailTime.inMilliseconds,
        'video_thumbnail_width': videoThumbnailWidth,
        'image_thumbnail_width': imageThumbnailWidth,
        'fields': fields,
      };

  @override
  FileInfo parse(json) => FileInfo.fromJson(json);
}

/// [文件路径查找文件](https://www.yuque.com/aliyundrive/zpfszx/gogo34oi2gy98w5d#zbKww)
class GetFileByPath extends Command<FileInfo> {
  const GetFileByPath({
    required this.driveId,
    required this.filePath,
    this.videoThumbnailTime = const Duration(seconds: 120),
    this.videoThumbnailWidth = 480,
    this.imageThumbnailWidth = 480,
    this.fields,
  });

  final String driveId;
  final String filePath;

  /// 生成的视频缩略图截帧时间，单位ms，默认120000ms
  final Duration videoThumbnailTime;

  /// 生成的视频缩略图宽度，默认480px
  final int videoThumbnailWidth;

  /// 生成的图片缩略图宽度，默认480px
  final int imageThumbnailWidth;

  /// 指定返回某些字段，逗号分隔： id_path,name_path
  final String? fields;

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  String get uri => '/adrive/v1.0/openFile/get_by_path';

  @override
  dynamic get data => {
        'drive_id': driveId,
        'file_path': filePath,
        'video_thumbnail_time': videoThumbnailTime.inMilliseconds,
        'video_thumbnail_width': videoThumbnailWidth,
        'image_thumbnail_width': imageThumbnailWidth,
        'fields': fields,
      };

  @override
  FileInfo parse(json) => FileInfo.fromJson(json);
}

class FileParam {
  final String driveId;
  final String fileId;

  const FileParam({required this.driveId, required this.fileId});

  Map<String, dynamic> toJson() => {
        'drive_id': driveId,
        'file_id': fileId,
      };
}

/// [批量获取文件详情](https://www.yuque.com/aliyundrive/zpfszx/gogo34oi2gy98w5d#I1QQl)
class GetBatchFiles extends Command<List<FileInfo>> {
  const GetBatchFiles({
    required this.files,
    this.videoThumbnailTime = const Duration(seconds: 120),
    this.videoThumbnailWidth = 480,
    this.imageThumbnailWidth = 480,
    this.fields,
  });

  final List<FileParam> files;

  /// 生成的视频缩略图截帧时间，单位ms，默认120000ms
  final Duration videoThumbnailTime;

  /// 生成的视频缩略图宽度，默认480px
  final int videoThumbnailWidth;

  /// 生成的图片缩略图宽度，默认480px
  final int imageThumbnailWidth;

  /// 指定返回某些字段，逗号分隔： id_path,name_path
  final String? fields;

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  String get uri => '/adrive/v1.0/openFile/batch/get';

  @override
  dynamic get data => {
        'file_list': files.map((e) => e.toJson()).toList(),
        'video_thumbnail_time': videoThumbnailTime.inMilliseconds,
        'video_thumbnail_width': videoThumbnailWidth,
        'image_thumbnail_width': imageThumbnailWidth,
        'fields': fields,
      };

  @override
  List<FileInfo> parse(json) {
    return (json as List).map((e) => FileInfo.fromJson(e)).toList();
  }
}

/// [获取文件下载链接](https://www.yuque.com/aliyundrive/zpfszx/gogo34oi2gy98w5d#mN50J)
class GetDownloadUrl extends Command<DownloadUrl> {
  const GetDownloadUrl({
    required this.driveId,
    required this.fileId,
    this.expire = const Duration(seconds: 900),
  });

  factory GetDownloadUrl.fromFile(
    FileInfo file, {
    Duration expire = const Duration(seconds: 900),
  }) {
    return GetDownloadUrl(
        driveId: file.driveId, fileId: file.fileId, expire: expire);
  }

  final String driveId;
  final String fileId;

  /// 最长过期时间为900s，若达到优质应用标准，最长4h（14400秒）详见: [应用分级](https://www.yuque.com/aliyundrive/zpfszx/mqocg38hlxzc5vcd)
  final Duration expire;

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  String get uri => '/adrive/v1.0/openFile/getDownloadUrl';

  @override
  dynamic get data => {
        'drive_id': driveId,
        'file_id': fileId,
        'expire_sec': expire.inSeconds,
      };

  @override
  DownloadUrl parse(json) => DownloadUrl.fromJson(json);
}

/// [文件创建](https://www.yuque.com/aliyundrive/zpfszx/ezlzok#Rptze)
class CreateFile extends Command<FileCreated> {
  const CreateFile({
    required this.driveId,
    this.parentFileId,
    required this.name,
    required this.type,
    this.checkNameMode = CheckNameMode.refuse,
    this.partInfoList,
    this.streamsInfo,
    this.preHash,
    this.size,
    this.contentHash,
    this.contentHashName,
    this.proofCode,
    this.proofVersion,
    this.localCreatedAt,
    this.localModifiedAt,
  });

  final String driveId;

  /// 父目录id，根目录为root
  final String? parentFileId;

  /// 文件名称，按照 utf8 编码最长 1024 字节，不能以 / 结尾
  final String name;
  final FileType type;
  final CheckNameMode checkNameMode;

  /// 最大分片数量 10000, 分片序列号，从 1 开始, 单个文件分片最大限制5GB，最小限制 100KB
  final List<PartInfo>? partInfoList;

  /// 仅上传livp格式的时候需要，常见场景不需要
  final StreamsInfo? streamsInfo;

  /// 针对大文件sha1计算非常耗时的情况， 可以先在读取文件的前1k的sha1， 如果前1k的sha1没有匹配的， 那么说明文件无法做秒传， 如果1ksha1有匹配再计算文件sha1进行秒传，这样有效边避免无效的sha1计算。
  final String? preHash;

  /// 秒传必须 文件大小，单位为 byte
  final int? size;

  /// 文件内容 hash 值，需要根据 content_hash_name 指定的算法计算，当前都是sha1算法
  final String? contentHash;

  /// 秒传必须, 默认都是 sha1
  final String? contentHashName;

  /// 秒传必须 [计算逻辑](https://www.yuque.com/aliyundrive/zpfszx/ezlzok#hwSW3)
  final String? proofCode;
  final String? proofVersion;

  /// 本地创建时间
  final DateTime? localCreatedAt;

  /// 本地修改时间
  final DateTime? localModifiedAt;

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  String get uri => '/adrive/v1.0/openFile/create';

  @override
  dynamic get data => {
        'drive_id': driveId,
        'parent_file_id': parentFileId ?? 'root',
        'name': name,
        'type': type.name,
        'check_name_mode': checkNameMode.name,
        'part_info_list': partInfoList?.map((e) => e.toJson()).toList(),
        'streams_info': streamsInfo?.toJson(),
        'pre_hash': preHash,
        'size': size,
        'content_hash': contentHash,
        'content_hash_name': contentHashName,
        'proof_code': proofCode,
        'proof_version': proofVersion,
        'local_created_at': localCreatedAt?.toIso8601String(),
        'local_modified_at': localModifiedAt?.toIso8601String(),
      };

  @override
  FileCreated parse(json) => FileCreated.fromJson(json);
}

/// [获取上传地址](https://www.yuque.com/aliyundrive/zpfszx/ezlzok#r0E90)
class GetUploadUrl extends Command<UploadUrl> {
  const GetUploadUrl({
    required this.driveId,
    required this.fileId,
    required this.uploadId,
    this.partInfoList,
  });

  final String driveId;
  final String fileId;

  /// 文件创建获取的upload_id
  final String uploadId;

  /// 分片信息列表
  final List<PartInfo>? partInfoList;

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  String get uri => '/adrive/v1.0/openFile/getUploadUrl';

  @override
  dynamic get data => {
        'drive_id': driveId,
        'file_id': fileId,
        'upload_id': uploadId,
        'part_info_list': partInfoList?.map((e) => e.toJson()).toList(),
      };

  @override
  UploadUrl parse(json) => UploadUrl.fromJson(json);
}

/// [获取已上传分片](https://www.yuque.com/aliyundrive/zpfszx/ezlzok#LGxhS)
class GetUploadedParts extends Command<UploadedParts> {
  const GetUploadedParts({
    required this.driveId,
    required this.fileId,
    required this.uploadId,
    this.partNumberMarker,
  });

  final String driveId;
  final String fileId;

  /// 文件创建获取的upload_id
  final String uploadId;
  final String? partNumberMarker;

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  String get uri => '/adrive/v1.0/openFile/listUploadedParts';

  @override
  dynamic get data => {
        'drive_id': driveId,
        'file_id': fileId,
        'upload_id': uploadId,
        'part_number_marker': partNumberMarker,
      };

  @override
  UploadedParts parse(json) => UploadedParts.fromJson(json);
}

/// [上传完毕](https://www.yuque.com/aliyundrive/zpfszx/ezlzok#PweKH)
class CompleteUpload extends Command<FileInfo> {
  const CompleteUpload({
    required this.driveId,
    required this.fileId,
    required this.uploadId,
  });

  final String driveId;
  final String fileId;
  final String uploadId;

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  String get uri => '/adrive/v1.0/openFile/complete';

  @override
  dynamic get data => {
        'drive_id': driveId,
        'file_id': fileId,
        'upload_id': uploadId,
      };

  @override
  FileInfo parse(json) => FileInfo.fromJson(json);
}

/// [文件更新](https://www.yuque.com/aliyundrive/zpfszx/dp9gn443hh8oksgd#xCOjJ)
class UpdateFile extends Command<FileInfo> {
  const UpdateFile({
    required this.driveId,
    required this.fileId,
    this.name,
    this.checkNameMode = CheckNameMode.refuse,
    this.starred,
  }) : assert(name != null || starred != null);

  final String driveId;
  final String fileId;
  final String? name;
  final CheckNameMode checkNameMode;
  final bool? starred;

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  String get uri => '/adrive/v1.0/openFile/update';

  @override
  dynamic get data => {
        'drive_id': driveId,
        'file_id': fileId,
        if (name != null) 'name': name,
        'check_name_mode': checkNameMode.name,
        if (starred != null) 'starred': starred,
      };

  @override
  FileInfo parse(json) => FileInfo.fromJson(json);
}

/// [移动文件或文件夹](https://www.yuque.com/aliyundrive/zpfszx/gzeh9ecpxihziqrc#xCOjJ)
class MoveFile extends Command<FileMoved> {
  const MoveFile({
    required this.driveId,
    required this.fileId,
    this.toParentFileId,
    this.checkNameMode = CheckNameMode.refuse,
    this.newName,
  });

  final String driveId;
  final String fileId;

  /// 父文件ID、根目录为 root
  final String? toParentFileId;
  final CheckNameMode checkNameMode;

  /// 当云端存在同名文件时，使用的新名字
  final String? newName;

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  String get uri => '/adrive/v1.0/openFile/move';

  @override
  dynamic get data => {
        'drive_id': driveId,
        'file_id': fileId,
        'to_parent_file_id': toParentFileId ?? 'root',
        'check_name_mode': checkNameMode.name,
        if (newName != null) 'new_name': newName,
      };

  @override
  FileMoved parse(json) => FileMoved.fromJson(json);
}

/// [复制文件或文件夹](https://www.yuque.com/aliyundrive/zpfszx/gzeh9ecpxihziqrc#eLg9A)
class CopyFile extends Command<FileCopied> {
  const CopyFile({
    required this.driveId,
    required this.fileId,
    this.toDriveId,
    this.toParentFileId,
    this.autoRename = false,
  });

  final String driveId;
  final String fileId;
  final String? toDriveId;

  /// 父文件ID、根目录为 root
  final String? toParentFileId;

  /// 当目标文件夹下存在同名文件时，是否自动重命名，默认为 false，默认允许同名文件
  final bool autoRename;

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  String get uri => '/adrive/v1.0/openFile/copy';

  @override
  dynamic get data => {
        'drive_id': driveId,
        'file_id': fileId,
        'to_drive_id': toDriveId,
        'to_parent_file_id': toParentFileId ?? 'root',
        'auto_rename': autoRename,
      };

  @override
  FileCopied parse(json) => FileCopied.fromJson(json);
}

/// [放入回收站](https://www.yuque.com/aliyundrive/zpfszx/get3mkr677pf10ws#xCOjJ)
class TrashFile extends Command<FileOperated> {
  const TrashFile({required this.driveId, required this.fileId});

  final String driveId;
  final String fileId;

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  String get uri => '/adrive/v1.0/openFile/recyclebin/trash';

  @override
  dynamic get data => {
        'drive_id': driveId,
        'file_id': fileId,
      };

  @override
  FileOperated parse(json) => FileOperated.fromJson(json);
}

/// [文件删除](https://www.yuque.com/aliyundrive/zpfszx/get3mkr677pf10ws#afKoC)
class DeleteFile extends Command<FileOperated> {
  const DeleteFile({required this.driveId, required this.fileId});

  final String driveId;
  final String fileId;

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  String get uri => '/adrive/v1.0/openFile/delete';

  @override
  dynamic get data => {
        'drive_id': driveId,
        'file_id': fileId,
      };

  @override
  FileOperated parse(json) => FileOperated.fromJson(json);
}

/// [获取异步任务状态](https://www.yuque.com/aliyundrive/zpfszx/get3mkr677pf10ws#InSGT)
class GetFileAsyncTaskState extends Command<OperateState> {
  const GetFileAsyncTaskState({required this.asyncTaskId});

  final String asyncTaskId;

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  String get uri => '/adrive/v1.0/openFile/async_task/get';

  @override
  dynamic get data => {
        'async_task_id': asyncTaskId,
      };

  @override
  OperateState parse(json) => OperateState.fromName(json['state']);
}
