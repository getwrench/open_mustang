import 'package:flutter/material.dart';
import 'package:hello_mustang/src/screens/counter/counter_state.state.dart';
import 'package:mustang_widgets/mustang_widgets.dart';

class Greeting extends StatelessWidget {
  const Greeting({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    CounterState state = StateConsumer<CounterState>().of(context)!;
    return SizedBox(
      height: 100.0,
      width: 100.0,
      child: Text('Counter from the Greeting widget: ${state.counter.value}'),
    );
  }
}
