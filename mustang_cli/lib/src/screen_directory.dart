import 'dart:io';

import 'utils.dart';

class ScreenDirectory {
  /// [directory] argument takes the form `dir1/dir2`.
  /// Path specified by [directory] argument will be created inside `lib/src/screens`
  /// of the flutter project directory
  static Future<void> create(String directory) async {
    String path = '${Utils.defaultScreenPrefix}/$directory';
    bool exists = await Directory(path).exists();
    if (!exists) {
      await Directory(path).create(recursive: true);
      print('  Created $path');
      return;
    }
    print('$path exists, skipping operation..');
  }
}
