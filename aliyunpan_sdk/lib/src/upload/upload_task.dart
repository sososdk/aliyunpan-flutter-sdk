part of '../aliyunpan_client.dart';

class UploadTask extends Task {
  UploadTask(
    super.path,
    this.driveId,
    this.name, {
    super.priority,
    super.retries,
    super.createTime,
    this.length,
    this.parentFileId,
    this.useProof = true,
    this.checkNameMode = CheckNameMode.refuse,
    this.chunkSize = 16 * 1024 * 1024,
    int maxConcurrent = 1,
  })  : assert(100 * 1024 <= chunkSize && chunkSize <= 5 * 1024 * 1024 * 1024),
        _maxConcurrent = maxConcurrent,
        assert(maxConcurrent == 1, 'concurrent uploads are not supported');

  UploadTask.fromJson(super.json)
      : driveId = json['driveId'],
        name = json['name'],
        length = json['length'],
        parentFileId = json['parentFileId'],
        useProof = json['useProof'],
        checkNameMode = CheckNameMode.fromName(json['checkNameMode']),
        chunkSize = json['chunkSize'],
        _maxConcurrent = json['maxConcurrent'],
        _fileId = json['fileId'],
        _uploadId = json['uploadId'],
        _parts = (json['parts'] as List?)?.map((e) {
          return PartInfo.fromJson(e);
        }).toList(),
        super.fromJson();

  final String driveId;
  final String? parentFileId;
  final String name;
  final int? length;
  final bool useProof;
  final CheckNameMode checkNameMode;
  final int chunkSize;
  int _maxConcurrent;
  String? _fileId;
  String? _uploadId;
  List<PartInfo>? _parts;

  bool get resume => _fileId != null && _uploadId != null && _parts != null;

  int _uploadedCount = 0;

  int get uploadedCount => _uploadedCount;

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'driveId': driveId,
        'parentFileId': parentFileId,
        'name': name,
        'length': length,
        'useProof': useProof,
        'checkNameMode': checkNameMode.name,
        'chunkSize': chunkSize,
        'maxConcurrent': _maxConcurrent,
        'fileId': _fileId,
        'uploadId': _uploadId,
        'parts': _parts?.map((e) => e.toJson()).toList(),
      };

  _UploadTaskRunner? _runner;

  Future<FileInfo> start(
    AliyunpanClient client,
    void Function(UploadTaskProgressUpdate update) onUpdate,
  ) {
    return (_runner = _UploadTaskRunner(client, onUpdate, this))
        .start()
        .whenComplete(() => _runner = null);
  }

  void cancel() => _runner?.cancel();
}

class _UploadTaskRunner {
  _UploadTaskRunner(this.client, this.onUpdate, this.task);

  final AliyunpanClient client;
  final void Function(UploadTaskProgressUpdate update) onUpdate;
  final UploadTask task;

  late final File _file;
  late final Completer<FileInfo> _completer;
  late int _lastProgressUpdateCount;
  late DateTime _lastProgressUpdateTime;
  final _speeds = <double>[];

  var _started = false;
  var _cancelled = false;

  void cancel() => _cancelled = true;

  final _queue = PriorityQueue<PartInfo>((p0, p1) {
    return p0.partNumber.compareTo(p1.partNumber);
  });

  // subset that is running
  final _running = Queue<PartInfo>();

  set maxConcurrent(int value) {
    task._maxConcurrent = value;
    _advanceQueue();
  }

  /// Advance the queue if it's not empty and there is room in the run queue
  void _advanceQueue() {
    if (!_started) return;

    if (_queue.isEmpty && _running.isEmpty) {
      if (!_completer.isCompleted) {
        _completer.complete(client.send(CompleteUpload(
            driveId: task.driveId,
            fileId: task._fileId!,
            uploadId: task._uploadId!)));
        return;
      }
    }

    while (_running.length < task._maxConcurrent && _queue.isNotEmpty) {
      final chunk = _getNextChunk();
      if (chunk != null) {
        _running.add(chunk);
        _uploadChunk(chunk).then((_) {
          _running.remove(chunk);
          _advanceQueue();
        }).catchError((e, s) {
          e = e is DioException && e.error is TaskCancelledException
              ? e.error
              : e;
          if (!_completer.isCompleted) _completer.completeError(e, s);
        });
      } else {
        break; // if no suitable task, done
      }
    }
    while (_running.length > task._maxConcurrent && _running.isNotEmpty) {
      _queue.add(_running.removeLast());
    }
  }

  /// Returns a [PartInfo] to run, or null if no suitable task is available
  PartInfo? _getNextChunk() {
    if (_queue.isNotEmpty) {
      return _queue.removeFirst();
    }
    return null;
  }

  void _updateProgress([bool force = false]) {
    final now = DateTime.now();
    final timeSinceLastUpdate = now.difference(_lastProgressUpdateTime);
    final timeSinceLastUpdateMicroseconds = timeSinceLastUpdate.inMicroseconds;
    if (timeSinceLastUpdateMicroseconds == 0) return;
    if (timeSinceLastUpdate < kOneSecond && !force) return;

    final length = task.length;
    final uploadedCount = task.uploadedCount;
    _lastProgressUpdateTime = now;
    final progress = length == null ? null : uploadedCount / length;

    final bytesSinceLastUpdate = uploadedCount - _lastProgressUpdateCount;
    _lastProgressUpdateCount = uploadedCount;
    _speeds.add(bytesSinceLastUpdate / timeSinceLastUpdateMicroseconds * 1000);
    if (_speeds.length > 5) _speeds.removeAt(0);
    final networkSpeed = _speeds.average;

    final remainingCount = length == null ? null : length - uploadedCount;
    final timeRemaining = networkSpeed <= 0 || remainingCount == null
        ? null
        : Duration(milliseconds: (remainingCount / networkSpeed).round());

    onUpdate(UploadTaskProgressUpdate(
      task,
      UploadStatus.upload,
      progress: progress,
      networkSpeed: _speeds.average,
      timeRemaining: timeRemaining,
    ));
  }

  Future<FileInfo> start() async {
    final chunkSize = task.chunkSize;
    final length = task.length;
    List<PartInfo>? uploadedParts;
    if (!task.resume) {
      if (task.useProof && length != null) {
        // 秒传
        final fileInfo = await _proofUpload();
        if (fileInfo != null) return fileInfo;
      }
      if (_cancelled) throw const TaskCancelledException();
      // 秒传失败, 开始正常上传
      onUpdate(UploadTaskProgressUpdate(task, UploadStatus.upload));
      final created = await client.send(CreateFile(
        driveId: task.driveId,
        parentFileId: task.parentFileId,
        checkNameMode: task.checkNameMode,
        name: task.name,
        type: FileType.file,
        size: length,
        partInfoList: length == null
            ? null
            : List.generate((length / chunkSize).ceil(), (index) {
                final int offset = index * chunkSize;
                final int partSize = (length - offset) < chunkSize
                    ? (length - offset)
                    : chunkSize;
                return PartInfo(partNumber: index + 1, partSize: partSize);
              }),
      ));
      if (created.exist == true) throw const FileAlreadyExistsException();
      task._fileId = created.fileId;
      task._uploadId = created.uploadId;
      task._parts = created.partInfoList;
    } else {
      uploadedParts = await _getUploadParts();
    }
    if (_cancelled) throw const TaskCancelledException();
    // 剔除已上传的分片. FIXME: 目前只能查到已上传的分片. 部分上传的分片只能重新上传, 有办法断点续传吗?
    final uploadedPartSizes = uploadedParts?.map((e) => e.partSize!) ?? [];
    task._uploadedCount = uploadedPartSizes.isEmpty
        ? 0
        : uploadedPartSizes.reduce((v, e) => v + e);
    final uploadParts = uploadedParts == null || uploadedParts.isEmpty
        ? task._parts!
        : task._parts!.where((e0) => !uploadedParts!.any((e1) {
              return e0.partNumber == e1.partNumber;
            }));
    // 开始上传
    _started = true;
    _file = File(task.path);
    _completer = Completer<FileInfo>();
    _lastProgressUpdateCount = task.uploadedCount;
    _lastProgressUpdateTime = DateTime.now();
    final networkSpeedTimer = Timer.periodic(kOneSecond, (timer) {
      _updateProgress();
    });
    _queue.addAll(uploadParts);
    _advanceQueue();
    return _completer.future.whenComplete(() {
      networkSpeedTimer.cancel();
    });
  }

  Future<void> _uploadChunk(PartInfo part) {
    if (_cancelled) throw const TaskCancelledException();
    final partSize = part.partSize;
    final partUrl = part.uploadUrl;
    if (partUrl == null) return Future.value();
    final chunkStart = (part.partNumber - 1) * task.chunkSize;
    final start = chunkStart;
    final end = partSize == null ? null : chunkStart + partSize;
    var preCount = 0;
    return client.dio
        .put(partUrl,
            data: _file.openRead(start, end),
            onSendProgress: (count, total) => () {
                  if (_completer.isCompleted) throw StateError('completed');
                  if (_cancelled) throw const TaskCancelledException();
                  task._uploadedCount += count - preCount;
                  preCount = count;
                  _updateProgress();
                }(),
            options: Options(headers: {
              if (end != null) Headers.contentLengthHeader: end - start,
              Headers.contentTypeHeader: '' // 不能传 Content-Type，否则会失败
            }))
        .whenComplete(() => _updateProgress(true));
  }

  Future<List<PartInfo>> _getUploadParts() async {
    final parts = <PartInfo>[];
    final uploadedParts = await client.send(GetUploadedParts(
      driveId: task.driveId,
      fileId: task._fileId!,
      uploadId: task._uploadId!,
    ));
    parts.addAll(uploadedParts.uploadedParts);
    var marker = uploadedParts.nextPartNumberMarker;
    while (marker != null && marker.isNotEmpty) {
      final uploadedParts = await client.send(GetUploadedParts(
        driveId: task.driveId,
        fileId: task._fileId!,
        uploadId: task._uploadId!,
      ));
      parts.addAll(uploadedParts.uploadedParts);
      marker = uploadedParts.nextPartNumberMarker;
    }
    return parts;
  }

  Future<FileInfo?> _proofUpload() async {
    final length = task.length!;
    // 大于 10M 的文件先预校验
    final bool isPreHashMatched;
    if (length > 10 * 1024 * 1024) {
      onUpdate(UploadTaskProgressUpdate(task, UploadStatus.preProof));
      isPreHashMatched = await _proofCheckPreHashMatched();
    } else {
      isPreHashMatched = true;
    }
    if (!isPreHashMatched) return null;
    if (_cancelled) throw const TaskCancelledException();
    onUpdate(UploadTaskProgressUpdate(task, UploadStatus.proof));
    final contentHash = await (File(task.path).openRead()).sha1;
    final proofCode = await getProofCode(
        client.token.accessToken, length, File(task.path).openRead);
    final created = await client.send(CreateFile(
      driveId: task.driveId,
      parentFileId: task.parentFileId,
      checkNameMode: task.checkNameMode,
      name: task.name,
      type: FileType.file,
      size: length,
      contentHash: contentHash,
      contentHashName: 'sha1',
      proofCode: proofCode,
      proofVersion: 'v1',
    ));
    if (created.exist == true) throw const FileAlreadyExistsException();
    if (created.rapidUpload ?? false) {
      /* 秒传成功 */
      return client.send(CompleteUpload(
          driveId: task.driveId,
          fileId: created.fileId,
          uploadId: created.uploadId!));
    } else {
      return null;
    }
  }

  Future<bool> _proofCheckPreHashMatched() async {
    final preData = await (File(task.path).openRead()).read(1024);
    final preHash = preData.sha1;
    try {
      await client.send(CreateFile(
          driveId: task.driveId,
          parentFileId: task.parentFileId,
          name: task.name,
          size: task.length,
          type: FileType.file,
          preHash: preHash));
      return false;
    } on ApiException catch (e) {
      if (e.code == 'PreHashMatched') return true;
      rethrow;
    }
  }
}
