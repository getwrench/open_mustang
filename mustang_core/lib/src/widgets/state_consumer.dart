import 'package:flutter/material.dart';
import 'package:mustang_core/src/widgets/state_provider.dart';

class StateConsumer<T extends ChangeNotifier> {
  T of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<StateProvider<T>>()
        .notifier;
  }
}
