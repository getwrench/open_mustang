import 'dart:async';

class MustangObservable {
  static final StreamController _streamController = StreamController();

  static void pushEvent<T>(T t) {
    _streamController.add(t);
  }

  static Stream getEventStream() {
    return _streamController.stream;
  }

  static void dispose() {
    _streamController.close();
  }
}
