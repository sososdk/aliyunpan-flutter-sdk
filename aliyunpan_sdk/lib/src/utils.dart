import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;

extension IntListExtension on List<int> {
  String get md5 => crypto.md5.convert(this).toString();

  String get sha1 => crypto.sha1.convert(this).toString();
}

extension StringMd5Extension on String {
  String get md5 => utf8.encode(this).md5.toString();
}

extension StreamReadExtension on Stream<List<int>> {
  Future<List<int>> read(int length) async {
    final buf = <int>[];
    await for (final chunk in this) {
      buf.addAll(chunk);
      if (buf.length == length) {
        return buf;
      } else if (buf.length > length) {
        return buf.sublist(0, length);
      }
    }
    throw ArgumentError('End of stream');
  }
}

extension StreamSha1Extension on Stream<List<int>> {
  Future<String> get sha1 =>
      crypto.sha1.bind(this).last.then((e) => e.toString());
}

/// 获取秒传值
Future<String?> getProofCode(
  String accessToken,
  int length,
  Stream<List<int>> Function(int start, int end) openRead,
) async {
  try {
    final string = accessToken.md5.substring(0, 16);
    final value = int.parse(string, radix: 16);
    final index = value % length;
    final data = await openRead(index, index + 8).read(8);
    return base64Encode(data);
  } catch (e) {
    return null;
  }
}
