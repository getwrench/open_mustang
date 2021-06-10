import 'dart:io';

import 'utils.dart';

class Screen {
  /// [screenDir] is the directory path in  `lib/src/screens`
  static Future<void> create(String screenDir) async {
    String assetName = Utils.pathToClass(screenDir);
    String assetFilename = Utils.class2File(assetName);
    String path =
        '${Utils.defaultScreenPrefix}/$screenDir/${assetFilename}_screen.dart';

    bool exists = await File(path).exists();
    if (!exists) {
      File file = File(path);
      await file.writeAsString(_template(assetName, assetFilename));
      print('  Created $path');
      return;
    }

    print('$path exists, skipping operation..');
  }

  static String _template(String assetName, String assetFilename) {
    String modelVar = Utils.classNameToVar(assetName);
    return '''
import 'package:flutter/material.dart';
import 'package:mustang_core/mustang_widgets.dart';
import 'package:flutter/scheduler.dart';
import 'package:wrench_widgets/widgets.dart';

import '${assetFilename}_state.state.dart';
import '${assetFilename}_service.dart';

class ${assetName}Screen extends StatelessWidget {
    const ${assetName}Screen({
      Key key,
    }) : super(key: key);
  
    @override
    Widget build(BuildContext context) {
      return StateProvider<${assetName}State>(
        state: ${assetName}State(),
        child: Builder(
          builder: (BuildContext context) {
            ${assetName}State state = StateConsumer<${assetName}State>().of(context);
            SchedulerBinding.instance.addPostFrameCallback(
              (_) => ${assetName}Service().memoizedGetData(),
            );
  
            if (state?.$modelVar?.busy ?? false) {
              return WrenchProgressIndicatorScreen(); 
            }
  
            if (state?.$modelVar?.errorMsg?.isNotEmpty ?? false) {
              return WrenchErrorWithDescriptionScreen(
                description: state.$modelVar.errorMsg,
                onPressed: () {
                  ${assetName}Service().clearCacheAndReload();
                },
              );
            }
  
            return _body(state, context);
          },
        ),
      );
    }
  
    Widget _body(${assetName}State state, BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text('$assetName'),
        ),
        body: RefreshIndicator(
          onRefresh: () => ${assetName}Service().getData(showBusy: false),
          child: Container(
            child: Text('Generated screen'),
          ),
        ),
      );
    }
}
    ''';
  }
}
