import 'package:flutter/foundation.dart';

class ProgressNotifier extends ChangeNotifier {
  int _totalScore = 0;

  int get totalScore => _totalScore;

  void updateScore(int newScore) {
    _totalScore = newScore;
    notifyListeners();
  }
}

// Global instance
final progressNotifier = ProgressNotifier();