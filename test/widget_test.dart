import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:onebus/data/mock_data.dart';
import 'package:onebus/main.dart';
import 'package:onebus/services/auth_store.dart';
import 'package:onebus/services/favorites_store.dart';
import 'package:onebus/models/bus_route.dart';
import 'package:onebus/services/bus_simulator.dart';

void main() {
  testWidgets(
    'splash shows the slogan, then account creation on first launch',
    (WidgetTester tester) async {
      FavoritesStore.instance.notifyArrivals = false;
      SharedPreferences.setMockInitialValues({});
      await AuthStore.instance.deleteAccount();
      await tester.pumpWidget(const OneBusApp());
      await tester.pump(const Duration(milliseconds: 2400));
      expect(find.text('Tudo sobre ônibus em um lugar só.'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('Crie sua conta'), findsOneWidget);
    },
  );

  test('BusRoute walks and projects along its geometry', () {
    final route = BusRoute('t', const [
      LatLng(0, 0),
      LatLng(0, 0.01),
      LatLng(0.01, 0.01),
    ]);
    expect(route.length, closeTo(1113 + 1106, 5));
    // Heading east on the first leg, north on the second.
    expect(route.bearingAt(300), closeTo(90, 1));
    expect(route.bearingAt(1800), closeTo(0, 1));
    expect(route.project(const LatLng(0.0001, 0.005)).offset, closeTo(11, 1));
  });

  test('every stop is served by at least one line with a live ETA', () {
    for (final stop in MockData.stops) {
      expect(stop.lineIds, isNotEmpty, reason: stop.name);
      for (final lineId in stop.lineIds) {
        final eta = BusSimulator.instance.eta(lineId, stop.id);
        expect(eta, isNotNull);
        expect(eta!.live, isTrue);
      }
    }
  });
}
