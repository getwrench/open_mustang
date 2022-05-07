import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:mustang_widgets/src/widgets/state_consumer.dart';
import 'package:mustang_widgets/src/widgets/state_provider.dart';

class MustangScreen<T extends ChangeNotifier> extends StatelessWidget {
  const MustangScreen({
    Key? key,
    required this.state,
    required this.builder,
    this.fetchData,
  }) : super(key: key);

  /// Mustang state instance associated with this screen
  final T state;

  /// Builder to construct the body of the Mustang screen
  final Widget Function(BuildContext context, T state) builder;

  /// Fetch data for the screen
  final Function? fetchData;

  @override
  Widget build(BuildContext context) {
    return StateProvider<T>(
      state: state,
      child: Builder(
        builder: (context) {
          T state = StateConsumer<T>().of(context)!;

          if (fetchData != null) {
            SchedulerBinding.instance?.addPostFrameCallback(
              (_) => fetchData!(),
            );
          }

          return builder(context, state);
        },
      ),
    );
  }
}
