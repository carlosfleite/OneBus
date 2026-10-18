import 'package:flutter_test/flutter_test.dart';

import 'package:onebus/data/mock_data.dart';
import 'package:onebus/services/alerts_center.dart';
import 'package:onebus/services/bus_simulator.dart';
import 'package:onebus/services/favorites_store.dart';
import 'package:onebus/services/nearby.dart';

void main() {
  test('favorite line approaching a favorite stop notifies once', () {
    final favs = FavoritesStore.instance;
    final alerts = AlertsCenter.instance;
    expect(favs.watchedPairs, isNotEmpty);

    // Every bus counts as "arriving" with a very wide window.
    favs.notifyMinutes = 10000;
    alerts.check(BusSimulator.instance);
    expect(alerts.banner.value?.title, contains('chegando no seu ponto'));

    // Same buses on the next ping: no repeated notification.
    alerts.dismiss();
    alerts.check(BusSimulator.instance);
    expect(alerts.banner.value, isNull);

    // Turned off: nothing fires.
    favs.notifyArrivals = false;
    alerts.check(BusSimulator.instance);
    expect(alerts.banner.value, isNull);
  });

  test('nearest stop is the closest of all stops', () {
    final all = stopsByDistance();
    expect(all.length, MockData.stops.length);
    expect(nearestStop().stop.id, all.first.stop.id);
    for (final n in all) {
      expect(n.meters, greaterThanOrEqualTo(all.first.meters));
    }
    expect(nearestStop().walkMinutes, greaterThan(0));
  });
}
