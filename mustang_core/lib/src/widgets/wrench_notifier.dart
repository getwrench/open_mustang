import 'package:flutter/material.dart';

class WrenchNotifier extends ChangeNotifier {
  void update() {
    notifyListeners();
  }
}
