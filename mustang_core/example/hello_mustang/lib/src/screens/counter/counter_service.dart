import 'package:hello_mustang/src/models/counter.model.dart';
import 'package:hello_mustang/src/screens/counter/counter_service.service.dart';
import 'package:mustang_core/mustang_core.dart';

@screenService
abstract class $CounterService {

  void increment() {
    Counter counter = MustangStore.get<Counter>() ?? Counter();
    counter = counter.rebuild((b) => b..value = (b.value ?? 0) + 1);
    updateState1(counter);
  }
}
