import 'package:latlong2/latlong.dart';

enum RechargeKind {
  terminal('Terminal'),
  loterica('Lotérica'),
  banca('Banca'),
  farmacia('Farmácia');

  final String label;

  const RechargeKind(this.label);
}

/// A place where the transit pass can be topped up.
class RechargePoint {
  final String id;
  final String name;
  final String address;
  final LatLng position;
  final RechargeKind kind;

  /// Opening hours (24h clock). [opens] == [closes] means always open.
  final int opens;
  final int closes;

  const RechargePoint({
    required this.id,
    required this.name,
    required this.address,
    required this.position,
    required this.kind,
    required this.opens,
    required this.closes,
  });

  bool get open24h => opens == closes;

  bool isOpenAt(DateTime t) => open24h || (t.hour >= opens && t.hour < closes);

  String get hoursLabel =>
      open24h ? '24 horas' : '${_h(opens)} às ${_h(closes)}';

  static String _h(int h) => '${h.toString().padLeft(2, '0')}h';
}
