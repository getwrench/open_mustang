import 'package:flutter/widgets.dart';
import 'package:mustang_widgets/src/widgets/state_provider.dart';

class StateConsumer<T extends ChangeNotifier> {
  T? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<StateProvider<T>>()
        ?.notifier;
  }
}
