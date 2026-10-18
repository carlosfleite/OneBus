import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../data/mock_data.dart';
import '../models/bus_route.dart';
import '../models/bus_stop.dart';

/// A fictional bus driving around its line's loop.
class SimulatedBus {
  final String id;
  final String lineId;
  final String plate;
  final bool accessible;
  final bool airConditioned;

  /// Adapted van that only serves accessible stops. Vans are not part of the
  /// regular bus timetable, so they don't count in arrival predictions.
  final bool isVan;

  /// Older vehicles with flaky GPS modems drop signal now and then — the
  /// app must show that honestly instead of inventing a position.
  final bool flakyGps;

  /// Distance travelled along the route (meters, monotonic — wrap with
  /// `% route.length`). [_previous] is the value at the previous GPS ping,
  /// used to interpolate between pings like ride-hailing apps do.
  double _distance;
  double _previous;
  double _speed;
  double _dwell = 0;
  int occupancy;

  /// Last position actually reported by the vehicle, and when.
  double _fix;
  int _fixMs = 0;
  int _gpsLostTicks = 0;

  SimulatedBus({
    required this.id,
    required this.lineId,
    required this.plate,
    required this.accessible,
    required this.airConditioned,
    required this.flakyGps,
    this.isVan = false,
    required double distance,
    required double speed,
    required this.occupancy,
  }) : _distance = distance,
       _previous = distance,
       _fix = distance,
       _speed = speed;

  bool get isAtStop => _dwell > 0;

  bool get hasSignal => _gpsLostTicks == 0;

  /// Simulated road speed in km/h (before the demo [BusSimulator.speedup]).
  int get speedKmh => isAtStop ? 0 : (_speed * 3.6).round();
}

/// Arrival prediction. [live] is false when it comes from the timetable or
/// from a vehicle that stopped reporting — users asked to always know which.
class Eta {
  final int seconds;
  final bool live;

  const Eta(this.seconds, {required this.live});

  String get label {
    if (seconds < 30) return 'Agora';
    final min = (seconds / 60).ceil();
    return live ? '$min min' : '~$min min';
  }
}

typedef RouteStop = ({double along, BusStop stop});

/// Drives fictional buses along [MockData.routes].
///
/// Position "pings" arrive every [tick] (like a real GPS feed). Between
/// pings, [positionOf]/[bearingOf] interpolate along the street geometry,
/// so markers glide smoothly when sampled every frame.
class BusSimulator extends ChangeNotifier {
  BusSimulator._() {
    _spawnBuses();
  }

  static final instance = BusSimulator._();

  static const tick = Duration(seconds: 1);

  /// Demo time multiplier so movement is visible at street zoom levels.
  static const speedup = 2.5;

  static const _busesPerLine = 3;

  /// Lines that also run an accessible van.
  static const _vanLines = ['l214', 'l302'];
  static const _stopDwellSeconds = 5.0;
  static const _avgSpeed = 10.5;

  final _random = math.Random(42);
  final _clock = Stopwatch()..start();
  int _lastPingMs = 0;
  Timer? _timer;
  int _listeners = 0;

  final List<SimulatedBus> buses = [];

  /// Stops of each line sorted by distance along its route.
  late final Map<String, List<RouteStop>> _stopsOnRoute = {
    for (final line in MockData.lines)
      line.id: [
        for (final stop in MockData.stops)
          if (stop.lineIds.contains(line.id))
            (
              along: MockData.routes[line.id]!.project(stop.position).along,
              stop: stop,
            ),
      ]..sort((a, b) => a.along.compareTo(b.along)),
  };

  List<RouteStop> stopsOf(String lineId) => _stopsOnRoute[lineId]!;

  BusRoute routeOf(SimulatedBus bus) => MockData.routes[bus.lineId]!;

  SimulatedBus bus(String id) => buses.firstWhere((b) => b.id == id);

  void _spawnBuses() {
    const letters = 'ABCDEFGHJKLMNPRSTUVWXYZ';
    String l() => letters[_random.nextInt(letters.length)];
    for (final line in MockData.lines) {
      final route = MockData.routes[line.id]!;
      for (var i = 0; i < _busesPerLine; i++) {
        buses.add(
          SimulatedBus(
            id: '${line.id}-$i',
            lineId: line.id,
            plate:
                'B${l()}${l()}-${_random.nextInt(10)}${l()}${_random.nextInt(90) + 10}',
            accessible: i != 2,
            airConditioned: i == 0 || line.id == 'l214',
            flakyGps: i == 2 && (line.id == 'l057' || line.id == 'l108'),
            distance:
                route.length * i / _busesPerLine + _random.nextDouble() * 300,
            speed: 9 + _random.nextDouble() * 3,
            occupancy: 20 + _random.nextInt(70),
          ),
        );
      }
    }
    for (final lineId in _vanLines) {
      final route = MockData.routes[lineId]!;
      buses.add(
        SimulatedBus(
          id: '$lineId-van',
          lineId: lineId,
          plate:
              'V${l()}${l()}-${_random.nextInt(10)}${l()}${_random.nextInt(90) + 10}',
          accessible: true,
          airConditioned: true,
          flakyGps: false,
          isVan: true,
          distance: route.length * 0.17 + _random.nextDouble() * 300,
          speed: 9 + _random.nextDouble() * 3,
          occupancy: 10 + _random.nextInt(30),
        ),
      );
    }
  }

  // Runs only while someone is listening, so hidden screens and tests
  // don't keep a timer alive.
  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    if (_listeners++ == 0) {
      _timer = Timer.periodic(tick, (_) => _ping());
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (--_listeners == 0) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _ping() {
    final dt = tick.inMilliseconds / 1000;
    final now = _clock.elapsedMilliseconds;
    for (final bus in buses) {
      // Signal back: glide from the last known fix to the real position.
      bus._previous = _updateGps(bus) ? bus._fix : bus._distance;
      if (bus._dwell > 0) {
        bus._dwell -= dt;
      } else {
        _drive(bus, dt);
      }
      if (bus.hasSignal) {
        bus._fix = bus._distance;
        bus._fixMs = now;
      }
    }
    _lastPingMs = now;
    notifyListeners();
  }

  /// Advances the GPS outage state; returns true when signal just came back.
  bool _updateGps(SimulatedBus bus) {
    if (bus._gpsLostTicks > 0) {
      bus._gpsLostTicks--;
      return bus._gpsLostTicks == 0;
    }
    if (bus.flakyGps && _random.nextDouble() < 0.03) {
      bus._gpsLostTicks = 15 + _random.nextInt(15);
    }
    return false;
  }

  void _drive(SimulatedBus bus, double dt) {
    // Gentle speed drift, like real traffic.
    bus._speed = (bus._speed + (_random.nextDouble() - 0.5) * 1.6).clamp(
      6.0,
      13.0,
    );
    final route = routeOf(bus);
    final from = bus._distance % route.length;
    final step = bus._speed * speedup * dt;
    var travelled = step;
    for (final s in _servedStops(bus)) {
      for (final at in [s.along, s.along + route.length]) {
        if (at > from && at <= from + step && at - from < travelled) {
          travelled = at - from;
        }
      }
    }
    bus._distance += travelled;
    if (travelled < step) {
      bus._dwell = _stopDwellSeconds;
      bus.occupancy = (bus.occupancy + _random.nextInt(31) - 15).clamp(5, 100);
    }
  }

  double _displayedDistance(SimulatedBus bus) {
    if (!bus.hasSignal) return bus._fix;
    final t = ((_clock.elapsedMilliseconds - _lastPingMs) / tick.inMilliseconds)
        .clamp(0.0, 1.0);
    return bus._previous + (bus._distance - bus._previous) * t;
  }

  LatLng positionOf(SimulatedBus bus) =>
      routeOf(bus).pointAt(_displayedDistance(bus));

  double bearingOf(SimulatedBus bus) =>
      routeOf(bus).bearingAt(_displayedDistance(bus));

  /// Seconds since the vehicle last reported its position.
  int secondsSinceFix(SimulatedBus bus) =>
      ((_clock.elapsedMilliseconds - bus._fixMs) / 1000).floor();

  /// Position of [bus] along its loop as a fraction 0..1.
  double progressOf(SimulatedBus bus) {
    final route = routeOf(bus);
    return (_displayedDistance(bus) % route.length) / route.length;
  }

  /// Regular buses of [lineId] (vans are listed by [vans]).
  Iterable<SimulatedBus> busesOf(String lineId) =>
      buses.where((b) => b.lineId == lineId && !b.isVan);

  Iterable<SimulatedBus> get vans => buses.where((b) => b.isVan);

  /// Stops [bus] halts at: every stop, or only accessible ones for vans.
  Iterable<RouteStop> _servedStops(SimulatedBus bus) => bus.isVan
      ? _stopsOnRoute[bus.lineId]!.where((s) => s.stop.accessible)
      : _stopsOnRoute[bus.lineId]!;

  /// Distance the app believes the bus has covered. Without signal we
  /// dead-reckon from the last fix at the average speed.
  double _believed(SimulatedBus bus) => bus.hasSignal
      ? bus._distance
      : bus._fix + secondsSinceFix(bus) * _avgSpeed * speedup * 0.8;

  double _secondsTo(SimulatedBus bus, double stopAlong) {
    final route = routeOf(bus);
    final here = _believed(bus) % route.length;
    final ahead = (stopAlong - here) % route.length;
    final stopsBetween = _stopsOnRoute[bus.lineId]!.where((s) {
      final d = (s.along - here) % route.length;
      return d > 1 && d < ahead - 1;
    }).length;
    return ahead / (_avgSpeed * speedup) +
        (bus.hasSignal ? bus._dwell : 0) +
        stopsBetween * _stopDwellSeconds;
  }

  /// The stop [bus] is standing at, if any.
  BusStop? currentStopOf(SimulatedBus bus) {
    if (!bus.isAtStop) return null;
    final route = routeOf(bus);
    final here = bus._distance % route.length;
    for (final s in _stopsOnRoute[bus.lineId]!) {
      final d = (here - s.along).abs();
      if (d < 2 || d > route.length - 2) return s.stop;
    }
    return null;
  }

  /// The next [count] stops of [bus] with arrival predictions.
  List<({BusStop stop, Eta eta})> upcomingStopsOf(
    SimulatedBus bus, {
    int count = 3,
  }) {
    final route = routeOf(bus);
    final here = _believed(bus) % route.length;
    final stops = _servedStops(bus).toList();
    final ordered = [
      ...stops.where((s) => s.along > here + 1),
      ...stops.where((s) => s.along <= here + 1),
    ];
    return [
      for (final s in ordered.take(count))
        (
          stop: s.stop,
          eta: Eta(_secondsTo(bus, s.along).round(), live: bus.hasSignal),
        ),
    ];
  }

  /// Next arrival of [lineId] at [stopId], or null if the line doesn't
  /// serve it.
  Eta? eta(String lineId, String stopId) {
    final entry = _stopsOnRoute[lineId]!
        .where((s) => s.stop.id == stopId)
        .firstOrNull;
    if (entry == null) return null;
    Eta? best;
    for (final bus in busesOf(lineId)) {
      final atThisStop = currentStopOf(bus)?.id == stopId && bus.hasSignal;
      final s = atThisStop ? 0 : _secondsTo(bus, entry.along).round();
      if (best == null || s < best.seconds) {
        best = Eta(s, live: bus.hasSignal);
      }
    }
    return best;
  }

  /// Bus of [lineId] that will reach [stopId] next.
  SimulatedBus? nextBusAt(String lineId, String stopId) {
    final entry = _stopsOnRoute[lineId]!
        .where((s) => s.stop.id == stopId)
        .firstOrNull;
    if (entry == null) return null;
    SimulatedBus? best;
    var bestS = double.infinity;
    for (final bus in busesOf(lineId)) {
      final s = _secondsTo(bus, entry.along);
      if (s < bestS) {
        bestS = s;
        best = bus;
      }
    }
    return best;
  }
}
