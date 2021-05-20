import 'dart:io';

import 'package:args/args.dart';
import 'package:cli/src/app_model.dart';
import 'package:cli/src/screen_directory.dart';
import 'package:cli/src/screen_service.dart';
import 'package:cli/src/screen_state.dart';
import 'package:cli/src/utils.dart';

import 'src/args.dart';
import 'src/screen.dart';

class Cli {
  static run(List<String> args) async {
    ArgParser parser;
    try {
      parser = Args.parser();
      ArgResults parsedArgs = parser.parse(args);

      if (parsedArgs.arguments.isEmpty) {
        print(parser.usage);
        exitCode = 2;
        return;
      }

      // if arg -c/--create exists
      String screenDir = parsedArgs['screen'];
      if (screenDir != null) {
        screenDir = screenDir.toLowerCase().replaceAll('-', '_');
        await ScreenDirectory.create(screenDir);
        await ScreenState.create(screenDir);
        await ScreenService.create(screenDir);
        await Screen.create(screenDir);
      }

      // if arg -m/--model exists
      String modelFile = parsedArgs['model'];
      if (modelFile != null) {
        await AppModel.create(modelFile);
      }

      // if arg -d/--clean exists
      bool cleanFlag = parsedArgs['clean'];
      if (cleanFlag) {
        Utils.runProcess('flutter', [
          'pub',
          'run',
          'build_runner',
          'clean',
        ]);
      }

      // if arg -b/--build exists
      bool buildFlag = parsedArgs['build'];
      if (buildFlag) {
        Utils.runProcess('flutter', [
          'pub',
          'run',
          'build_runner',
          'build',
          '--delete-conflicting-outputs',
        ]);
        return;
      }

      // if arg -w/--watch exists
      bool watchFlag = parsedArgs['watch'];
      if (watchFlag) {
        Utils.runProcess('flutter', [
          'pub',
          'run',
          'build_runner',
          'watch',
        ]);
        return;
      }
    } catch (e) {
      exitCode = 2;
      print(e.toString());
      print(parser.usage);
    }
  }
}
