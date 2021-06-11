import 'dart:io';

import 'package:path/path.dart' as p;

import 'utils.dart';

class AppModel {
  /// [modelFile] is the name of the file that gets created inside `/lib/models` directory
  static Future<void> create(String modelFile) async {
    modelFile = modelFile.replaceAll('-', '_').replaceAll('\.dart', '');
    // removing directories in the path, if any
    modelFile = p.basename(modelFile);
    String path = '${Utils.defaultModelPrefix}/$modelFile.dart';
    String modelClass = Utils.pathToClass(modelFile);

    String modelsDir = p.dirname(path);
    bool exists = await Directory(modelsDir).exists();
    if (!exists) {
      await Directory(modelsDir).create(recursive: true);
      print('  Created $modelsDir');
    }

    exists = await File(path).exists();
    if (!exists) {
      File file = File(path);
      await file.writeAsString(_template(modelClass));
      print('  Created $path');
      return;
    }
    print('$path exists, skipping operation..');
  }

  static String _template(String modelClass) {
    return '''
import 'package:mustang_core/mustang_core.dart';

@appModel 
class \$$modelClass {
  @InitField(false)
  bool busy;

  @InitField('')
  String errorMsg;
  
  @InitField(false)
  bool clearScreenCache;
}
    ''';
  }
}
