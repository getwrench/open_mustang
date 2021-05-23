import 'dart:io';

import 'utils.dart';

class ScreenService {
  /// [screenDir] is the directory path in  `lib/src/screens`
  static Future<void> create(String screenDir) async {
    String assetName = Utils.pathToClass(screenDir);
    String assetFilename = Utils.class2File(assetName);
    String path =
        '${Utils.defaultAssetPrefix}/$screenDir/${assetFilename}_service.dart';
    bool exists = await File(path).exists();
    if (!exists) {
      File file = File(path);
      await file.writeAsString(_template(assetName, assetFilename));
      print('Created $path');
      return;
    }
    print('$path exists, skipping operation..');
  }

  static String _template(String assetName, String assetFilename) {
    return '''
import 'package:mustang_core/mustang_core.dart';
import '${assetFilename}_state.dart';
import '${assetFilename}_service.service.dart';

@ScreenService(screenState: \$${assetName}State) 
class ${assetName}Service {
}
    ''';
  }
}
