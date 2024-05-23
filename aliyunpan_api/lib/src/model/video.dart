import 'file.dart';

class VideoInfo {
  final String domainId;
  final String driveId;
  final String fileId;
  final VideoPreviewPlayInfo videoPreviewPlayInfo;

  /// 播放进度，例子 "5722.376"
  final Duration? playCursor;

  const VideoInfo({
    required this.domainId,
    required this.driveId,
    required this.fileId,
    required this.videoPreviewPlayInfo,
    this.playCursor,
  });

  factory VideoInfo.fromJson(Map<String, dynamic> json) => VideoInfo(
        domainId: json['domain_id'],
        driveId: json['drive_id'],
        fileId: json['file_id'],
        videoPreviewPlayInfo:
            VideoPreviewPlayInfo.fromJson(json['video_preview_play_info']),
        playCursor: json['play_cursor'] == null
            ? null
            : Duration(
                milliseconds:
                    (double.parse(json['play_cursor']) * 1000).toInt(),
              ),
      );

  Map<String, dynamic> toJson() => {
        'domain_id': domainId,
        'drive_id': driveId,
        'file_id': fileId,
        'video_preview_play_info': videoPreviewPlayInfo.toJson(),
        'play_cursor':
            playCursor == null ? null : playCursor!.inMilliseconds / 1000,
      };
}

class VideoPreviewPlayInfo {
  final String category;
  final List<LiveTranscodingTask> liveTranscodingTaskList;
  final List<LiveTranscodingSubtitleTask>? liveTranscodingSubtitleTaskList;

  const VideoPreviewPlayInfo({
    required this.category,
    required this.liveTranscodingTaskList,
    this.liveTranscodingSubtitleTaskList,
  });

  factory VideoPreviewPlayInfo.fromJson(Map<String, dynamic> json) =>
      VideoPreviewPlayInfo(
        category: json['category'],
        liveTranscodingTaskList: (json['live_transcoding_task_list'] as List)
            .map((e) => LiveTranscodingTask.fromJson(e))
            .toList(),
        liveTranscodingSubtitleTaskList:
            (json['live_transcoding_subtitle_task_list'] as List?)
                ?.map((e) => LiveTranscodingSubtitleTask.fromJson(e))
                .toList(),
      );

  Map<String, dynamic> toJson() => {
        'category': category,
        'live_transcoding_task_list':
            liveTranscodingTaskList.map((e) => e.toJson()).toList(),
        'live_transcoding_subtitle_task_list':
            liveTranscodingSubtitleTaskList?.map((e) => e.toJson()).toList(),
      };
}

class LiveTranscodingTask {
  final VideoTemplate templateId;
  final String? templateName;
  final int? templateWidth;
  final int? templateHeight;
  final bool? keepOriginalResolution;
  final String? stage;
  final VideoTranscodingStatus status;
  final String? url;

  const LiveTranscodingTask({
    required this.templateId,
    this.templateName,
    this.templateWidth,
    this.templateHeight,
    this.keepOriginalResolution,
    this.stage,
    required this.status,
    this.url,
  });

  factory LiveTranscodingTask.fromJson(Map<String, dynamic> json) =>
      LiveTranscodingTask(
        templateId: VideoTemplate.fromName(json['template_id']),
        templateName: json['template_name'],
        templateWidth: json['template_width'],
        templateHeight: json['template_height'],
        keepOriginalResolution: json['keep_original_resolution'],
        stage: json['stage'],
        status: VideoTranscodingStatus.fromName(json['status']),
        url: json['url'],
      );

  Map<String, dynamic> toJson() => {
        'template_id': templateId.name,
        'template_name': templateName,
        'template_width': templateWidth,
        'template_height': templateHeight,
        'keep_original_resolution': keepOriginalResolution,
        'stage': stage,
        'status': status.name,
        'url': url,
      };
}

class LiveTranscodingSubtitleTask {
  final String language;
  final VideoTranscodingStatus status;
  final String? url;

  const LiveTranscodingSubtitleTask({
    required this.language,
    required this.status,
    this.url,
  });

  factory LiveTranscodingSubtitleTask.fromJson(Map<String, dynamic> json) =>
      LiveTranscodingSubtitleTask(
        language: json['language'],
        status: VideoTranscodingStatus.fromName(json['status']),
        url: json['url'],
      );

  Map<String, dynamic> toJson() => {
        'language': language,
        'status': status.name,
        'url': url,
      };
}

class UpdateVideoRecordResult {
  final String domainId;
  final String driveId;
  final String fileId;
  final String name;

  const UpdateVideoRecordResult({
    required this.domainId,
    required this.driveId,
    required this.fileId,
    required this.name,
  });

  factory UpdateVideoRecordResult.fromJson(Map<String, dynamic> json) =>
      UpdateVideoRecordResult(
        domainId: json['domain_id'],
        driveId: json['drive_id'],
        fileId: json['file_id'],
        name: json['name'],
      );

  Map<String, dynamic> toJson() => {
        'domain_id': domainId,
        'drive_id': driveId,
        'file_id': fileId,
        'name': name,
      };
}
