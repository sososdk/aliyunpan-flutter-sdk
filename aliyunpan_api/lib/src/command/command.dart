enum HttpMethod {
  get,
  post;

  String get name => switch (this) {
        HttpMethod.get => 'GET',
        HttpMethod.post => 'POST',
      };
}

abstract class Command<T> {
  const Command();

  bool get authorized => true;

  HttpMethod get method;

  String get uri;

  dynamic get data;

  T parse(dynamic json);
}

enum CheckNameMode {
  /// 自动重命名，存在并发问题
  autoRename,

  /// 同名不创建
  refuse,

  /// 同名文件可创建
  ignore;

  String get name => switch (this) {
        CheckNameMode.autoRename => 'auto_rename',
        CheckNameMode.refuse => 'refuse',
        CheckNameMode.ignore => 'ignore',
      };

  static CheckNameMode fromName(String name) {
    return CheckNameMode.values.firstWhere((e) => e.name == name);
  }
}

enum FileOrder {
  createdAt,
  updatedAt,
  name,
  size,

  /// 对数字编号的文件友好，排序结果为 1、2、3...99 而不是 1、10、11...2、21...9、91...99
  nameEnhanced;
}

extension FileOrderExtension on FileOrder {
  String get name => switch (this) {
        FileOrder.createdAt => 'created_at',
        FileOrder.updatedAt => 'updated_at',
        FileOrder.name => 'name',
        FileOrder.size => 'size',
        FileOrder.nameEnhanced => 'name_enhanced',
      };
}

enum FileOrderDirection {
  desc,
  asc;

  String get name => switch (this) {
        FileOrderDirection.desc => 'DESC',
        FileOrderDirection.asc => 'ASC',
      };
}
