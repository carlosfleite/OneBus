import 'package:latlong2/latlong.dart';

class BusStop {
  final String id;
  final String name;
  final String address;
  final LatLng position;
  final List<String> lineIds;

  /// Step-free boarding: ramp, tactile paving and a shelter with space for
  /// wheelchairs.
  final bool accessible;

  const BusStop({
    required this.id,
    required this.name,
    required this.address,
    required this.position,
    required this.lineIds,
    this.accessible = false,
  });
}
