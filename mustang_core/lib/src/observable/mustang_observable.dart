import 'dart:async';

class MustangObservable {
  static final StreamController<EventType> _streamController =
      StreamController<EventType>();

  static void pushEvent<T>(T t) {
    _streamController.sink.add(EventType<T>(t: t));
  }

  static Stream eventStream() {
    return _streamController.stream;
  }

  static void dispose() {
    _streamController.close();
  }
}

class EventType<T> {
  EventType({required this.t});
  final T t;
}
