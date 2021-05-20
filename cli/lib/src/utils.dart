import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

class Utils {
  static String defaultAssetPrefix = 'lib/src/screens';

  static String class2File(String className) {
    RegExp exp = RegExp(r'(?<=[0-9a-z])[A-Z]');
    return className
        .replaceAllMapped(exp, (Match m) => ('_' + m.group(0)))
        .toLowerCase();
  }

  static String pathToClass(String path) {
    String screenDirName = p.basename(path);
    List<String> tokens = screenDirName.split('_');
    return tokens
        .map((token) {
          String firstLetter = token.substring(0, 1).toUpperCase();
          return '$firstLetter${token.substring(1)}';
        })
        .toList()
        .join('');
  }

  static void runProcess(String cmd, List<String> args) async {
    Process proc = await Process.start(cmd, args);
    proc.stdout.transform(utf8.decoder).listen(
          (data) => stdout.write(data),
          onError: (error) => stdout.write(error),
        );
    proc.stderr.transform(utf8.decoder).listen(
          (data) => stdout.write(data),
          onError: (error) => stdout.write(error),
        );
  }

  static validateModel(String name) {}
}
