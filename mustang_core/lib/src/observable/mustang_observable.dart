import 'dart:async';

class MustangObservable {
  static final MustangObservable _mustangObservable =
      MustangObservable._internal();
  static final StreamController _streamController = StreamController();

  factory MustangObservable() {
    return _mustangObservable;
  }

  MustangObservable._internal();

  static void initStream<T>(Stream stream, T t) async {
    stream.listen((event) {
      _streamController.sink.add(EventType(event: event, model: t));
    });
  }

  static Stream statusEmitter() async* {
    await for (var status in _streamController.stream) {
      yield status;
    }
  }

  static void dispose() {
    _streamController.close();
  }
}

class EventType<T> {
  EventType({
    required this.event,
    required this.model,
  });

  dynamic event;
  T model;
}
