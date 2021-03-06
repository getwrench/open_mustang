import 'package:mustang_core/src/interfaces/aspect_impl.dart';

class After {
  const After(
    this.aspects, {
    this.args = const <String, dynamic>{},
  });

  final List<AspectImpl> aspects;
  final Map<String, dynamic> args;
}
