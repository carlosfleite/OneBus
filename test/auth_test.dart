import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:onebus/main.dart';
import 'package:onebus/services/auth_store.dart';
import 'package:onebus/services/favorites_store.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthStore.instance.deleteAccount();
    FavoritesStore.instance.notifyArrivals = false;
  });

  test('session is remembered until logout', () async {
    final auth = AuthStore.instance;
    await auth.createAccount(
      name: 'Maria Souza',
      email: 'Maria@Exemplo.com',
      password: 'segredo1',
    );
    expect(auth.firstName, 'Maria');

    // "Restart": reload from storage, still logged in.
    await auth.load();
    expect(auth.loggedIn, isTrue);

    await auth.logout();
    await auth.load();
    expect(auth.loggedIn, isFalse);
    expect(auth.hasAccount, isTrue);

    expect(await auth.login('maria@exemplo.com', 'errada'), isNotNull);
    expect(await auth.login('maria@exemplo.com', 'segredo1'), isNull);
    expect(auth.loggedIn, isTrue);
  });

  test('password is not stored in plain text', () async {
    await AuthStore.instance.createAccount(
      name: 'Ana',
      email: 'ana@exemplo.com',
      password: 'minhasenha',
    );
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys()) {
      expect('${prefs.get(key)}', isNot(contains('minhasenha')));
    }
  });

  testWidgets('first launch asks to create an account, then opens the app', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const OneBusApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Crie sua conta'), findsOneWidget);

    final fields = find.byType(CupertinoTextField);
    await tester.enterText(fields.at(0), 'Duda');
    await tester.enterText(fields.at(1), 'duda@exemplo.com');
    await tester.enterText(fields.at(2), '123');
    await tester.tap(find.text('Criar conta'));
    await tester.pump();
    expect(
      find.text('A senha precisa ter pelo menos 6 caracteres.'),
      findsOneWidget,
    );

    await tester.enterText(fields.at(2), '123456');
    await tester.tap(find.text('Criar conta'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Olá, Duda'), findsOneWidget);
    expect(find.text('Seus ônibus'), findsOneWidget);
  });
}
