class ScreenService {
  const ScreenService({
    required this.screenState,
    this.rootState,
    this.rootStateDir,
  });

  final Object screenState;

  @deprecated
  final Object? rootState;

  @deprecated
  final String? rootStateDir;
}
