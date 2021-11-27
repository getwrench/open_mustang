class ScreenService {
  const ScreenService({
    required this.screenState,
    this.rootState,
    this.rootStateDir,
  });

  final Object screenState;
  final Object? rootState;
  final String? rootStateDir;
}
