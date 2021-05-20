import 'package:core/src/widgets/wrench_provider.dart';
import 'package:flutter/widgets.dart';

class WrenchConsumer<T extends ChangeNotifier> {
  T of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<WrenchProvider<T>>()
        .notifier;
  }
}
