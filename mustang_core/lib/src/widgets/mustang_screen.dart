import 'package:flutter/widgets.dart';
import 'package:mustang_core/src/widgets/state_consumer.dart';
import 'package:mustang_core/src/widgets/state_provider.dart';

class MustangScreen<T extends ChangeNotifier> extends StatelessWidget {
  const MustangScreen({
    Key? key,
    required this.state,
    required this.builder,
  }) : super(key: key);

  /// Mustang state instance associated with this screen
  final T state;

  /// Builder to construct the body of the Mustang screen
  final Widget Function(BuildContext context, T state) builder;

  @override
  Widget build(BuildContext context) {
    return StateProvider<T>(
      state: state,
      child: Builder(
        builder: (context) {
          T state = StateConsumer<T>().of(context)!;
          return builder(context, state);
        },
      ),
    );
  }
}
