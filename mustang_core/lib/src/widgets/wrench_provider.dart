import 'package:flutter/material.dart';

class WrenchProvider<T extends ChangeNotifier> extends InheritedNotifier<T> {
  WrenchProvider({
    Key key,
    @required T notifier,
    @required Widget child,
  })  : assert(notifier != null),
        assert(child != null),
        super(key: key, notifier: notifier, child: child);
}
