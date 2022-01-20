import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final StreamController<ConnectivityStatus> _streamController =
      StreamController<ConnectivityStatus>.broadcast();

  ConnectivityService._() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        _streamController.sink.add(ConnectivityStatus.offline);
      } else {
        _streamController.sink.add(ConnectivityStatus.online);
      }
    });
  }

  static Stream<ConnectivityStatus> connectivityStatus() async* {
    await for (ConnectivityStatus status
        in ConnectivityService._()._streamController.stream) {
      yield status;
    }
  }

  void dispose() {
    _streamController.close();
  }
}

enum ConnectivityStatus { offline, online }
