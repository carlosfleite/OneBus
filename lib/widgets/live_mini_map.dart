import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme/app_colors.dart';
import '../data/mock_data.dart';
import '../services/bus_simulator.dart';
import '../services/nearby.dart';
import 'bus_marker.dart';
import 'map_layers.dart';

/// Compact live map for the top of Início: you, the nearest stop, your
/// favorite stops, and the favorite lines' buses moving in real time.
class LiveMiniMap extends StatefulWidget {
  final Set<String> lineIds;
  final Set<String> stopIds;
  final EdgeInsets padding;
  final VoidCallback onTap;

  const LiveMiniMap({
    super.key,
    required this.lineIds,
    required this.stopIds,
    required this.onTap,
    this.padding = const EdgeInsets.fromLTRB(40, 100, 40, 50),
  });

  @override
  State<LiveMiniMap> createState() => _LiveMiniMapState();
}

class _LiveMiniMapState extends State<LiveMiniMap>
    with SingleTickerProviderStateMixin {
  final _sim = BusSimulator.instance;
  final _frame = ValueNotifier<int>(0);
  late final Ticker _ticker;
  final _nearest = nearestStop();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => _frame.value++)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  List<LatLng> get _fitPoints => [
    MockData.userLocation,
    _nearest.stop.position,
    for (final id in widget.stopIds) MockData.stop(id).position,
  ];

  @override
  Widget build(BuildContext context) {
    final ios = IosColors.of(context);
    final lines = widget.lineIds.isEmpty
        ? MockData.lines.map((l) => l.id).toSet()
        : widget.lineIds;

    return GestureDetector(
      onTap: widget.onTap,
      child: AbsorbPointer(
        child: FlutterMap(
          // Refit when the set of favorites changes.
          key: ValueKey(Object.hashAll([...lines, ...widget.stopIds])),
          options: MapOptions(
            initialCenter: MockData.userLocation,
            initialZoom: 15,
            initialCameraFit: CameraFit.coordinates(
              coordinates: _fitPoints,
              padding: widget.padding,
              maxZoom: 14.8,
            ),
            backgroundColor: mapBackground(context),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            const OneBusTileLayer(),
            PolylineLayer(
              polylines: [
                for (final id in lines)
                  Polyline(
                    points: MockData.routes[id]!.points,
                    color: MockData.line(id).color.withValues(alpha: 0.85),
                    strokeWidth: 5,
                    borderColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black54
                        : Colors.white,
                    borderStrokeWidth: 2,
                  ),
                Polyline(
                  points: [MockData.userLocation, _nearest.stop.position],
                  color: ios.tint,
                  strokeWidth: 4,
                  pattern: const StrokePattern.dotted(spacingFactor: 2),
                ),
              ],
            ),
            ValueListenableBuilder<int>(
              valueListenable: _frame,
              builder: (context, _, _) => MarkerLayer(
                markers: [
                  for (final bus in _sim.buses)
                    if (lines.contains(bus.lineId))
                      Marker(
                        point: _sim.positionOf(bus),
                        width: 64,
                        height: 64,
                        child: Transform.scale(
                          scale: 0.85,
                          child: BusMarker(
                            color: MockData.line(bus.lineId).color,
                            number: MockData.line(bus.lineId).number,
                            bearing: _sim.bearingOf(bus),
                            stale: !bus.hasSignal,
                          ),
                        ),
                      ),
                ],
              ),
            ),
            MarkerLayer(
              markers: [
                for (final id in {...widget.stopIds, _nearest.stop.id})
                  Marker(
                    point: MockData.stop(id).position,
                    width: 30,
                    height: 30,
                    child: StopPin(
                      selected: widget.stopIds.contains(id),
                      nearest: id == _nearest.stop.id
                          ? _nearest.walkLabel
                          : null,
                    ),
                  ),
                Marker(
                  point: MockData.userLocation,
                  width: 44,
                  height: 44,
                  child: UserDot(color: ios.tint),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
