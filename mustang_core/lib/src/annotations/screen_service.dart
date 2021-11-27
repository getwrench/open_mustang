class ScreenService {
  const ScreenService({
    required this.screenState,
    this.rootState,
    this.rootStateDir,
  });

  final Object screenState;

  @Deprecated('Not supported')
  final Object? rootState;

  @Deprecated('Not supported')
  final String? rootStateDir;
}
