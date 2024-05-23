class AliyunpanException implements Exception {
  final String? message;

  const AliyunpanException({this.message});

  @override
  String toString() => '$runtimeType: $message';
}

/// 接口错误
class ApiException extends AliyunpanException {
  const ApiException({required this.code, super.message});

  final String code;
}

/// 授权错误
class AuthorizeException extends AliyunpanException {
  const AuthorizeException({super.message});
}

/// 获取 auth code 错误
class AuthcodeException extends AuthorizeException {
  const AuthcodeException({super.message});
}

/// 文件错误
class FileException extends AliyunpanException {
  const FileException({super.message});
}

/// 文件已存在
class FileAlreadyExistsException extends FileException {
  const FileAlreadyExistsException({super.message});
}
