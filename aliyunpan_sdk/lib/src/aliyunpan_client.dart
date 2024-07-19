import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:aliyunpan_api/aliyunpan_api.dart';
import 'package:anio/anio.dart' as anio;
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';

import '../aliyunpan_sdk.dart';
import 'utils.dart';

part 'download/download_task.dart';
part 'download/downloader.dart';
part 'upload/upload_task.dart';
part 'upload/uploader.dart';

const kAuthorizationHeaderKey = 'Authorization';

class AliyunpanClient implements ClientBase {
  AliyunpanClient(
    this.appId, {
    this.refreshTokenFunction,
    this.scopes = Scope.values,
    Dio? dio,
    bool debug = false,
    this.checkExpires = false,
    this.onTokenChange,
  }) : dio = dio ?? Dio(BaseOptions(receiveDataWhenStatusError: true)) {
    if (debug) {
      this.dio.interceptors.add(
            LogInterceptor(requestBody: true, responseBody: true),
          );
    }
    this.dio.interceptors.addAll([
      QueuedInterceptorsWrapper(
        onError: (error, handler) async {
          if (error.response == null) {
            return handler.next(error);
          }
          final refreshToken = _token?.refreshToken;
          if (error.response?.statusCode == 401 &&
              refreshToken != null &&
              refreshTokenFunction != null) {
            try {
              // update token
              updateToken(await refreshTokenFunction!(refreshToken));
              // Retry the request when 401 occurred
              error.requestOptions.headers[kAuthorizationHeaderKey] =
                  token.accessToken;
              final dio = Dio(BaseOptions(receiveDataWhenStatusError: true))
                ..interceptors.addAll([
                  if (debug)
                    LogInterceptor(requestBody: true, responseBody: true),
                ]);
              return handler.resolve(await dio.fetch(error.requestOptions));
            } catch (e) {
              if (e is DioException) {
                return handler.reject(e);
              } else {
                return handler.reject(error.copyWith(error: e));
              }
            }
          }
          return handler.next(error);
        },
      ),
    ]);
  }

  @override
  String get host => 'https://openapi.alipan.com';

  @override
  String appId;

  RefreshTokenFunction? refreshTokenFunction;

  @override
  List<Scope> scopes;

  final Dio dio;

  final bool checkExpires;

  final void Function(Token? token)? onTokenChange;

  bool _closed = false;

  Token? _token;

  Token get token {
    final token = _token;
    if (token == null) {
      throw const AuthorizeException(message: 'unauthorized');
    }
    if (checkExpires && token.expiresAt.isAfter(DateTime.now())) {
      throw const AuthorizeException(message: 'access token invalid');
    }
    return token;
  }

  set token(Token? value) {
    if (_token == value) return;
    _token = value;
  }

  void updateToken(Token? value) {
    if (_closed) throw StateError('closed');
    _token = value;
    onTokenChange?.call(value);
  }

  bool get authorized => _token != null;

  Future<void> authorize(
    Credentials credentials, {
    void Function(AuthorizeState state)? onStateChange,
    bool Function()? canceled,
  }) {
    if (_closed) throw StateError('closed');
    return credentials
        .authorize(this, onStateChange ?? (state) {}, canceled ?? () => false)
        .then((e) => updateToken(e));
  }

  @override
  Future<T> send<T>(Command<T> command) {
    if (_closed) throw StateError('closed');
    final headers = <String, dynamic>{};
    if (command.authorized) {
      headers[kAuthorizationHeaderKey] = 'Bearer ${token.accessToken}';
    }
    return dio.send('$host${command.uri}',
        Options(method: command.method.name, headers: headers), command);
  }

  late final _uploader = Uploader(this);

  Uploader get uploader => _uploader;

  late final _downloader = Downloader(this);

  Downloader get downloader => _downloader;

  Future close() async {
    if (_closed) return;
    _closed = true;
    dio.close(force: true);
    await _uploader.close();
    await _downloader.close();
  }
}

extension DioExtension on Dio {
  Future<T> send<T>(String url, Options options, Command<T> command) {
    return request<Map<String, dynamic>>(url,
            data: command.data, options: options)
        .then((e) => command.parse(e.data))
        .onError<DioException>((error, stackTrace) => () async {
              final data = error.response?.data;
              if (data == null || data is! Map<String, dynamic>) {
                Error.throwWithStackTrace(error, stackTrace);
              }
              final code = data['code'];
              if (code == null) {
                Error.throwWithStackTrace(error, stackTrace);
              } else {
                if (code == 'AlreadyExist.File') {
                  throw FileAlreadyExistsException(message: data['message']);
                } else {
                  throw ApiException(code: '$code', message: data['message']);
                }
              }
            }());
  }
}

const kOneSecond = Duration(seconds: 1);

sealed class Task implements Comparable<Task> {
  Task(
    this.path, {
    this.priority = 5,
    this.retries = 3,
    DateTime? createTime,
  })  : createTime = createTime ?? DateTime.now(),
        _retriesRemaining = retries;

  Task.fromJson(Map<String, dynamic> json)
      : path = json['path'],
        priority = json['priority'],
        retries = json['retries'],
        _retriesRemaining = json['retries'],
        createTime = DateTime.parse(json['createTime']);

  final String path;

  /// Priority of this task, relative to other tasks.
  /// Range 0 <= priority <= 10 with 0 being the highest priority.
  /// Not all platforms will have the same actual granularity, and how
  /// priority is considered is inconsistent across platforms.
  final int priority;

  /// Maximum number of retries the downloader should attempt
  ///
  /// Defaults to 0, meaning no retry will be attempted
  final int retries;

  /// Number of retries remaining
  int _retriesRemaining;

  /// Time at which this request was first created
  final DateTime createTime;

  @override
  int compareTo(Task other) {
    final diff = priority - other.priority;
    if (diff != 0) {
      return diff;
    }
    final retryTimes = retries - _retriesRemaining;
    final otherRetryTimes = other.retries - other._retriesRemaining;
    final retryTimesDiff = otherRetryTimes - retryTimes;
    if (retryTimesDiff != 0) {
      return retryTimesDiff;
    }
    return createTime.compareTo(other.createTime);
  }

  Map<String, dynamic> toJson() => {
        'path': path,
        'priority': priority,
        'retries': retries,
        'createTime': createTime.toString(),
      };
}

/// Defines a set of possible states which a [Task] can be in.
enum TaskStatus {
  /// Task is enqueued on the native platform and waiting to start
  ///
  /// It may wait for resources, or for an appropriate network to become
  /// available before starting the actual download and changing state to
  /// `running`.
  enqueued,

  /// Task is running, i.e. actively downloading
  running,

  /// Task has completed successfully
  ///
  /// This is a final state
  complete,

  /// Task has failed due to an exception
  ///
  /// This is a final state
  failed,

  /// Task has been canceled by the user or the system
  ///
  /// This is a final state
  canceled,

  /// Task failed, and is now waiting to retry
  ///
  /// The task is held in this state until the exponential backoff time for
  /// this retry has passed, and will then be rescheduled on the native
  /// platform, switching state to `enqueued` and then `running`
  waitingToRetry;

  /// True if this state is one of the 'final' states, meaning no more
  /// state changes are possible
  bool get isFinalState {
    switch (this) {
      case TaskStatus.complete:
      case TaskStatus.failed:
      case TaskStatus.canceled:
        return true;

      case TaskStatus.enqueued:
      case TaskStatus.running:
      case TaskStatus.waitingToRetry:
        return false;
    }
  }

  /// True if this state is not a 'final' state, meaning more
  /// state changes are possible
  bool get isNotFinalState => !isFinalState;
}

sealed class TaskUpdate<T extends Task> {
  final T task;

  const TaskUpdate(this.task);
}

abstract mixin class TaskProgress {
  double? get progress;

  double? get networkSpeed; // in B/ms

  Duration? get timeRemaining;
}

class TaskException implements Exception {
  const TaskException();
}

class TaskCancelledException extends TaskException {
  const TaskCancelledException();
}
