part of '../aliyunpan_client.dart';

class Uploader {
  Uploader(
    this.client, {
    int maxConcurrent = 3,
  }) : _maxConcurrent = maxConcurrent {
    if (_maxConcurrent <= 0) {
      throw ArgumentError.value(
          _maxConcurrent, 'maxConcurrent', 'Must be greater than zero.');
    }
  }

  final AliyunpanClient client;

  bool _closed = false;

  int _maxConcurrent;

  set maxConcurrent(int value) {
    if (_closed) throw StateError('closed');
    if (value <= 0) {
      throw ArgumentError.value(
          value, 'maxConcurrent', 'Must be greater than zero.');
    }
    if (value == _maxConcurrent) return;
    _maxConcurrent = value;
    _advanceQueue();
  }

  final _updatesController = StreamController<UploadTaskUpdate>.broadcast();

  Stream<UploadTaskUpdate> get updates => _updatesController.stream;

  final _queue = PriorityQueue<UploadTask>();

  // subset that is running
  final _running = Queue<UploadTask>();

  /// Advance the queue if it's not empty and there is room in the run queue
  void _advanceQueue() {
    while (_running.length < _maxConcurrent && _queue.isNotEmpty) {
      final task = _getNextTask();
      if (task != null) {
        _running.add(task);
        _executeTask(task).whenComplete(() => _advanceQueue());
      } else {
        break; // if no suitable task, done
      }
    }
    while (_running.length > _maxConcurrent && _running.isNotEmpty) {
      _queue.add(_running.removeLast()..cancel());
    }
  }

  /// Returns a [UploadTask] to run, or null if no suitable task is available
  UploadTask? _getNextTask() {
    final tasksThatHaveToWait = <UploadTask>[];
    while (_queue.isNotEmpty) {
      final task = _queue.removeFirst();
      if (true /* task canRun */) {
        _queue.addAll(tasksThatHaveToWait); // put back in queue
        return task;
      }
      // ignore: dead_code
      tasksThatHaveToWait.add(task);
    }
    _queue.addAll(tasksThatHaveToWait); // put back in queue
    return null;
  }

  Future<bool> enqueue(UploadTask task) async {
    if (_closed) throw StateError('closed');
    if (_queue.contains(task) || _running.contains(task)) return false;

    _queue.add(task.._retriesRemaining = task.retries);
    _updatesController.add(UploadTaskStatusUpdate(task, TaskStatus.enqueued));

    _advanceQueue();
    return true;
  }

  Future<bool> cancel(UploadTask task) async {
    if (_closed) throw StateError('closed');
    if (_queue.contains(task)) {
      _queue.remove(task);
      _updatesController.add(UploadTaskStatusUpdate(task, TaskStatus.canceled));
      return true;
    } else if (_running.contains(task)) {
      task.cancel();
      return true;
    }
    return false;
  }

  Future<void> _executeTask(UploadTask task) async {
    try {
      _updatesController.add(UploadTaskStatusUpdate(task, TaskStatus.running));
      final file = await task.start(client, (update) {
        _updatesController.add(update);
      });
      _running.remove(task);
      _updatesController.add(
        UploadTaskStatusUpdate(task, TaskStatus.complete, result: file),
      );
    } catch (e) {
      if (e is TaskCancelledException) {
        if (_running.contains(task)) {
          // 取消
          _running.remove(task);
          _updatesController.add(
            UploadTaskStatusUpdate(task, TaskStatus.canceled),
          );
        } else {
          // 并发减少, 将运行中的任务放回队列
          _queue.add(task);
          _updatesController.add(
            UploadTaskStatusUpdate(task, TaskStatus.enqueued),
          );
        }
      } else if (task._retriesRemaining > 0) {
        // 其他异常, 重试
        task._retriesRemaining--;
        _running.remove(task);
        _queue.add(task);
        _updatesController.add(
          UploadTaskStatusUpdate(task, TaskStatus.waitingToRetry),
        );
      } else {
        // 失败
        _running.remove(task);
        _updatesController.add(UploadTaskStatusUpdate(task, TaskStatus.failed));
      }
    }
  }

  Future close() async {
    if (_closed) return;
    _closed = true;
    while (_running.isNotEmpty) {
      _running.removeLast().cancel();
    }
    await _updatesController.close();
  }
}

enum UploadStatus { preProof, proof, upload }

sealed class UploadTaskUpdate extends TaskUpdate<UploadTask> {
  const UploadTaskUpdate(super.task);
}

class UploadTaskStatusUpdate extends UploadTaskUpdate {
  const UploadTaskStatusUpdate(
    super.task,
    this.status, {
    this.exception,
    this.result,
  });

  final TaskStatus status;
  final Object? exception;
  final FileInfo? result;
}

class UploadTaskProgressUpdate extends UploadTaskUpdate with TaskProgress {
  const UploadTaskProgressUpdate(
    super.task,
    this.status, {
    this.progress,
    this.networkSpeed,
    this.timeRemaining,
  });

  final UploadStatus status;
  @override
  final double? progress;
  @override
  final double? networkSpeed;
  @override
  final Duration? timeRemaining;
}
