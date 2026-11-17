import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:onebus/features/tour/tour_controller.dart';
import 'package:onebus/main.dart';
import 'package:onebus/services/auth_errors.dart';
import 'package:onebus/services/auth_store.dart';
import 'package:onebus/services/connectivity_service.dart';
import 'package:onebus/services/favorites_store.dart';
import 'package:onebus/services/feed_service.dart';
import 'package:onebus/services/password_rules.dart';

Future<void> _openApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  FavoritesStore.instance.notifyArrivals = false;
  FeedService.loadingDelay = Duration.zero;
  SharedPreferences.setMockInitialValues({});
  await AuthStore.instance.createAccount(
    name: 'Duda',
    email: 'duda@exemplo.com',
    password: 'Senha@123',
  );
  await tester.pumpWidget(const OneBusApp());
  await tester.pump(const Duration(seconds: 3));
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  group('PasswordRules', () {
    test('accepts a strong password and rejects weak ones', () {
      expect(PasswordRules.isStrong('Senha@123'), isTrue);
      expect(PasswordRules.isStrong('senha@123'), isFalse); // no uppercase
      expect(PasswordRules.isStrong('SENHA@123'), isFalse); // no lowercase
      expect(PasswordRules.isStrong('Senha@abc'), isFalse); // no number
      expect(PasswordRules.isStrong('Senha1234'), isFalse); // no symbol
      expect(PasswordRules.isStrong('Se@1'), isFalse); // too short
      expect(PasswordRules.validate('Senha@123'), isNull);
      expect(PasswordRules.validate(''), isNotNull);
    });

    test('check reports each requirement', () {
      final checks = PasswordRules.check('abc');
      expect(checks.length, 5);
      expect(checks.where((c) => c.ok).length, 1); // only lowercase
    });
  });

  group('AuthErrors', () {
    test('translates Supabase failures to Portuguese', () {
      expect(
        AuthErrors.humanize(
          const AuthApiException(
            'Invalid login credentials',
            statusCode: '400',
            code: 'invalid_credentials',
          ),
        ),
        'E-mail ou senha incorretos.',
      );
      expect(
        AuthErrors.humanize(
          const AuthApiException(
            'User already registered',
            statusCode: '422',
            code: 'user_already_exists',
          ),
        ),
        contains('já está cadastrado'),
      );
      expect(
        AuthErrors.humanize(
          const AuthApiException(
            'Email rate limit exceeded',
            statusCode: '429',
            code: 'over_email_send_rate_limit',
          ),
        ),
        contains('Muitas tentativas'),
      );
      expect(
        AuthErrors.humanize(
          const AuthApiException(
            'Password should be at least 6 characters',
            statusCode: '422',
            code: 'weak_password',
          ),
        ),
        contains('Senha fraca'),
      );
      expect(
        AuthErrors.humanize(Exception('Failed host lookup: x.supabase.co')),
        AuthErrors.offline,
      );
      expect(AuthErrors.humanize(Exception('???')), AuthErrors.generic);
    });
  });

  group('without Supabase configured', () {
    test(
      'uses the local account and says recovery needs an online one',
      () async {
        expect(AuthStore.instance.usesBackend, isFalse);
        expect(
          await AuthStore.instance.sendPasswordReset('a@b.com'),
          AuthStore.recoveryUnavailable,
        );
      },
    );
  });

  testWidgets('first access runs the guided tour; Pular ends it for good', (
    tester,
  ) async {
    TourController.instance
      ..done = false
      ..active = false;
    await _openApp(tester);
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('1/5'), findsOneWidget);
    expect(find.text('Início'), findsWidgets);
    await tester.tap(find.text('Próximo'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('2/5'), findsOneWidget);
    // The button labels must stay on one line.
    expect(tester.getSize(find.text('Anterior')).height, lessThan(30));
    expect(tester.getSize(find.text('Próximo')).height, lessThan(30));
    await tester.tap(find.text('Anterior'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('1/5'), findsOneWidget);

    await tester.tap(find.text('Pular'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('1/5'), findsNothing);
    expect(TourController.instance.done, isTrue);
  });

  testWidgets('the offline strip appears when the connection drops', (
    tester,
  ) async {
    TourController.instance.skipForTests();
    await _openApp(tester);
    expect(find.textContaining('Sem conexão'), findsNothing);

    ConnectivityService.instance.online.value = false;
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Sem conexão'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsOneWidget);

    ConnectivityService.instance.online.value = true;
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Sem conexão'), findsNothing);
  });

  testWidgets('Rever tour do app is offered in Conta', (tester) async {
    TourController.instance.skipForTests();
    await _openApp(tester);
    // Open the account sheet from the home avatar.
    await tester.tap(find.text('D').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Rever tour do app'), findsOneWidget);
    await tester.ensureVisible(find.text('Rever tour do app'));
    await tester.pump();
    await tester.tap(find.text('Rever tour do app'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(TourController.instance.active, isTrue);
    expect(find.text('1/5'), findsOneWidget);
  });
}
