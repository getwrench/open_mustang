import 'dart:async';

import 'package:mustang_core/src/annotations/app_event.dart';

class EventStream {
  static StreamController<AppEvent> _streamController =
      StreamController<AppEvent>();

  static void pushEvent(AppEvent event) {
    _streamController.add(event);
  }

  static Future<Stream<AppEvent>> getStream() async {
    if (_streamController.hasListener) {
      await _streamController.close();
    }
    _streamController = StreamController<AppEvent>();
    return _streamController.stream;
  }
}
