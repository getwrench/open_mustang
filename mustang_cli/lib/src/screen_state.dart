import 'dart:io';

import 'utils.dart';

class ScreenState {
  /// [screenDir] is the directory path in  `lib/src/screens`
  static Future<void> create(String screenDir) async {
    String assetName = Utils.pathToClass(screenDir);
    String assetFilename = Utils.class2File(assetName);
    String path =
        '${Utils.defaultScreenPrefix}/$screenDir/${assetFilename}_state.dart';

    bool exists = await File(path).exists();
    if (!exists) {
      File file = File(path);
      await file.writeAsString(_template(assetName));
      print('  Created $path');
      return;
    }
    print('$path exists, skipping operation..');
  }

  static String _template(String assetName) {
    String modelVar = Utils.classNameToVar(assetName);
    String modelFileName = Utils.class2File(assetName);
    String pkgName = Utils.pkgName();
    return '''
import 'package:mustang_core/mustang_core.dart';
import '$pkgName/src/models/$modelFileName.dart';

@screenState 
class \$${assetName}State {
  \$$assetName $modelVar;
}
    ''';
  }
}
