abstract class Aspect {
  bool preHook();

  void postHook();

  void onException(Object e, StackTrace stackTrace);
}