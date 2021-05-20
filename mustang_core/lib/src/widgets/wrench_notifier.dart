import 'package:flutter/widgets.dart';

class WrenchNotifier extends ChangeNotifier {
  void update() {
    notifyListeners();
  }
}
