import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:onebus/main.dart';
import 'package:onebus/services/auth_store.dart';
import 'package:onebus/services/favorites_store.dart';

Future<void> _openApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  // Arrival notifications are covered in alerts_test; keep banners (and
  // their dismiss timers) out of the UI tests.
  FavoritesStore.instance.notifyArrivals = false;
  SharedPreferences.setMockInitialValues({});
  await AuthStore.instance.createAccount(
    name: 'Duda',
    email: 'duda@exemplo.com',
    password: '123456',
  );
  await tester.pumpWidget(const OneBusApp());
  await tester.pump(const Duration(seconds: 3));
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _tab(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(ValueKey('tab-$name')));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('home tab shows the map greeting and favorite buses', (
    tester,
  ) async {
    await _openApp(tester);
    expect(find.text('Olá, Duda'), findsOneWidget);
    expect(find.text('Seus ônibus'), findsOneWidget);
    expect(find.text('Centro ↔ Unesp'), findsOneWidget);
  });

  testWidgets('stops tab lists every stop with the nearest first', (
    tester,
  ) async {
    await _openApp(tester);
    await _tab(tester, 'stops');
    expect(find.text('Mais próximo de você'), findsOneWidget);
    expect(find.text('Todos os pontos'), findsOneWidget);
  });

  testWidgets('opening a stop from the stops tab shows it on the map', (
    tester,
  ) async {
    await _openApp(tester);
    await _tab(tester, 'stops');
    await tester.tap(find.text('Rua Caetés').first);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Chegadas'), findsOneWidget);
  });

  testWidgets('line and bus pages render on the map tab', (tester) async {
    await _openApp(tester);
    await _tab(tester, 'map');
    await tester.enterText(find.byType(CupertinoSearchTextField), '214');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Centro ↔ Unesp').last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Itinerário'), findsOneWidget);

    await tester.tap(find.text('Próximo ônibus'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Próximas paradas'), findsOneWidget);
  });

  testWidgets('favorites tab shows notification settings', (tester) async {
    await _openApp(tester);
    await _tab(tester, 'favorites');
    expect(find.text('Avisar quando estiver chegando'), findsOneWidget);
    expect(find.text('Monitorando agora'), findsOneWidget);
  });
}
