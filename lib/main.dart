import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/tour/tour_controller.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_store.dart';
import 'services/connectivity_service.dart';
import 'services/favorites_store.dart';
import 'services/notification_service.dart';
import 'services/pass_store.dart';
import 'widgets/app_chrome.dart';
import 'widgets/ds/app_toast.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Clean URLs (no "#/"): the Supabase links put their tokens in the hash
  // fragment, which the router must leave alone.
  usePathUrlStrategy();
  await AuthStore.instance.initBackend();
  await Future.wait([
    ThemeController.instance.load(),
    AuthStore.instance.load(),
    FavoritesStore.instance.load(),
    PassStore.instance.load(),
    TourController.instance.load(),
    NotificationService.instance.init(),
    ConnectivityService.instance.init(),
  ]);
  runApp(const OneBusApp());
}

class OneBusApp extends StatefulWidget {
  const OneBusApp({super.key});

  @override
  State<OneBusApp> createState() => _OneBusAppState();
}

class _OneBusAppState extends State<OneBusApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    AuthStore.instance.recoveryPending.addListener(_onRecovery);
  }

  @override
  void dispose() {
    AuthStore.instance.recoveryPending.removeListener(_onRecovery);
    super.dispose();
  }

  /// The user opened the recovery link while the app was already running.
  void _onRecovery() {
    if (!AuthStore.instance.recoveryPending.value || !SplashScreen.finished) {
      return;
    }
    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const ResetPasswordScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, mode, _) => MaterialApp(
        title: 'OneBus',
        debugShowCheckedModeBanner: false,
        navigatorKey: _navigatorKey,
        scaffoldMessengerKey: AppToast.messengerKey,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: mode,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => AppChrome(child: child!),
        home: const SplashScreen(),
      ),
    );
  }
}
