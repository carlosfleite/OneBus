import 'package:latlong2/latlong.dart';

import '../core/theme/app_colors.dart';
import '../models/bus_line.dart';
import '../models/bus_route.dart';
import '../models/bus_stop.dart';
import '../models/recharge_point.dart';
import 'route_geometry.dart';

/// Fictional bus network over real streets in Bauru-SP.
/// Replace with a real API / GTFS-realtime integration.
class MockData {
  MockData._();

  static const cityCenter = LatLng(-22.3220, -49.0600);

  /// Simulated device location (Vila Flores, near the 214/302 stops).
  static const userLocation = LatLng(-22.3163, -49.0628);

  static const List<BusLine> lines = [
    BusLine(
      id: 'l214',
      number: '214',
      name: 'Centro ↔ Unesp',
      color: AppColors.lineBlue,
      headwayMinutes: 12,
    ),
    BusLine(
      id: 'l302',
      number: '302',
      name: 'Centro ↔ Jardim Nova Nise',
      color: AppColors.lineGreen,
      headwayMinutes: 15,
    ),
    BusLine(
      id: 'l108',
      number: '108',
      name: 'Alto Sumaré ↔ Jardim Petrópolis',
      color: AppColors.lineIndigo,
      headwayMinutes: 20,
    ),
    BusLine(
      id: 'l057',
      number: '057',
      name: 'Vila Triagem ↔ Mary Dota',
      color: AppColors.lineOrange,
      headwayMinutes: 20,
      alert:
          'Obras na Rua Ivo Marcelino: ônibus com desvio pela rua paralela. '
          'Atrasos de até 5 min.',
    ),
  ];

  static final Map<String, BusRoute> routes = {
    for (final e in routeGeometry.entries) e.key: BusRoute(e.key, e.value),
  };

  // Stop coordinates were snapped to the route geometry; names are the
  // real streets at those points (OpenStreetMap reverse geocoding).
  static const _rawStops = [
    // Integration stops where several routes share the same street.
    (
      's17',
      'Integração Vila Coralina',
      'R. Dr. Alpheu Vasconcelos Sampaio',
      LatLng(-22.325300, -49.052430),
    ),
    (
      's18',
      'Integração Vista Alegre',
      'Parque Vista Alegre',
      LatLng(-22.311170, -49.062740),
    ),
    ('s1', 'Rua Aimorés', 'Vila Flores', LatLng(-22.314592, -49.061755)),
    ('s5', 'Rua Caetés', 'Vila Flores', LatLng(-22.317804, -49.063715)),
    (
      's2',
      'Rua Manuel de Camargo',
      'Vila Engler',
      LatLng(-22.329948, -49.048019),
    ),
    (
      's3',
      'Unesp · Av. Eng. Luiz E. Carrijo Coube',
      'Jardim Santos Dumont',
      LatLng(-22.347793, -49.031011),
    ),
    (
      's4',
      'Rua Dr. José Ranieri',
      'Jardim Marambá',
      LatLng(-22.325025, -49.041963),
    ),
    (
      's6',
      'Rua Manoel Bento da Cruz',
      'Vila Altinópolis',
      LatLng(-22.328272, -49.069920),
    ),
    (
      's7',
      'Rua Antônio Xavier de Mendonça',
      'Jardim Nova Nise',
      LatLng(-22.335952, -49.061957),
    ),
    (
      's8',
      'Rua Capitão Alcides',
      'Vila Coralina',
      LatLng(-22.324773, -49.054045),
    ),
    (
      's9',
      'Alameda Amor Perfeito',
      'Parque Alto Sumaré',
      LatLng(-22.309002, -49.062344),
    ),
    (
      's10',
      'Rua Maria José Losnak',
      'Parque São Geraldo',
      LatLng(-22.300962, -49.074865),
    ),
    (
      's11',
      'Rua Prof. José Torres Brito',
      'Jardim Petrópolis',
      LatLng(-22.311754, -49.085891),
    ),
    (
      's12',
      'Rua Antônio Alves',
      'Vila Camargo',
      LatLng(-22.316889, -49.071530),
    ),
    (
      's13',
      'Rod. Marechal Rondon',
      'Vila Conceição',
      LatLng(-22.311077, -49.056214),
    ),
    (
      's14',
      'Rua Alexandre Jorge Nasralla',
      'Mary Dota',
      LatLng(-22.301125, -49.045840),
    ),
    (
      's15',
      'Rua Waldemar Pereira da Silveira',
      'Mutirão Primavera',
      LatLng(-22.306084, -49.034183),
    ),
    (
      's16',
      'Rua Ivo Marcelino',
      'Vila Triagem',
      LatLng(-22.316094, -49.047610),
    ),
  ];

  /// Stops with ramp, tactile paving and room for wheelchairs.
  static const _accessibleStopIds = {
    's17', 's18', 's1', 's3', 's6', 's9', 's12', 's13', 's16', //
  };

  /// A stop is served by every line whose route passes within 40 m of it.
  static final List<BusStop> stops = [
    for (final (id, name, district, pos) in _rawStops)
      BusStop(
        id: id,
        name: name,
        address: district,
        position: pos,
        accessible: _accessibleStopIds.contains(id),
        lineIds: [
          for (final line in lines)
            if (routes[line.id]!.project(pos).offset < 40) line.id,
        ],
      ),
  ];

  /// Places to top up the pass (fictional, placed next to real stops).
  static const rechargePoints = [
    RechargePoint(
      id: 'r1',
      name: 'Terminal Vila Coralina',
      address: 'R. Dr. Alpheu Vasconcelos Sampaio',
      position: LatLng(-22.325050, -49.052700),
      kind: RechargeKind.terminal,
      opens: 5,
      closes: 23,
    ),
    RechargePoint(
      id: 'r2',
      name: 'Lotérica Vila Flores',
      address: 'Vila Flores',
      position: LatLng(-22.315200, -49.062200),
      kind: RechargeKind.loterica,
      opens: 8,
      closes: 18,
    ),
    RechargePoint(
      id: 'r3',
      name: 'Banca do Zé',
      address: 'Parque Alto Sumaré',
      position: LatLng(-22.309200, -49.062600),
      kind: RechargeKind.banca,
      opens: 6,
      closes: 20,
    ),
    RechargePoint(
      id: 'r4',
      name: 'Posto de Atendimento Unesp',
      address: 'Av. Eng. Luiz E. Carrijo Coube',
      position: LatLng(-22.347600, -49.031600),
      kind: RechargeKind.terminal,
      opens: 7,
      closes: 22,
    ),
    RechargePoint(
      id: 'r5',
      name: 'Farmácia Nova Nise',
      address: 'Jardim Nova Nise',
      position: LatLng(-22.335700, -49.062400),
      kind: RechargeKind.farmacia,
      opens: 0,
      closes: 0,
    ),
    RechargePoint(
      id: 'r6',
      name: 'Terminal Vista Alegre',
      address: 'Parque Vista Alegre',
      position: LatLng(-22.311300, -49.063000),
      kind: RechargeKind.terminal,
      opens: 5,
      closes: 23,
    ),
  ];

  static RechargePoint rechargePoint(String id) =>
      rechargePoints.firstWhere((r) => r.id == id);

  static BusLine line(String id) => lines.firstWhere((l) => l.id == id);

  static BusStop stop(String id) => stops.firstWhere((s) => s.id == id);

  /// The stop the user cares about for a line (first stop it serves).
  static BusStop homeStopFor(String lineId) =>
      stops.firstWhere((s) => s.lineIds.contains(lineId));
}
