import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/mock_data.dart';
import '../../models/bus_line.dart';
import '../../services/bus_simulator.dart';
import '../../services/favorites_store.dart';
import '../../widgets/ios.dart';
import 'common.dart';
import 'sheet_nav.dart';

SheetContent buildLineSheet(BuildContext context, SheetNav nav, String lineId) {
  final sim = BusSimulator.instance;
  final line = MockData.line(lineId);
  final favs = FavoritesStore.instance;
  final stops = sim.stopsOf(lineId);
  final length = MockData.routes[lineId]!.length;

  // Interleave buses into the stop list by where they are on the loop.
  final rows = <Widget>[];
  final buses = sim.busesOf(lineId).toList()
    ..sort((a, b) => sim.progressOf(a).compareTo(sim.progressOf(b)));
  var b = 0;
  for (var i = 0; i < stops.length; i++) {
    while (b < buses.length &&
        sim.progressOf(buses[b]) * length < stops[i].along) {
      rows.add(_BusTimelineRow(line: line, bus: buses[b], onTap: nav.push));
      b++;
    }
    rows.add(
      _StopTimelineRow(
        line: line,
        name: stops[i].stop.name,
        eta: sim.eta(lineId, stops[i].stop.id),
        first: i == 0,
        last: i == stops.length - 1 && b >= buses.length,
        onTap: () => nav.push(StopPage(stops[i].stop.id)),
      ),
    );
  }
  for (; b < buses.length; b++) {
    rows.add(
      _BusTimelineRow(
        line: line,
        bus: buses[b],
        onTap: nav.push,
        last: b == buses.length - 1,
      ),
    );
  }

  final now = DateTime.now();
  final h = line.headwayMinutes;
  final firstSlot = ((now.hour * 60 + now.minute) ~/ h + 1) * h;
  final departures = [
    for (var i = 0; i < 6; i++)
      () {
        final m = (firstSlot + i * h) % (24 * 60);
        return '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
      }(),
  ];

  return SheetContent(
    headerHeight: SheetTitleHeader.height,
    header: SheetTitleHeader(
      leading: LineBadge(line, height: 30),
      title: line.name,
      subtitle: 'Circular · ${buses.length} ônibus · a cada ~$h min',
      actions: [
        FavoriteCircle(
          active: favs.hasLine(lineId),
          onTap: () => favs.toggleLine(lineId),
        ),
      ],
      onClose: nav.pop,
    ),
    body: [
      ActionButtons([
        (
          icon: CupertinoIcons.location_fill,
          label: 'Próximo ônibus',
          primary: true,
          onTap: () {
            final next = sim.nextBusAt(lineId, MockData.homeStopFor(lineId).id);
            if (next != null) nav.push(BusPage(next.id));
          },
        ),
        (
          icon: CupertinoIcons.exclamationmark_bubble,
          label: 'Reportar',
          primary: false,
          onTap: () => showReportSheet(context, lineId),
        ),
      ]),
      if (line.alert != null) ServiceAlertCard(lineId),
      SectionHeader('Itinerário'),
      InsetGroup(dividers: false, children: rows),
      SectionHeader('Saídas programadas'),
      InsetGroup(
        footer:
            'Partidas de ${stops.first.stop.name}. Quando um ônibus fica sem GPS, '
            'mostramos o tempo estimado com "~" — nunca um ônibus fantasma.',
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in departures)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: IosColors.of(context).fill,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      t,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 32),
    ],
  );
}

/// Vertical route rail drawn in the line color.
class _Rail extends StatelessWidget {
  final Color color;
  final bool top;
  final bool bottom;
  final Widget node;

  const _Rail({
    required this.color,
    required this.node,
    this.top = true,
    this.bottom = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              Expanded(
                child: Container(
                  width: 5,
                  color: top ? color : Colors.transparent,
                ),
              ),
              Expanded(
                child: Container(
                  width: 5,
                  color: bottom ? color : Colors.transparent,
                ),
              ),
            ],
          ),
          node,
        ],
      ),
    );
  }
}

class _StopTimelineRow extends StatelessWidget {
  final BusLine line;
  final String name;
  final Eta? eta;
  final bool first;
  final bool last;
  final VoidCallback onTap;

  const _StopTimelineRow({
    required this.line,
    required this.name,
    required this.eta,
    required this.first,
    required this.last,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ios = IosColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: IntrinsicHeight(
        child: Padding(
          padding: const EdgeInsets.only(left: 12, right: 16),
          child: Row(
            children: [
              _Rail(
                color: line.color,
                top: !first,
                bottom: !last,
                node: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: ios.cell,
                    shape: BoxShape.circle,
                    border: Border.all(color: line.color, width: 3),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.bodyLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              EtaLabel(eta, fontSize: 15),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusTimelineRow extends StatelessWidget {
  final BusLine line;
  final SimulatedBus bus;
  final void Function(SheetPage) onTap;
  final bool last;

  const _BusTimelineRow({
    required this.line,
    required this.bus,
    required this.onTap,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final ios = IosColors.of(context);
    final noSignal = !bus.hasSignal;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(BusPage(bus.id)),
      child: IntrinsicHeight(
        child: Padding(
          padding: const EdgeInsets.only(left: 12, right: 16),
          child: Row(
            children: [
              _Rail(
                color: line.color,
                bottom: !last,
                node: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: noSignal ? AppColors.gray : line.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: ios.cell, width: 2),
                  ),
                  child: const Icon(
                    CupertinoIcons.bus,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    noSignal
                        ? '${bus.plate} · sem sinal de GPS'
                        : '${bus.plate} · ${bus.isAtStop ? 'no ponto' : '${bus.speedKmh} km/h'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: noSignal ? AppColors.orange : ios.secondaryLabel,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Icon(
                CupertinoIcons.chevron_forward,
                size: 14,
                color: ios.tertiaryLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
