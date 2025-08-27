import 'dart:io';
import 'package:flutter/services.dart';

class Qalqan {
  static const _chan = MethodChannel('com.qalqan/qalqan');

  /// Возвращает true, если декрипт прошёл успешно.
  static Future<bool> decryptFile(File file, String password) async {
    final res = await _chan.invokeMethod<bool>('decryptFile', {
      'path': file.path,
      'password': password,
    });
    return res ?? false;
  }
}
