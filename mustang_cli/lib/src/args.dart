import 'package:args/args.dart';

class Args {
  static ArgParser parser() {
    ArgParser parser = ArgParser();

    parser.addOption(
      'screen',
      abbr: 's',
      help: 'Creates screen files inside lib/src/screens directory\n'
          ' booking/new_user/new_user_service.dart\n'
          ' booking/new_user/new_user_state.dart\n'
          ' booking/new_user/new_user_screen.dart\n',
      valueHelp: 'booking/new_user',
    );

    parser.addOption(
      'model',
      abbr: 'm',
      help: 'Creates vehicle.dart inside lib/src/models directory',
      valueHelp: 'vehicle',
    );

    parser.addFlag(
      'build',
      abbr: 'b',
      help: 'Generates runtime files',
      defaultsTo: false,
      negatable: false,
    );

    parser.addFlag(
      'clean',
      abbr: 'd',
      help: 'Deletes runtime files',
      defaultsTo: false,
      negatable: false,
    );

    parser.addFlag(
      'watch',
      abbr: 'w',
      help: 'Monitors files for changes and re-generate runtime files',
      defaultsTo: false,
      negatable: false,
    );
    return parser;
  }
}
