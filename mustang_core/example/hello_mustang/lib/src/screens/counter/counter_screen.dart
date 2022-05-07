import 'package:flutter/material.dart';
import 'package:hello_mustang/src/screens/counter/greeting.dart';
import 'package:mustang_core/mustang_widgets.dart';

import 'counter_service.service.dart';
import 'counter_state.state.dart';

class CounterScreen extends StatelessWidget {
  const CounterScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MustangScreen<CounterState>(
      state: CounterState(context: context),
      builder: (BuildContext context, CounterState state) {
        if (state.counter.busy) {
          return const CircularProgressIndicator();
        }

        if (state.counter.errorMsg.isNotEmpty) {
          Text(state.counter.errorMsg);
        }

        return _body(state, context);
      },
    );
  }

  Widget _body(CounterState? state, BuildContext context) {
    int counter = state?.counter.value ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter'),
      ),
      body: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('$counter'),
            ),
            const Greeting(),
            ElevatedButton(
              onPressed: CounterService().increment,
              child: const Text('Increment'),
            ),
          ],
        ),
      ),
    );
  }
}
