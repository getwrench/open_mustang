import 'package:meta/meta.dart';

class AppModelMethod {
  AppModelMethod({
    @required this.name,
    @required this.type,
    this.sourceOffset,
    this.sourceLength,
  })  : assert(name != null),
        assert(type != null);

  final String name;
  final String type;
  final int sourceOffset;
  int sourceLength;

  @override
  String toString() {
    return '$type ${name}() -> $sourceOffset $sourceLength';
  }
}
