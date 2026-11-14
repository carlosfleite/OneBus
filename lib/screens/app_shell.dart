import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../features/tour/tour_controller.dart';
import '../features/tour/tour_overlay.dart';
import '../services/alerts_center.dart';
import '../services/bus_simulator.dart';
import '../services/feed_service.dart';
import '../services/pass_store.dart';
import '../widgets/glass.dart';
import 'favorites_tab.dart';
import 'home_tab.dart';
import 'map_home.dart';
import 'pass_screen.dart';
import 'sheet/sheet_nav.dart';
import 'stops_tab.dart';

enum AppTab { home, map, stops, pass, favorites }

/// Lets any tab switch tabs or open something on the live map.
class AppNav extends InheritedWidget {
  final void Function(AppTab tab) select;
  final void Function(SheetPage page) openOnMap;

  const AppNav({
    super.key,
    required this.select,
    required this.openOnMap,
    required super.child,
  });

  static AppNav of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppNav>()!;

  @override
  bool updateShouldNotify(AppNav oldWidget) => false;
}

/// Tabbed app: Início · Mapa · Pontos · Passe · Favoritos.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _sim = BusSimulator.instance;
  final _mapKey = GlobalKey<MapHomeState>();
  final _tabKeys = {for (final t in AppTab.values) t: GlobalKey()};
  AppTab _tab = AppTab.home;

  late final _tourSteps = [
    TourStep(
      icon: Icons.home_rounded,
      title: 'Início',
      body:
          'Seus ônibus favoritos, o ponto mais próximo de você e os avisos '
          'de desvios e obras, tudo logo ao abrir o app.',
      target: _tabKeys[AppTab.home]!,
    ),
    TourStep(
      icon: Icons.map_rounded,
      title: 'Mapa ao vivo',
      body:
          'Acompanhe os ônibus em tempo real. Toque em um ônibus, linha ou '
          'ponto para ver a chegada, a lotação e o trajeto.',
      target: _tabKeys[AppTab.map]!,
    ),
    TourStep(
      icon: Icons.location_on_rounded,
      title: 'Pontos',
      body:
          'Todos os pontos, do mais próximo ao mais distante, com a próxima '
          'chegada de cada linha. Toque na estrela para favoritar.',
      target: _tabKeys[AppTab.stops]!,
    ),
    TourStep(
      icon: Icons.credit_card_rounded,
      title: 'Passe',
      body:
          'Veja o saldo, as últimas viagens e recarregue o passe. Também '
          'mostramos os pontos de recarga mais perto de você.',
      target: _tabKeys[AppTab.pass]!,
    ),
    TourStep(
      icon: Icons.star_rounded,
      title: 'Favoritos e avisos',
      body:
          'Escolha as linhas e os pontos que você usa e receba um aviso '
          'quando o ônibus estiver chegando.',
      target: _tabKeys[AppTab.favorites]!,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // The shell keeps the live feed running on every tab so arrival
    // notifications fire wherever the user is.
    _sim.addListener(_onPing);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Warn right away when the pass is already running out.
      PassStore.instance.checkOnLaunch();
      FeedService.instance.refresh();
      // First access: guided tour (after the screen settles).
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (mounted) TourController.instance.startIfFirstTime();
      });
    });
  }

  @override
  void dispose() {
    _sim.removeListener(_onPing);
    super.dispose();
  }

  void _onPing() => AlertsCenter.instance.check(_sim);

  void _select(AppTab tab) => setState(() => _tab = tab);

  void _openOnMap(SheetPage page) {
    _select(AppTab.map);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _mapKey.currentState?.openPage(page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final tabs = <AppTab, Widget>{
      AppTab.home: const HomeTab(),
      AppTab.map: MapHome(key: _mapKey),
      AppTab.stops: const StopsTab(),
      AppTab.pass: const PassScreen(),
      AppTab.favorites: const FavoritesTab(),
    };

    return AppNav(
      select: _select,
      openOnMap: _openOnMap,
      child: Stack(
        children: [
          Scaffold(
            body: Stack(
              children: [
                IndexedStack(
                  index: _tab.index,
                  children: [
                    for (final t in AppTab.values)
                      TickerMode(enabled: t == _tab, child: tabs[t]!),
                  ],
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  top: mq.padding.top + 8,
                  child: BannerHost(
                    listenable: AlertsCenter.instance.banner,
                    onTap: AlertsCenter.instance.dismiss,
                  ),
                ),
              ],
            ),
            bottomNavigationBar: _AppTabBar(
              current: _tab,
              onSelect: _select,
              keys: _tabKeys,
            ),
          ),
          ListenableBuilder(
            listenable: TourController.instance,
            builder: (context, _) => TourController.instance.active
                ? Positioned.fill(
                    child: TourOverlay(
                      steps: _tourSteps,
                      onStep: (i) => _select(AppTab.values[i]),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Black bottom bar; the active tab gets a yellow pill.
class _AppTabBar extends StatelessWidget {
  final AppTab current;
  final ValueChanged<AppTab> onSelect;
  final Map<AppTab, GlobalKey> keys;

  const _AppTabBar({
    required this.current,
    required this.onSelect,
    required this.keys,
  });

  static const _items = {
    AppTab.home: (Icons.home_outlined, Icons.home_rounded, 'Início'),
    AppTab.map: (Icons.map_outlined, Icons.map_rounded, 'Mapa'),
    AppTab.stops: (
      Icons.location_on_outlined,
      Icons.location_on_rounded,
      'Pontos',
    ),
    AppTab.pass: (Icons.credit_card_outlined, Icons.credit_card_rounded, 'Passe'),
    AppTab.favorites: (
      Icons.star_outline_rounded,
      Icons.star_rounded,
      'Favoritos',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.only(bottom: bottom),
      decoration: BoxDecoration(
        color: p.ink,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 18)],
      ),
      child: SizedBox(
        height: 68,
        child: Row(
          children: [
            for (final e in _items.entries)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: e.key == current,
                  label: e.value.$3,
                  child: GestureDetector(
                    key: ValueKey('tab-${e.key.name}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelect(e.key),
                    child: Center(
                      child: Column(
                        key: keys[e.key],
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            width: e.key == current ? 58 : 40,
                            height: 32,
                            decoration: BoxDecoration(
                              color: e.key == current
                                  ? p.accent
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              e.key == current ? e.value.$2 : e.value.$1,
                              size: 24,
                              color: e.key == current
                                  ? p.onAccent
                                  : const Color(0xFFA1A1AA),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            e.value.$3,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: e.key == current
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: e.key == current
                                  ? Colors.white
                                  : const Color(0xFFA1A1AA),
                            ),
                          ),
                        ],
                      ),
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
