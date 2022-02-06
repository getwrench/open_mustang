import 'dart:async';

import 'package:mustang_core/src/annotations/app_event.dart';

class EventStream {
  static StreamController<AppEvent> _streamController =
      StreamController<AppEvent>();

  static void pushEvent(AppEvent event) {
    _streamController.add(event);
  }

  static Stream<AppEvent> getStream() {
    return _streamController.stream;
  }

  static void reset() {
    if (_streamController.hasListener) {
      _streamController.close();
    }
    _streamController = StreamController<AppEvent>();
  }
}
