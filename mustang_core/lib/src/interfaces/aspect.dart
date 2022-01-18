abstract class Aspect {
  bool preHook();

  void postHook();

  bool onException(
    Object e,
    StackTrace stackTrace, {
    String? message,
  });
}
