import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';

import '../core/theme/app_colors.dart';
import '../data/mock_data.dart';
import '../services/bus_simulator.dart';
import 'bus_marker.dart';
import 'map_layers.dart';

/// Small street map inside the bus page: the bus (moving), its route and
/// the stops around it. The camera follows the bus.
class BusMiniMap extends StatefulWidget {
  final String busId;
  final double height;

  const BusMiniMap({super.key, required this.busId, this.height = 190});

  @override
  State<BusMiniMap> createState() => _BusMiniMapState();
}

class _BusMiniMapState extends State<BusMiniMap>
    with SingleTickerProviderStateMixin {
  static const _zoom = 16.0;

  final _sim = BusSimulator.instance;
  final _map = MapController();
  final _frame = ValueNotifier<int>(0);
  late final Ticker _ticker;
  bool _ready = false;

  SimulatedBus get _bus => _sim.bus(widget.busId);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      if (_ready) _map.move(_sim.positionOf(_bus), _zoom);
      _frame.value++;
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ios = IosColors.of(context);
    final bus = _bus;
    final line = MockData.line(bus.lineId);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: widget.height,
        child: AbsorbPointer(
          child: FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _sim.positionOf(bus),
              initialZoom: _zoom,
              backgroundColor: mapBackground(context),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
              onMapReady: () => _ready = true,
            ),
            children: [
              const OneBusTileLayer(plain: true),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: MockData.routes[bus.lineId]!.points,
                    color: line.color.withValues(alpha: 0.85),
                    strokeWidth: 6,
                    borderColor: dark ? Colors.black54 : Colors.white,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  for (final stop in MockData.stops)
                    if (stop.lineIds.contains(bus.lineId))
                      Marker(
                        point: stop.position,
                        width: 30,
                        height: 30,
                        child: StopPin(
                          selected: false,
                          accessible: stop.accessible,
                        ),
                      ),
                ],
              ),
              ValueListenableBuilder<int>(
                valueListenable: _frame,
                builder: (context, _, _) => MarkerLayer(
                  markers: [
                    Marker(
                      point: _sim.positionOf(bus),
                      width: 64,
                      height: 64,
                      child: BusMarker(
                        color: line.color,
                        number: line.number,
                        bearing: _sim.bearingOf(bus),
                        selected: true,
                        van: bus.isVan,
                        stale: !bus.hasSignal,
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    '© OpenStreetMap',
                    style: TextStyle(fontSize: 9, color: ios.secondaryLabel),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
