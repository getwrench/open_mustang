import 'package:flutter/material.dart';

class StateProvider<T extends ChangeNotifier> extends InheritedNotifier<T> {
  StateProvider({
    Key key,
    @required T state,
    @required Widget child,
  })  : assert(state != null),
        assert(child != null),
        super(key: key, notifier: state, child: child);
}
