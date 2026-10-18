import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../services/alerts_center.dart';
import '../services/bus_simulator.dart';
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
  AppTab _tab = AppTab.home;

  @override
  void initState() {
    super.initState();
    // The shell keeps the live feed running on every tab so arrival
    // notifications fire wherever the user is.
    _sim.addListener(_onPing);
    // Warn right away when the pass is already running out.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => PassStore.instance.checkOnLaunch(),
    );
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
      child: Scaffold(
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
        bottomNavigationBar: _IosTabBar(current: _tab, onSelect: _select),
      ),
    );
  }
}

class _IosTabBar extends StatelessWidget {
  final AppTab current;
  final ValueChanged<AppTab> onSelect;

  const _IosTabBar({required this.current, required this.onSelect});

  static const _items = {
    AppTab.home: (CupertinoIcons.house, CupertinoIcons.house_fill, 'Início'),
    AppTab.map: (CupertinoIcons.map, CupertinoIcons.map_fill, 'Mapa'),
    AppTab.stops: (
      CupertinoIcons.placemark,
      CupertinoIcons.placemark_fill,
      'Pontos',
    ),
    AppTab.pass: (
      CupertinoIcons.creditcard,
      CupertinoIcons.creditcard_fill,
      'Passe',
    ),
    AppTab.favorites: (
      CupertinoIcons.star,
      CupertinoIcons.star_fill,
      'Favoritos',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final ios = IosColors.of(context);
    final bottom = MediaQuery.of(context).padding.bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: EdgeInsets.only(bottom: bottom),
          decoration: BoxDecoration(
            color: ios.sheet,
            border: Border(top: BorderSide(color: ios.separator, width: 0.5)),
          ),
          child: SizedBox(
            height: 54,
            child: Row(
              children: [
                for (final e in _items.entries)
                  Expanded(
                    child: GestureDetector(
                      key: ValueKey('tab-${e.key.name}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelect(e.key),
                      child: Semantics(
                        button: true,
                        selected: e.key == current,
                        label: e.value.$3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              e.key == current ? e.value.$2 : e.value.$1,
                              size: 25,
                              color: e.key == current
                                  ? ios.tint
                                  : ios.secondaryLabel,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              e.value.$3,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: e.key == current
                                    ? ios.tint
                                    : ios.secondaryLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
