import 'dart:io';

import 'utils.dart';

class Screen {
  /// [screenDir] is the directory path in  `lib/src/screens`
  static Future<void> create(String screenDir) async {
    String assetName = Utils.pathToClass(screenDir);
    String assetFilename = Utils.class2File(assetName);
    String path =
        '${Utils.defaultAssetPrefix}/$screenDir/${assetFilename}_screen.dart';

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
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '${assetFilename}_service.dart';

class ${assetName}Screen extends StatelessWidget {
    const ${assetName}Screen({
      Key key,
    }) : super(key: key);
  
    @override
    Widget build(BuildContext context) {
      return ChangeNotifierProvider<${assetName}State>(
        create: (context) => ${assetName}State(),
        child: Consumer<${assetName}State>(
          builder: (
            BuildContext context,
            ${assetName}State state,
            Widget _,
          ) {
            SchedulerBinding.instance.addPostFrameCallback(
              (_) => ${assetName}Service().memoizedGetData(),
            );
  
            if (state?.common?.busy ?? false) return Spinner();
  
            if (state.common?.errorMsg != null)
              return ErrorBody(errorMsg: state.common.errorMsg);
  
            return _body(state, context);
          },
        ),
      );
    }
  
    Widget _body(${assetName}State state, BuildContext context) {
      return RefreshIndicator(
        onRefresh: () => ${assetName}Service().getData(),
        child: Container(),
      );
    }
}

    ''';
  }
}
