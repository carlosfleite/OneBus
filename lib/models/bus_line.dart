import 'package:flutter/material.dart';

class BusLine {
  final String id;
  final String number;
  final String name;
  final Color color;

  /// Scheduled minutes between departures (used for the timetable).
  final int headwayMinutes;

  /// Service notice (detour, works…), shown on the line and its stops.
  final String? alert;

  const BusLine({
    required this.id,
    required this.number,
    required this.name,
    required this.color,
    required this.headwayMinutes,
    this.alert,
  });
}
