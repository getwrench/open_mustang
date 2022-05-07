import 'package:mustang_core/mustang_core.dart';

@appModel
abstract class $Counter {
  @InitField(false)
  @SerializeField(false)
  late bool busy;

  @InitField('')
  @SerializeField(false)
  late String errorMsg;

  @InitField(false)
  late bool clearScreenCache;

  @InitField(0)
  late int value;
}
