import 'package:mustang_core/mustang_core.dart';

class Around {
  const Around(
    this.aspect, {
    this.args = const <String, dynamic>{},
  });

  final AspectImpl aspect;
  final Map<String, dynamic> args;
}
