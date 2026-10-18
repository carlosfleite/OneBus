import 'package:latlong2/latlong.dart';

import '../data/mock_data.dart';
import '../models/bus_stop.dart';
import '../models/recharge_point.dart';

/// Average walking pace used for "X min a pé".
const walkMetersPerMinute = 80.0;

const _distance = Distance();

String _distanceLabel(double meters) => meters < 1000
    ? '${(meters / 10).round() * 10} m'
    : '${(meters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';

int _walkMinutes(double meters) =>
    (meters / walkMetersPerMinute).ceil().clamp(1, 999);

class NearbyStop {
  final BusStop stop;
  final double meters;

  const NearbyStop(this.stop, this.meters);

  int get walkMinutes => _walkMinutes(meters);

  String get distanceLabel => _distanceLabel(meters);

  String get walkLabel => '$walkMinutes min a pé';
}

/// Every stop, closest to [from] first (defaults to the user's location).
List<NearbyStop> stopsByDistance([LatLng from = MockData.userLocation]) =>
    [for (final s in MockData.stops) NearbyStop(s, _distance(from, s.position))]
      ..sort((a, b) => a.meters.compareTo(b.meters));

NearbyStop nearestStop([LatLng from = MockData.userLocation]) =>
    stopsByDistance(from).first;

NearbyStop distanceTo(String stopId) {
  final stop = MockData.stop(stopId);
  return NearbyStop(stop, _distance(MockData.userLocation, stop.position));
}

class NearbyRecharge {
  final RechargePoint point;
  final double meters;

  const NearbyRecharge(this.point, this.meters);

  String get distanceLabel => _distanceLabel(meters);

  String get walkLabel => '${_walkMinutes(meters)} min a pé';
}

/// Every recharge point, closest to the user first.
List<NearbyRecharge> rechargeByDistance() => [
  for (final r in MockData.rechargePoints)
    NearbyRecharge(r, _distance(MockData.userLocation, r.position)),
]..sort((a, b) => a.meters.compareTo(b.meters));

NearbyRecharge rechargeDistanceTo(String id) {
  final r = MockData.rechargePoint(id);
  return NearbyRecharge(r, _distance(MockData.userLocation, r.position));
}
