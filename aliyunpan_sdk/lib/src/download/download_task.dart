part of '../aliyunpan_client.dart';

class DownloadChunk {
  DownloadChunk(this.start, this.end, {int count = 0}) : _count = count;

  factory DownloadChunk.fromJson(Map<String, dynamic> json) => DownloadChunk(
        json['start'],
        json['end'],
        count: json['count'],
      );

  /// 文件开始位置
  final int start;

  /// 文件结束位置
  final int? end;

  /// 下载进度
  int _count;

  String get rangeHeaderValue => 'bytes=${start + _count}-${end! - 1}';

  bool get isCompleted => end == null ? false : end! - start == _count;

  Map<String, dynamic> toJson() => {
        'start': start,
        'end': end,
        'count': _count,
      };
}

class DownloadTask extends Task {
  DownloadTask(
    super.path,
    this.driveId,
    this.fileId, {
    super.priority,
    super.retries,
    super.createTime,
    this.expire = const Duration(seconds: 900),
    this.chunkSize = 16 * 1024 * 1024,
    int maxConcurrent = 10,
  })  : assert(0 < maxConcurrent && maxConcurrent <= 10),
        _maxConcurrent = maxConcurrent;

  DownloadTask.fromJson(super.json)
      : driveId = json['driveId'],
        fileId = json['fileId'],
        expire = Duration(milliseconds: json['expire']),
        chunkSize = json['chunkSize'],
        _maxConcurrent = json['maxConcurrent'],
        _url = json['url'] == null ? null : DownloadUrl.fromJson(json['url']),
        _ranges = json['ranges'],
        _length = json['length'],
        _chunks = (json['chunks'] as List?)?.map((e) {
          return DownloadChunk.fromJson(e);
        }).toList(),
        super.fromJson();

  final String driveId;
  final String fileId;
  final Duration expire;
  final int chunkSize;
  int _maxConcurrent;
  DownloadUrl? _url;
  bool? _ranges;
  int? _length;
  List<DownloadChunk>? _chunks;

  bool get resume => _url != null && _ranges != null && _chunks != null;

  int get downloadedCount {
    return _chunks?.map((e) => e._count).reduce((v, e) => v + e) ?? 0;
  }

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'driveId': driveId,
        'fileId': fileId,
        'expire': expire.inMilliseconds,
        'chunkSize': chunkSize,
        'maxConcurrent': _maxConcurrent,
        'url': _url?.toJson(),
        'ranges': _ranges,
        'length': _length,
        'chunks': _chunks?.map((e) => e.toJson()).toList(),
      };

  _DownloadTaskRunner? _runner;

  Future<void> start(
    AliyunpanClient client,
    void Function(DownloadTaskProgressUpdate update) onUpdate,
  ) {
    return (_runner = _DownloadTaskRunner(client, onUpdate, this))
        .start()
        .whenComplete(() => _runner = null);
  }

  void cancel() => _runner?.cancel();
}

class _DownloadTaskRunner {
  _DownloadTaskRunner(this.client, this.onUpdate, this.task) {
    _dio.interceptors.add(QueuedInterceptorsWrapper(
      onError: (error, handler) async {
        if (error.response?.statusCode != 403) {
          return handler.next(error);
        }
        try {
          final url = await _updateUrl();
          final options = error.requestOptions.copyWith(path: url);
          return handler.resolve(await Dio().fetch(options));
        } catch (e) {
          if (e is DioException) {
            return handler.reject(e);
          } else {
            return handler.reject(error.copyWith(error: e));
          }
        }
      },
    ));
  }

  final AliyunpanClient client;
  final void Function(DownloadTaskProgressUpdate update) onUpdate;
  final DownloadTask task;
  final _dio = Dio();

  late final anio.FileHandle _fileHandle;
  late final Completer _completer;
  late int _lastProgressUpdateCount;
  late DateTime _lastProgressUpdateTime;
  final _speeds = <double>[];

  var _started = false;
  var _cancelled = false;

  void cancel() => _cancelled = true;

  final _queue = PriorityQueue<DownloadChunk>((p0, p1) {
    return p0.start.compareTo(p1.start);
  });

  // subset that is running
  final _running = Queue<DownloadChunk>();

  set maxConcurrent(int value) {
    task._maxConcurrent = value;
    _advanceQueue();
  }

  /// Advance the queue if it's not empty and there is room in the run queue
  void _advanceQueue() {
    if (!_started) return;

    if (_queue.isEmpty && _running.isEmpty) {
      if (!_completer.isCompleted) _completer.complete();
      return;
    }

    while (_running.length < task._maxConcurrent && _queue.isNotEmpty) {
      final chunk = _getNextChunk();
      if (chunk != null) {
        _running.add(chunk);
        _downloadChunk(chunk).then((_) {
          _running.remove(chunk);
          _advanceQueue();
        }).catchError((e, s) {
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

  /// Returns a [DownloadChunk] to run, or null if no suitable task is available
  DownloadChunk? _getNextChunk() {
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

    final length = task._length;
    final downloadedCount = task.downloadedCount;
    _lastProgressUpdateTime = now;
    final progress = length == null ? null : downloadedCount / length;

    final bytesSinceLastUpdate = downloadedCount - _lastProgressUpdateCount;
    _lastProgressUpdateCount = downloadedCount;
    _speeds.add(bytesSinceLastUpdate / timeSinceLastUpdateMicroseconds * 1000);
    if (_speeds.length > 5) _speeds.removeAt(0);
    final networkSpeed = _speeds.average;

    final remainingCount = length == null ? null : length - downloadedCount;
    final timeRemaining = networkSpeed <= 0 || remainingCount == null
        ? null
        : Duration(milliseconds: (remainingCount / networkSpeed).round());

    onUpdate(DownloadTaskProgressUpdate(
      task,
      progress: progress,
      networkSpeed: _speeds.average,
      timeRemaining: timeRemaining,
    ));
  }

  Future<void> start() async {
    final List<DownloadChunk> chunks;
    if (!task.resume) {
      if (task._ranges == null) await _preDownload();
      // 分块
      final length = task._length;
      if (task._ranges! && length != null) {
        final number = (length / task.chunkSize).ceil();
        chunks = task._chunks = List.generate(number, (i) {
          final int start = i * task.chunkSize;
          final int end = (i == number - 1) ? length : (start + task.chunkSize);
          return DownloadChunk(start, end);
        });
      } else {
        chunks = task._chunks = [DownloadChunk(0, null)];
      }
    } else {
      chunks = task._chunks!;
    }
    // 开始下载
    _started = true;
    _fileHandle = await File(task.path).openHandle(mode: FileMode.append);
    _completer = Completer();
    _lastProgressUpdateCount = task.downloadedCount;
    _lastProgressUpdateTime = DateTime.now();
    final networkSpeedTimer = Timer.periodic(kOneSecond, (timer) {
      _updateProgress();
    });
    _queue.addAll(chunks.where((e) => !e.isCompleted));
    _advanceQueue();
    return _completer.future.whenComplete(() {
      networkSpeedTimer.cancel();
      _fileHandle.close();
      _dio.close(force: true);
    });
  }

  Future<void> _downloadChunk(DownloadChunk chunk) async {
    if (_cancelled) throw const TaskCancelledException();
    final url = task._url!.url;
    final method = task._url!.method;
    final response = await _dio.request<ResponseBody>(url,
        options: Options(
            method: method,
            responseType: ResponseType.stream,
            headers: {
              if (task._ranges!)
                HttpHeaders.rangeHeader: chunk.rangeHeaderValue,
            }));
    final stream = response.data!.stream;
    final sink = _fileHandle.sink(chunk.start + chunk._count).buffered();
    final completer = Completer<void>();
    StreamSubscription? subscription;
    subscription = stream.listen(
      (data) async {
        if (_completer.isCompleted) {
          if (!completer.isCompleted) {
            completer.completeError(
                StateError('completed'), StackTrace.current);
          }
          return;
        }
        if (_cancelled) {
          if (!completer.isCompleted) {
            completer.completeError(
                const TaskCancelledException(), StackTrace.current);
          }
          return;
        }
        subscription?.pause();
        await sink.writeFromBytes(data);
        chunk._count += data.length;
        _updateProgress();
        subscription?.resume();
      },
      cancelOnError: true,
      onError: (e, s) {
        if (!completer.isCompleted) completer.completeError(e, s);
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete();
      },
    );
    return completer.future.whenComplete(() {
      sink.close();
      subscription?.cancel();
      _updateProgress(true);
    });
  }

  Future<String> _updateUrl() async {
    task._url = await client.send(
      GetDownloadUrl(driveId: task.driveId, fileId: task.fileId),
    );
    return task._url!.url;
  }

  Future<void> _preDownload() async {
    final url = task._url?.url ?? await _updateUrl();
    final response = await _dio.request(url,
        options: Options(
          responseType: ResponseType.stream,
          method: task._url!.method,
        ));
    final acceptRangesHeader =
        response.headers.value(HttpHeaders.acceptRangesHeader);
    final lengthHeader =
        response.headers.value(HttpHeaders.contentLengthHeader);
    final length = lengthHeader == null ? null : int.tryParse(lengthHeader);
    final canRanges =
        acceptRangesHeader == 'bytes' || response.statusCode == 206;
    task._ranges = canRanges && length != null;
    task._length = length;
  }
}
