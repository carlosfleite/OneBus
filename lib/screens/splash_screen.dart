import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../widgets/onebus_logo.dart';
import '../services/auth_store.dart';
import 'app_shell.dart';
import 'auth_screen.dart';

/// Opening sequence: the icon springs in, the "1" route draws itself, a bus
/// runs along it, then the wordmark and slogan settle in before the map.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _iconSize = 112.0;

  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward().whenComplete(_goHome);

  Animation<double> _interval(
    double a,
    double b, [
    Curve curve = Curves.easeOutCubic,
  ]) => CurvedAnimation(
    parent: _c,
    curve: Interval(a, b, curve: curve),
  );

  late final _iconIn = _interval(0, 0.28, Curves.easeOutBack);
  late final _draw = _interval(0.16, 0.48, Curves.easeInOutCubic);
  late final _stations = _interval(0.42, 0.58, Curves.elasticOut);
  late final _bus = _interval(0.30, 0.62, Curves.easeInOut);
  late final _word = _interval(0.46, 0.72);
  late final _slogan = _interval(0.60, 0.86);

  void _goHome() {
    if (!mounted) return;
    // Only the first access (or after "Sair") goes through the account
    // screen; otherwise straight into the app.
    replaceWith(
      context,
      AuthStore.instance.loggedIn ? const AppShell() : const AuthScreen(),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondary = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: _iconIn.value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.6 + 0.4 * _iconIn.value,
                      child: _AnimatedIcon(
                        size: _iconSize,
                        draw: _draw.value,
                        stations: _stations.value,
                        bus: _bus.value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Opacity(
                    opacity: _word.value,
                    child: Transform.translate(
                      offset: Offset(0, 14 * (1 - _word.value)),
                      child: const OneBusWordmark(fontSize: 40),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Opacity(
                    opacity: _slogan.value,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - _slogan.value)),
                      child: Text(
                        'Tudo sobre ônibus em um lugar só.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: secondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 40,
              child: Opacity(
                opacity: _slogan.value,
                child: Text(
                  'Bauru · SP',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: secondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The logo plus a small bus dot that travels along the route as it draws.
class _AnimatedIcon extends StatelessWidget {
  final double size;
  final double draw;
  final double stations;
  final double bus;

  const _AnimatedIcon({
    required this.size,
    required this.draw,
    required this.stations,
    required this.bus,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = OneBusLogoPainter.routePath(
      Size.square(size),
    ).computeMetrics().toList();
    final total = metrics.fold<double>(0, (a, m) => a + m.length);
    var d = total * bus.clamp(0.0, 1.0);
    Tangent? at;
    for (final m in metrics) {
      if (d <= m.length) {
        at = m.getTangentForOffset(d);
        break;
      }
      d -= m.length;
    }
    final visible = bus > 0 && bus < 1;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.225),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          OneBusLogo(size: size, draw: draw, stations: stations),
          if (visible && at != null)
            Positioned(
              left: at.position.dx - 6,
              top: at.position.dy - 6,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.brandInk, width: 2.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
