import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_colors.dart';
import '../services/connectivity_service.dart';
import '../services/pwa_platform.dart';
import 'onebus_logo.dart';

/// Wraps the whole app (placed in `MaterialApp.builder`):
///  * on wide screens (desktop browser) shows the app in a centered,
///    phone-sized column;
///  * shows a slim "offline" strip when the connection drops;
///  * on Safari for iPhone, a hint on how to install the PWA.
class AppChrome extends StatefulWidget {
  final Widget child;

  /// Widest the app column gets on a large screen.
  static const maxAppWidth = 440.0;

  const AppChrome({super.key, required this.child});

  @override
  State<AppChrome> createState() => _AppChromeState();
}

class _AppChromeState extends State<AppChrome> with WidgetsBindingObserver {
  Timer? _timer;
  int _ticks = 0;

  Widget get child => widget.child;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // On iOS the safe-area values can arrive a moment after the first
    // frame: read them again for a few seconds.
    _timer = Timer.periodic(const Duration(milliseconds: 500), (t) {
      if (!mounted || ++_ticks > 12) {
        t.cancel();
        return;
      }
      setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > 560;
        final mq = MediaQuery.of(context);
        final width = wide ? AppChrome.maxAppWidth : c.maxWidth;
        // iOS PWA: use the safe-area insets measured by the page when
        // Flutter didn't report any (notch, Dynamic Island, home bar).
        final inset = webSafeInsets;
        EdgeInsets merge(EdgeInsets e) => EdgeInsets.fromLTRB(
          e.left > inset.left ? e.left : inset.left,
          e.top > inset.top ? e.top : inset.top,
          e.right > inset.right ? e.right : inset.right,
          e.bottom > inset.bottom ? e.bottom : inset.bottom,
        );
        final app = MediaQuery(
          data: mq.copyWith(
            size: Size(width, c.maxHeight),
            padding: wide ? mq.padding : merge(mq.padding),
            viewPadding: wide ? mq.viewPadding : merge(mq.viewPadding),
          ),
          child: _AppColumn(child: child),
        );
        if (!wide) return app;
        return ColoredBox(
          color: AppColors.brandInk,
          child: Row(
            children: [
              if (c.maxWidth > 980)
                const Expanded(child: _DesktopSide())
              else
                const Spacer(),
              Container(
                width: width,
                decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: ClipRect(child: app),
              ),
              const Spacer(),
            ],
          ),
        );
      },
    );
  }
}

class _DesktopSide extends StatelessWidget {
  const _DesktopSide();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OneBusLogo(size: 72),
          const SizedBox(height: 24),
          const OneBusWordmark(fontSize: 40, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            'Tudo sobre ônibus em um lugar só.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.brandYellow,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Abra no celular para a melhor experiência.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

/// Offline strip + install hint around the app content.
class _AppColumn extends StatelessWidget {
  final Widget child;

  const _AppColumn({required this.child});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: ConnectivityService.instance.online,
            builder: (context, online, _) => Column(
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: online
                      ? const SizedBox(width: double.infinity)
                      : _OfflineStrip(topInset: mq.padding.top),
                ),
                Expanded(
                  child: MediaQuery(
                    // The strip already covers the status bar area.
                    data: online
                        ? mq
                        : mq.copyWith(
                            padding: mq.padding.copyWith(top: 0),
                            viewPadding: mq.viewPadding.copyWith(top: 0),
                          ),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
          const Positioned(left: 12, right: 12, bottom: 0, child: _InstallHint()),
        ],
      ),
    );
  }
}

class _OfflineStrip extends StatelessWidget {
  final double topInset;

  const _OfflineStrip({required this.topInset});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: AppColors.orange,
        padding: EdgeInsets.fromLTRB(16, topInset + 8, 8, 8),
        child: Row(
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 18,
              color: AppColors.brandInk,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Sem conexão. Alguns dados podem estar desatualizados.',
                style: text.labelMedium?.copyWith(
                  color: AppColors.brandInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brandInk,
                minimumSize: const Size(48, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: ConnectivityService.instance.refresh,
              child: const Text('Tentar de novo'),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Add to Home Screen" hint, shown only in Safari on iPhone/iPad and only
/// until the user dismisses it (or installs the app).
class _InstallHint extends StatefulWidget {
  const _InstallHint();

  @override
  State<_InstallHint> createState() => _InstallHintState();
}

class _InstallHintState extends State<_InstallHint> {
  static const _key = 'install_hint_dismissed';
  bool _show = false;
  Timer? _timer;

  /// Only Safari on iPhone/iPad, and only until the app is installed.
  final _eligible = isIosSafariBrowser && !isStandalone;

  @override
  void initState() {
    super.initState();
    if (_eligible) _maybeShow();
  }

  Future<void> _maybeShow() async {
    var dismissed = false;
    try {
      dismissed = (await SharedPreferences.getInstance()).getBool(_key) ?? false;
    } catch (_) {}
    if (dismissed || !mounted) return;
    // Wait a little so it doesn't compete with the opening animation.
    _timer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _show = true);
    });
  }

  Future<void> _dismiss() async {
    setState(() => _show = false);
    try {
      await (await SharedPreferences.getInstance()).setBool(_key, true);
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_eligible) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    final bottom = MediaQuery.of(context).padding.bottom;
    return AnimatedSlide(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      offset: _show ? Offset.zero : const Offset(0, 1.3),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: _show ? 1 : 0,
        child: IgnorePointer(
          ignoring: !_show,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottom + 12),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              decoration: BoxDecoration(
                color: AppColors.brandInk,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.brandYellow, width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Color(0x55000000), blurRadius: 24),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const OneBusLogo(size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Instale o OneBus',
                          style: text.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text.rich(
                          TextSpan(
                            style: text.bodySmall?.copyWith(
                              color: Colors.white70,
                              height: 1.4,
                            ),
                            children: const [
                              TextSpan(text: 'Toque em '),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Icon(
                                  Icons.ios_share_rounded,
                                  size: 17,
                                  color: AppColors.brandYellow,
                                ),
                              ),
                              TextSpan(
                                text: ' Compartilhar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(text: ' e depois em '),
                              TextSpan(
                                text: 'Adicionar à Tela de Início',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(text: '.'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // No tooltip here: this layer lives above the Navigator, so
                  // there is no Overlay for it.
                  Semantics(
                    button: true,
                    label: 'Fechar',
                    child: IconButton(
                      onPressed: _dismiss,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
