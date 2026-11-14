import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// State of the first-access guided tour.
///
/// The tour starts once, the first time the user reaches the main screen;
/// "Rever tour do app" (Conta) starts it again.
class TourController extends ChangeNotifier {
  TourController._();

  static final instance = TourController._();

  static const _key = 'tour_done';

  /// The user already finished (or skipped) the tour.
  bool done = false;

  bool active = false;
  int step = 0;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      done = prefs.getBool(_key) ?? false;
    } catch (_) {}
  }

  /// Starts the tour automatically, only if it was never completed.
  void startIfFirstTime() {
    if (!done) start();
  }

  void start() {
    step = 0;
    active = true;
    notifyListeners();
  }

  void goTo(int index) {
    step = index;
    notifyListeners();
  }

  /// Ends the tour (finished or skipped) and remembers it.
  Future<void> finish() async {
    active = false;
    done = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (_) {}
  }

  @visibleForTesting
  void skipForTests() {
    done = true;
    active = false;
  }
}
