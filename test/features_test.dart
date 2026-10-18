import 'package:flutter_test/flutter_test.dart';

import 'package:onebus/data/mock_data.dart';
import 'package:onebus/services/alerts_center.dart';
import 'package:onebus/services/bus_simulator.dart';
import 'package:onebus/services/nearby.dart';
import 'package:onebus/services/pass_store.dart';

void main() {
  test('some stops are accessible, some are not', () {
    expect(MockData.stops.where((s) => s.accessible), isNotEmpty);
    expect(MockData.stops.where((s) => !s.accessible), isNotEmpty);
  });

  test('vans are accessible and kept out of bus arrival predictions', () {
    final sim = BusSimulator.instance;
    expect(sim.vans, isNotEmpty);
    for (final van in sim.vans) {
      expect(van.accessible, isTrue);
      expect(sim.busesOf(van.lineId), isNot(contains(van)));
      expect(
        sim.upcomingStopsOf(van, count: 3).every((u) => u.stop.accessible),
        isTrue,
      );
    }
  });

  test('recharge points are listed nearest first', () {
    final all = rechargeByDistance();
    expect(all.length, MockData.rechargePoints.length);
    for (final n in all) {
      expect(n.meters, greaterThanOrEqualTo(all.first.meters));
    }
    expect(MockData.rechargePoints.any((r) => r.open24h), isTrue);
  });

  test('pass warns once when the balance runs low, again when it runs out', () {
    final pass = PassStore.instance;
    final alerts = AlertsCenter.instance;
    pass.value = 16;
    pass.recharge(0);
    alerts.dismiss();

    pass.chargeFare(); // 11,00: still fine
    expect(alerts.banner.value, isNull);

    pass.chargeFare(); // 6,00: running out
    expect(alerts.banner.value?.title, 'Seu passe está acabando');
    alerts.dismiss();

    pass.chargeFare(); // 1,00: no trip left
    expect(alerts.banner.value?.title, 'Seu passe acabou');
    alerts.dismiss();

    pass.recharge(20); // back to normal, warns again next time
    expect(pass.isLow, isFalse);
    pass.value = 6;
    pass.recharge(10);
    pass.chargeFare();
    pass.chargeFare(); // 6,00
    expect(alerts.banner.value?.title, 'Seu passe está acabando');
    alerts.dismiss();
  });
}
