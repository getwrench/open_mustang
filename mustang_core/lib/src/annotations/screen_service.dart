import 'package:meta/meta.dart';

class ScreenService {
  const ScreenService({
    @required this.screenState,
    this.rootState,
    this.rootStateDir,
  }) : assert(screenState != null);

  final Object screenState;
  final Object rootState;
  final String rootStateDir;
}
