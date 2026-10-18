import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme/app_colors.dart';
import '../data/mock_data.dart';
import '../services/alerts_center.dart';
import '../services/nearby.dart';
import '../services/bus_simulator.dart';
import '../services/favorites_store.dart';
import '../widgets/bus_marker.dart';
import '../widgets/glass.dart';
import '../widgets/ios.dart';
import '../widgets/map_layers.dart';
import '../widgets/recharge_widgets.dart';
import 'app_shell.dart';
import 'settings_sheet.dart';
import 'sheet/bus_sheet.dart';
import 'sheet/home_sheet.dart';
import 'sheet/line_sheet.dart';
import 'sheet/recharge_sheet.dart';
import 'sheet/sheet_nav.dart';
import 'sheet/stop_sheet.dart';

/// "Mapa" tab: the live map with a draggable card (or a side panel on wide
/// screens) that drives it.
class MapHome extends StatefulWidget {
  const MapHome({super.key});

  @override
  State<MapHome> createState() => MapHomeState();
}

class MapHomeState extends State<MapHome>
    with SingleTickerProviderStateMixin
    implements SheetNav {
  static const _wideBreakpoint = 720.0;
  static const _panelWidth = 380.0;
  static const _snapSizes = [0.12, 0.42, 0.92];
  static const _followZoom = 16.5;
  static const _flyDuration = Duration(milliseconds: 900);

  final _sim = BusSimulator.instance;
  final _alerts = AlertsCenter.instance;
  final _favs = FavoritesStore.instance;

  final _map = MapController();
  final _sheet = DraggableScrollableController();
  final _panelScroll = ScrollController();
  final _frame = ValueNotifier<int>(0);
  late final Ticker _ticker;

  @override
  final search = TextEditingController();
  @override
  final searchFocus = FocusNode();

  final _stack = <SheetPage>[const HomePage()];
  SheetPage get _page => _stack.last;

  bool _mapReady = false;
  bool _wide = false;
  Size _screen = Size.zero;
  Duration _now = Duration.zero;

  // Camera animation: fly towards a (possibly moving) target.
  LatLng Function()? _camTarget;
  double _camZoom = 14;
  Duration? _camStart;
  LatLng? _camFrom;
  double? _camFromZoom;
  bool _following = false;

  @override
  void initState() {
    super.initState();
    _sim.addListener(_onPing);
    _alerts.addListener(_refresh);
    _favs.addListener(_refresh);
    search.addListener(_refresh);
    searchFocus.addListener(_onSearchFocus);
    _ticker = createTicker(_onFrame)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _sim.removeListener(_onPing);
    _alerts.removeListener(_refresh);
    _favs.removeListener(_refresh);
    search.dispose();
    searchFocus.dispose();
    _frame.dispose();
    _sheet.dispose();
    _panelScroll.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _onPing() => _refresh();

  /// Opens [page] on top of the map's home card (used by the other tabs).
  void openPage(SheetPage page) {
    searchFocus.unfocus();
    setState(() {
      _stack
        ..clear()
        ..add(const HomePage());
      if (page is! HomePage) _stack.add(page);
    });
    _onPageChanged();
  }

  /// Stop pins show which lines serve them.
  bool _showStopLines = true;

  /// Only accessible stops and buses (accessible vans are always shown).
  bool _onlyAccessible = false;
  bool _showRecharge = false;
  final _nearest = nearestStop();

  void _onSearchFocus() {
    if (searchFocus.hasFocus) _snapSheet(_snapSizes.last);
  }

  // ---------------------------------------------------------------- camera

  /// Where the "visual center" is: above the sheet, or right of the panel.
  Offset get _viewOffset {
    if (_wide) return const Offset((_panelWidth + 12) / 2, 0);
    final size = _sheet.isAttached ? _sheet.size : _snapSizes[1];
    return Offset(0, -_screen.height * size.clamp(0.0, 0.6) / 2);
  }

  EdgeInsets get _fitPadding => _wide
      ? const EdgeInsets.fromLTRB(_panelWidth + 48, 60, 70, 40)
      : EdgeInsets.fromLTRB(
          40,
          90,
          70,
          _screen.height *
                  (_sheet.isAttached ? _sheet.size : _snapSizes[1]).clamp(
                    0.0,
                    0.6,
                  ) +
              30,
        );

  void _flyTo(LatLng Function() target, double zoom, {bool follow = false}) {
    if (!_mapReady) return;
    _camTarget = target;
    _camZoom = zoom;
    _camStart = _now;
    _camFrom = _map.camera.center;
    _camFromZoom = _map.camera.zoom;
    _following = follow;
  }

  void _fitPoints(List<LatLng> points) {
    if (!_mapReady) return;
    final cam = CameraFit.coordinates(
      coordinates: points,
      padding: _fitPadding,
    ).fit(_map.camera);
    final center = cam.center;
    _flyTo(() => center, cam.zoom);
    _camOffsetless = true;
  }

  /// Fits ignore the visual offset (padding already accounts for it).
  bool _camOffsetless = false;

  void _onFrame(Duration elapsed) {
    _now = elapsed;
    _frame.value++;
    final target = _camTarget;
    if (target == null || !_mapReady) return;

    final offset = _camOffsetless ? Offset.zero : _viewOffset;
    final start = _camStart;
    if (start == null) {
      // Steady follow.
      _map.move(target(), _map.camera.zoom, offset: offset);
      return;
    }
    final raw = (elapsed - start).inMicroseconds / _flyDuration.inMicroseconds;
    final t = Curves.easeInOutCubic.transform(raw.clamp(0.0, 1.0));
    final to = target();
    final from = _camFrom!;
    _map.move(
      LatLng(
        from.latitude + (to.latitude - from.latitude) * t,
        from.longitude + (to.longitude - from.longitude) * t,
      ),
      _camFromZoom! + (_camZoom - _camFromZoom!) * t,
      offset: offset * t,
    );
    if (raw >= 1) {
      _camStart = null;
      if (!_following) _camTarget = null;
    }
  }

  void _stopCamera() {
    _camTarget = null;
    _camStart = null;
    if (_following) setState(() => _following = false);
  }

  // ------------------------------------------------------------ navigation

  @override
  bool get following => _following;

  @override
  void follow() {
    final p = _page;
    if (p is! BusPage) return;
    final bus = _sim.bus(p.busId);
    _camOffsetless = false;
    _flyTo(() => _sim.positionOf(bus), _followZoom, follow: true);
    setState(() {});
  }

  @override
  void push(SheetPage page) {
    searchFocus.unfocus();
    setState(() => _stack.add(page));
    _onPageChanged();
  }

  @override
  void pop() {
    if (_stack.length == 1) return;
    setState(() => _stack.removeLast());
    _onPageChanged();
  }

  void _onPageChanged() {
    _following = false;
    _camTarget = null;
    _resetScroll();
    final p = _page;
    if (p is! HomePage &&
        _sheet.isAttached &&
        (_sheet.size < 0.3 || _sheet.size > 0.6)) {
      _snapSheet(_snapSizes[1]);
    }
    // Let the sheet settle before computing the visible map area.
    Future.delayed(const Duration(milliseconds: 60), () {
      if (!mounted) return;
      switch (p) {
        case HomePage():
          _fitPoints([for (final r in MockData.routes.values) ...r.points]);
        case LinePage(:final lineId):
          _fitPoints(MockData.routes[lineId]!.points);
        case StopPage(:final stopId):
          final pos = MockData.stop(stopId).position;
          _camOffsetless = false;
          _flyTo(() => pos, 16);
        case BusPage():
          follow();
        case RechargeListPage():
          _fitPoints([
            MockData.userLocation,
            for (final r in MockData.rechargePoints) r.position,
          ]);
        case RechargePage(:final pointId):
          final pos = MockData.rechargePoint(pointId).position;
          _camOffsetless = false;
          _flyTo(() => pos, 16);
      }
    });
  }

  void _resetScroll() {
    if (_panelScroll.hasClients) _panelScroll.jumpTo(0);
  }

  void _snapSheet(double size) {
    if (!_sheet.isAttached) return;
    _sheet.animateTo(
      size,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void openPass() => AppNav.of(context).select(AppTab.pass);

  @override
  void openSettings() => showSettingsSheet(context, onOpenPass: openPass);

  // ----------------------------------------------------------------- build

  /// Lines the current page is about (others get dimmed on the map).
  Set<String>? get _focusLines => switch (_page) {
    HomePage() => null,
    LinePage(:final lineId) => {lineId},
    StopPage(:final stopId) => MockData.stop(stopId).lineIds.toSet(),
    BusPage(:final busId) => {_sim.bus(busId).lineId},
    RechargeListPage() || RechargePage() => null,
  };

  @override
  Widget build(BuildContext context) {
    final ios = IosColors.of(context);
    final mq = MediaQuery.of(context);
    _screen = mq.size;
    _wide = mq.size.width >= _wideBreakpoint;

    final content = switch (_page) {
      HomePage() => buildHomeSheet(context, this),
      LinePage(:final lineId) => buildLineSheet(context, this, lineId),
      StopPage(:final stopId) => buildStopSheet(context, this, stopId),
      BusPage(:final busId) => buildBusSheet(context, this, busId),
      RechargeListPage() => buildRechargeListSheet(context, this),
      RechargePage(:final pointId) => buildRechargeSheet(
        context,
        this,
        pointId,
      ),
    };
    final pageKey = ValueKey(
      _stack.length.toString() + _page.runtimeType.toString(),
    );

    return PopScope(
      canPop: _stack.length == 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) pop();
      },
      child: Scaffold(
        backgroundColor: ios.groupedBackground,
        body: Stack(
          children: [
            _buildMap(context),
            if (_wide)
              Positioned(
                left: 12,
                top: mq.padding.top + 12,
                bottom: 12,
                width: _panelWidth,
                child: GlassFrame(
                  radius: BorderRadius.circular(16),
                  child: _SheetScroll(
                    key: pageKey,
                    controller: _panelScroll,
                    content: content,
                    showGrabber: false,
                  ),
                ),
              )
            else
              DraggableScrollableSheet(
                controller: _sheet,
                initialChildSize: _snapSizes[1],
                minChildSize: _snapSizes.first,
                maxChildSize: _snapSizes.last,
                snap: true,
                snapSizes: _snapSizes,
                builder: (context, scroll) => GlassFrame(
                  radius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: _SheetScroll(
                    key: pageKey,
                    controller: scroll,
                    content: content,
                    showGrabber: true,
                  ),
                ),
              ),
            Positioned(
              right: 12,
              top: mq.padding.top + 12,
              child: MapControlBox(
                children: [
                  MapControlButton(
                    icon: CupertinoIcons.square_stack_3d_up,
                    tooltip: 'Mostrar linhas nos pontos',
                    active: _showStopLines,
                    onTap: () =>
                        setState(() => _showStopLines = !_showStopLines),
                  ),
                  MapControlButton(
                    icon: Icons.accessible_rounded,
                    tooltip: 'Só acessíveis',
                    active: _onlyAccessible,
                    onTap: () =>
                        setState(() => _onlyAccessible = !_onlyAccessible),
                  ),
                  MapControlButton(
                    icon: CupertinoIcons.creditcard,
                    tooltip: 'Pontos de recarga',
                    active: _showRecharge || _showsRecharge,
                    onTap: () => setState(() => _showRecharge = !_showRecharge),
                  ),
                  MapControlButton(
                    icon: Icons.directions_walk_rounded,
                    tooltip: 'Ponto mais próximo',
                    onTap: () => push(StopPage(_nearest.stop.id)),
                  ),
                  MapControlButton(
                    icon: _following
                        ? CupertinoIcons.location_fill
                        : CupertinoIcons.location,
                    tooltip: 'Centralizar',
                    active: _following,
                    onTap: () {
                      if (_page is BusPage) {
                        follow();
                      } else {
                        _camOffsetless = false;
                        _flyTo(() => MockData.userLocation, 15.5);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _showsRecharge => _page is RechargePage || _page is RechargeListPage;

  Widget _buildMap(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ios = IosColors.of(context);
    final focus = _focusLines;
    final selectedStop = switch (_page) {
      StopPage(:final stopId) => stopId,
      _ => null,
    };
    final selectedBus = switch (_page) {
      BusPage(:final busId) => busId,
      _ => null,
    };
    final selectedRecharge = switch (_page) {
      RechargePage(:final pointId) => pointId,
      _ => null,
    };
    bool inFocus(String lineId) => focus == null || focus.contains(lineId);

    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: MockData.cityCenter,
        initialZoom: 13.6,
        minZoom: 11,
        maxZoom: 18.5,
        backgroundColor: isDark
            ? const Color(0xFF1C1C1E)
            : const Color(0xFFF2EFE9),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onMapReady: () {
          _mapReady = true;
          _onPageChanged();
        },
        onTap: (_, _) => searchFocus.unfocus(),
        onPositionChanged: (camera, hasGesture) {
          if (hasGesture && _camTarget != null) _stopCamera();
        },
      ),
      children: [
        const OneBusTileLayer(),
        PolylineLayer(
          polylines: [
            for (final line in MockData.lines)
              if (!inFocus(line.id))
                Polyline(
                  points: MockData.routes[line.id]!.points,
                  color: line.color.withValues(alpha: 0.18),
                  strokeWidth: 3,
                ),
            for (final line in MockData.lines)
              if (inFocus(line.id))
                Polyline(
                  points: MockData.routes[line.id]!.points,
                  color: line.color,
                  strokeWidth: focus == null ? 4 : 6,
                  borderColor: isDark ? Colors.black54 : Colors.white,
                  borderStrokeWidth: 2,
                ),
          ],
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: [MockData.userLocation, _nearest.stop.position],
              color: ios.tint,
              strokeWidth: 4,
              pattern: const StrokePattern.dotted(spacingFactor: 2),
            ),
          ],
        ),
        ValueListenableBuilder<int>(
          valueListenable: _frame,
          builder: (context, _, _) {
            // Shrink vehicles when zoomed out so the city stays readable.
            final zoom = _mapReady ? _map.camera.zoom : 13.6;
            final scale = ((zoom - 11.5) / 4.5).clamp(0.55, 1.0);
            return MarkerLayer(
              markers: [
                for (final bus in _sim.buses)
                  if (!_onlyAccessible || bus.accessible)
                    Marker(
                      key: ValueKey(bus.id),
                      point: _sim.positionOf(bus),
                      width: 64,
                      height: 64,
                      child: GestureDetector(
                        onTap: () => push(BusPage(bus.id)),
                        child: Transform.scale(
                          scale: scale,
                          child: BusMarker(
                            color: MockData.line(bus.lineId).color,
                            number: MockData.line(bus.lineId).number,
                            bearing: _sim.bearingOf(bus),
                            selected: bus.id == selectedBus,
                            van: bus.isVan,
                            stale: !bus.hasSignal,
                            dimmed:
                                (selectedBus != null &&
                                    bus.id != selectedBus) ||
                                !inFocus(bus.lineId),
                          ),
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
        ValueListenableBuilder<int>(
          valueListenable: _frame,
          builder: (context, _, _) {
            final zoom = _mapReady ? _map.camera.zoom : 13.6;
            final labels = _showStopLines && zoom >= 12;
            return MarkerLayer(
              markers: [
                for (final stop in MockData.stops)
                  if (stop.lineIds.any(inFocus) &&
                      (!_onlyAccessible ||
                          stop.accessible ||
                          stop.id == selectedStop))
                    Marker(
                      point: stop.position,
                      width: 30,
                      height: 30,
                      child: GestureDetector(
                        onTap: () => push(StopPage(stop.id)),
                        child: StopPin(
                          selected: stop.id == selectedStop,
                          accessible: stop.accessible,
                          nearest: stop.id == _nearest.stop.id
                              ? _nearest.walkLabel
                              : null,
                          lineIds: labels || stop.id == selectedStop
                              ? stop.lineIds
                              : const [],
                        ),
                      ),
                    ),
                if (_showRecharge || _showsRecharge)
                  for (final r in MockData.rechargePoints)
                    Marker(
                      point: r.position,
                      width: 34,
                      height: 34,
                      child: GestureDetector(
                        onTap: () => push(RechargePage(r.id)),
                        child: RechargePin(selected: r.id == selectedRecharge),
                      ),
                    ),
                Marker(
                  point: MockData.userLocation,
                  width: 44,
                  height: 44,
                  child: UserDot(color: ios.tint),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Pinned header + scrolling body of a sheet page, fading in on change.
class _SheetScroll extends StatelessWidget {
  final ScrollController controller;
  final SheetContent content;
  final bool showGrabber;

  const _SheetScroll({
    super.key,
    required this.controller,
    required this.content,
    required this.showGrabber,
  });

  @override
  Widget build(BuildContext context) {
    final ios = IosColors.of(context);
    final grabber = showGrabber ? 17.0 : 12.0;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: CustomScrollView(
        controller: controller,
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _HeaderDelegate(
              height: grabber + content.headerHeight,
              color: ios.sheet,
              child: Column(
                children: [
                  SizedBox(
                    height: grabber,
                    child: showGrabber
                        ? Center(
                            child: Container(
                              width: 36,
                              height: 5,
                              decoration: BoxDecoration(
                                color: ios.tertiaryLabel,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          )
                        : null,
                  ),
                  content.header,
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(delegate: SliverChildListDelegate(content.body)),
          ),
        ],
      ),
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Color color;
  final Widget child;

  _HeaderDelegate({
    required this.height,
    required this.color,
    required this.child,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final ios = IosColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border(
          bottom: BorderSide(
            color: shrinkOffset > 0 || overlapsContent
                ? ios.separator
                : Colors.transparent,
            width: 0.5,
          ),
        ),
      ),
      child: OverflowBox(
        alignment: Alignment.topCenter,
        maxHeight: height,
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(_HeaderDelegate old) => true;
}
