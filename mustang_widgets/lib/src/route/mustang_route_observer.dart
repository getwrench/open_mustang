import 'package:flutter/widgets.dart';

class MustangRouteObserver {
  static RouteObserver<ModalRoute<void>>? routeObserver;

  static RouteObserver<ModalRoute<void>> getInstance() {
    routeObserver ??= RouteObserver<ModalRoute<void>>();
    return routeObserver!;
  }
}
