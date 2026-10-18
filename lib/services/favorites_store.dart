import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/mock_data.dart';

/// Favorite lines and stops, plus the "favorite arriving" notification
/// preferences, persisted on the device.
class FavoritesStore extends ChangeNotifier {
  FavoritesStore._();

  static final instance = FavoritesStore._();

  static const _linesKey = 'fav_lines';
  static const _stopsKey = 'fav_stops';
  static const _notifyKey = 'fav_notify';
  static const _minutesKey = 'fav_notify_minutes';

  static const minuteOptions = [2, 5, 10];

  final Set<String> lines = {'l214', 'l302'};
  final Set<String> stops = {'s1', 's5'};

  /// Notify when a favorite line is about to reach a favorite stop.
  bool notifyArrivals = true;
  int notifyMinutes = 5;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final l = prefs.getStringList(_linesKey);
      final s = prefs.getStringList(_stopsKey);
      if (l != null) {
        lines
          ..clear()
          ..addAll(l);
      }
      if (s != null) {
        stops
          ..clear()
          ..addAll(s);
      }
      notifyArrivals = prefs.getBool(_notifyKey) ?? notifyArrivals;
      notifyMinutes = prefs.getInt(_minutesKey) ?? notifyMinutes;
      notifyListeners();
    } catch (_) {}
  }

  bool hasLine(String id) => lines.contains(id);

  bool hasStop(String id) => stops.contains(id);

  /// Favorite line × favorite stop combinations the line actually serves.
  List<({String lineId, String stopId})> get watchedPairs => [
    for (final stopId in stops)
      for (final lineId in lines)
        if (MockData.stop(stopId).lineIds.contains(lineId))
          (lineId: lineId, stopId: stopId),
  ];

  void toggleLine(String id) {
    lines.contains(id) ? lines.remove(id) : lines.add(id);
    _save();
  }

  void toggleStop(String id) {
    stops.contains(id) ? stops.remove(id) : stops.add(id);
    _save();
  }

  void setNotifyArrivals(bool value) {
    notifyArrivals = value;
    _save();
  }

  void setNotifyMinutes(int value) {
    notifyMinutes = value;
    _save();
  }

  Future<void> _save() async {
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_linesKey, lines.toList());
      await prefs.setStringList(_stopsKey, stops.toList());
      await prefs.setBool(_notifyKey, notifyArrivals);
      await prefs.setInt(_minutesKey, notifyMinutes);
    } catch (_) {}
  }
}
