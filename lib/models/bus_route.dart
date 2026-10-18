import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// A closed bus loop with helpers to walk along it by distance (meters).
///
/// Uses a local equirectangular projection, which is accurate enough at
/// city scale and keeps the per-frame math cheap.
class BusRoute {
  final String lineId;
  final List<LatLng> points;

  late final double _originLat;
  late final double _mPerDegLng;
  static const double _mPerDegLat = 110574;

  late final List<double> _xs;
  late final List<double> _ys;
  late final List<double> _cumulative;
  late final double length;

  BusRoute(this.lineId, this.points) {
    _originLat = points.first.latitude;
    _mPerDegLng = 111320 * math.cos(_originLat * math.pi / 180);
    _xs = [for (final p in points) p.longitude * _mPerDegLng];
    _ys = [for (final p in points) p.latitude * _mPerDegLat];
    _cumulative = [0];
    for (var i = 1; i < points.length; i++) {
      final dx = _xs[i] - _xs[i - 1];
      final dy = _ys[i] - _ys[i - 1];
      _cumulative.add(_cumulative.last + math.sqrt(dx * dx + dy * dy));
    }
    length = _cumulative.last;
  }

  /// Position after travelling [distance] meters from the start (wraps).
  LatLng pointAt(double distance) {
    final d = distance % length;
    var lo = 0, hi = _cumulative.length - 1;
    while (hi - lo > 1) {
      final mid = (lo + hi) >> 1;
      if (_cumulative[mid] <= d) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final segLen = _cumulative[hi] - _cumulative[lo];
    final t = segLen == 0 ? 0.0 : (d - _cumulative[lo]) / segLen;
    final a = points[lo], b = points[hi];
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }

  /// Heading in degrees (0 = north, clockwise). Measured over a short chord
  /// around [distance] so the vehicle turns smoothly through corners.
  double bearingAt(double distance, {double chord = 14}) {
    final a = pointAt(distance - chord);
    final b = pointAt(distance + chord);
    final dx = (b.longitude - a.longitude) * _mPerDegLng;
    final dy = (b.latitude - a.latitude) * _mPerDegLat;
    return (math.atan2(dx, dy) * 180 / math.pi + 360) % 360;
  }

  /// Projects [p] onto the route. Returns the distance along the route of
  /// the closest point and how far (meters) [p] is from it.
  ({double along, double offset}) project(LatLng p) {
    final px = p.longitude * _mPerDegLng;
    final py = p.latitude * _mPerDegLat;
    var best = double.infinity;
    var bestAlong = 0.0;
    for (var i = 1; i < _xs.length; i++) {
      final ax = _xs[i - 1], ay = _ys[i - 1];
      final dx = _xs[i] - ax, dy = _ys[i] - ay;
      final len2 = dx * dx + dy * dy;
      final t = len2 == 0
          ? 0.0
          : (((px - ax) * dx + (py - ay) * dy) / len2).clamp(0.0, 1.0);
      final cx = ax + dx * t, cy = ay + dy * t;
      final dist = math.sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy));
      if (dist < best) {
        best = dist;
        bestAlong = _cumulative[i - 1] + math.sqrt(len2) * t;
      }
    }
    return (along: bestAlong % length, offset: best);
  }
}
