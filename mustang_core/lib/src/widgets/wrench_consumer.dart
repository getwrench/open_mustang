import 'package:flutter/material.dart';
import 'package:mustang_core/src/widgets/wrench_provider.dart';

class WrenchConsumer<T extends ChangeNotifier> {
  T of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<WrenchProvider<T>>()
        .notifier;
  }
}
