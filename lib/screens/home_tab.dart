import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/mock_data.dart';
import '../models/bus_line.dart';
import '../models/bus_stop.dart';
import '../services/alerts_center.dart';
import '../services/auth_store.dart';
import '../services/bus_simulator.dart';
import '../services/favorites_store.dart';
import '../services/nearby.dart';
import '../widgets/glass.dart';
import '../widgets/ios.dart';
import '../widgets/ad_banner.dart';
import '../widgets/live_mini_map.dart';
import '../widgets/pass_alert.dart';
import '../widgets/recharge_widgets.dart';
import '../widgets/stop_widgets.dart';
import '../widgets/tab_page.dart';
import 'app_shell.dart';
import 'settings_sheet.dart';
import 'sheet/common.dart';
import 'sheet/sheet_nav.dart';

/// "Início", Uber-style: live map on top, your favorite buses in a card
/// below that you can pull up.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  /// One entry per favorite line, at the favorite stop it serves (or the
  /// line's first stop when none of your stops is on it).
  static List<({BusLine line, BusStop stop})> favoriteRides() {
    final favs = FavoritesStore.instance;
    return [
      for (final lineId in favs.lines)
        (
          line: MockData.line(lineId),
          stop: favs.stops
              .map(MockData.stop)
              .firstWhere(
                (s) => s.lineIds.contains(lineId),
                orElse: () => MockData.homeStopFor(lineId),
              ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final nav = AppNav.of(context);
    final favs = FavoritesStore.instance;
    final ios = IosColors.of(context);
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: ios.groupedBackground,
      body: LayoutBuilder(
        builder: (context, box) {
          final mapHeight = box.maxHeight * 0.46;
          final sheetStart = 1 - (mapHeight - 20) / box.maxHeight;

          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: mapHeight + 20,
                child: ListenableBuilder(
                  listenable: favs,
                  builder: (context, _) => LiveMiniMap(
                    lineIds: favs.lines,
                    stopIds: {for (final r in favoriteRides()) r.stop.id},
                    padding: EdgeInsets.fromLTRB(40, top + 70, 40, 50),
                    onTap: () => nav.openOnMap(const HomePage()),
                  ),
                ),
              ),
              Positioned(
                top: top + 10,
                left: 12,
                right: 12,
                child: _TopBar(
                  onAvatar: () => showSettingsSheet(
                    context,
                    onOpenPass: () => nav.select(AppTab.pass),
                  ),
                  onExpand: () => nav.openOnMap(const HomePage()),
                ),
              ),
              DraggableScrollableSheet(
                initialChildSize: sheetStart,
                minChildSize: sheetStart,
                maxChildSize: 0.94,
                snap: true,
                builder: (context, scroll) => GlassFrame(
                  radius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: _HomeCard(scroll: scroll),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onAvatar;
  final VoidCallback onExpand;

  const _TopBar({required this.onAvatar, required this.onExpand});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GlassFrame(
          radius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(5, 5, 14, 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AvatarButton(onTap: onAvatar),
                const SizedBox(width: 8),
                ListenableBuilder(
                  listenable: AuthStore.instance,
                  builder: (context, _) => Text(
                    'Olá, ${AuthStore.instance.firstName}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        MapControlBox(
          children: [
            MapControlButton(
              icon: CupertinoIcons.arrow_up_left_arrow_down_right,
              tooltip: 'Abrir mapa completo',
              onTap: onExpand,
            ),
          ],
        ),
      ],
    );
  }
}

class _HomeCard extends StatelessWidget {
  final ScrollController scroll;

  const _HomeCard({required this.scroll});

  @override
  Widget build(BuildContext context) {
    final nav = AppNav.of(context);
    final ios = IosColors.of(context);
    final text = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: Listenable.merge([
        BusSimulator.instance,
        FavoritesStore.instance,
        AlertsCenter.instance,
      ]),
      builder: (context, _) {
        final favs = FavoritesStore.instance;
        final rides = HomeTab.favoriteRides()
          ..sort(
            (a, b) =>
                (BusSimulator.instance.eta(a.line.id, a.stop.id)?.seconds ??
                        1 << 30)
                    .compareTo(
                      BusSimulator.instance
                              .eta(b.line.id, b.stop.id)
                              ?.seconds ??
                          1 << 30,
                    ),
          );
        final nearest = nearestStop();

        return ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: ios.tertiaryLabel,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => nav.select(AppTab.stops),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: ios.fill,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.search, color: ios.label, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Qual ônibus ou ponto?',
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            LowBalanceCard(onTap: () => nav.select(AppTab.pass)),
            for (final line in MockData.lines.where((l) => l.alert != null))
              ServiceAlertCard(
                line.id,
                onTap: () => nav.openOnMap(LinePage(line.id)),
              ),
            SectionHeader(
              'Seus ônibus',
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: () => nav.select(AppTab.favorites),
                child: const Text('Editar', style: TextStyle(fontSize: 15)),
              ),
            ),
            if (rides.isEmpty)
              InsetGroup(
                children: [
                  IosRow(
                    leading: const IconTile(
                      CupertinoIcons.star_fill,
                      AppColors.orange,
                    ),
                    title: 'Escolha seus ônibus',
                    subtitle: 'Favorite linhas para acompanhar a chegada aqui.',
                    chevron: true,
                    onTap: () => nav.select(AppTab.favorites),
                  ),
                ],
              ),
            for (final r in rides) ...[
              _RideCard(
                line: r.line,
                stop: r.stop,
                notify: favs.notifyArrivals && favs.hasStop(r.stop.id),
              ),
              const SizedBox(height: 10),
            ],
            if (favs.notifyArrivals && favs.watchedPairs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Você recebe uma notificação quando faltarem '
                  '${favs.notifyMinutes} min.',
                  style: text.bodySmall?.copyWith(color: ios.secondaryLabel),
                ),
              ),
            const SizedBox(height: 16),
            const AdBanner(),
            const SectionHeader('Perto de você'),
            NearestStopCard(
              onOpen: () => nav.openOnMap(StopPage(nearest.stop.id)),
            ),
            const SizedBox(height: 12),
            InsetGroup(
              separatorIndent: 58,
              children: [
                RechargeRow(
                  near: rechargeByDistance().first,
                  onTap: () => nav.openOnMap(
                    RechargePage(rechargeByDistance().first.point.id),
                  ),
                ),
                IosRow(
                  leading: const IconTile(
                    CupertinoIcons.placemark_fill,
                    AppColors.lineIndigo,
                  ),
                  title: 'Todos os pontos',
                  subtitle:
                      '${MockData.stops.length} pontos e as linhas de cada um',
                  chevron: true,
                  onTap: () => nav.select(AppTab.stops),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Uber-style card for a favorite line: when the next bus reaches your
/// stop, how full it is, and a bar that fills as it gets closer.
class _RideCard extends StatelessWidget {
  final BusLine line;
  final BusStop stop;
  final bool notify;

  const _RideCard({
    required this.line,
    required this.stop,
    required this.notify,
  });

  @override
  Widget build(BuildContext context) {
    final nav = AppNav.of(context);
    final sim = BusSimulator.instance;
    final ios = IosColors.of(context);
    final text = Theme.of(context).textTheme;
    final eta = sim.eta(line.id, stop.id);
    final bus = sim.nextBusAt(line.id, stop.id);
    final seconds = eta?.seconds ?? 0;
    // 15 min away = empty bar, arriving = full.
    final progress = (1 - seconds / (15 * 60)).clamp(0.04, 1.0);

    final details = <String>[
      if (bus != null && !bus.hasSignal) 'sem sinal de GPS',
      if (bus != null && bus.hasSignal)
        bus.occupancy < 50
            ? 'vazio'
            : bus.occupancy < 80
            ? 'tem lugar'
            : 'lotado',
      if (bus?.accessible ?? false) 'acessível',
      if (bus?.airConditioned ?? false) 'ar',
    ];

    return GestureDetector(
      onTap: bus == null ? null : () => nav.openOnMap(BusPage(bus.id)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ios.cell,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                LineBadge(line, height: 34),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.name,
                        style: text.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          if (notify) ...[
                            Icon(
                              CupertinoIcons.bell_fill,
                              size: 12,
                              color: ios.secondaryLabel,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              'em ${stop.name}',
                              style: text.bodySmall?.copyWith(
                                color: ios.secondaryLabel,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                EtaLabel(eta, fontSize: 20),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: progress),
                duration: const Duration(milliseconds: 800),
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 5,
                  color: eta?.live ?? false ? ios.live : AppColors.gray,
                  backgroundColor: ios.fill,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(CupertinoIcons.bus, size: 13, color: ios.secondaryLabel),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    [if (bus != null) bus.plate, ...details].join(' · '),
                    style: text.labelMedium?.copyWith(
                      color: ios.secondaryLabel,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Ver no mapa',
                  style: text.labelMedium?.copyWith(
                    color: ios.tint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
