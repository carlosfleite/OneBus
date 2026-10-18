import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'screens/splash_screen.dart';
import 'services/auth_store.dart';
import 'services/favorites_store.dart';
import 'services/notification_service.dart';
import 'services/pass_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    ThemeController.instance.load(),
    AuthStore.instance.load(),
    FavoritesStore.instance.load(),
    PassStore.instance.load(),
    NotificationService.instance.init(),
  ]);
  runApp(const OneBusApp());
}

class OneBusApp extends StatelessWidget {
  const OneBusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, mode, _) => MaterialApp(
        title: 'OneBus',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: mode,
        home: const SplashScreen(),
      ),
    );
  }
}
