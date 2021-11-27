import 'package:flutter/material.dart';

class StateProvider<T extends ChangeNotifier> extends InheritedNotifier<T> {
  StateProvider({
    Key? key,
    required T state,
    required Widget child,
  }) : super(key: key, notifier: state, child: child);
}
