import 'package:flutter/cupertino.dart';

import '../../core/theme/app_colors.dart';
import '../../data/mock_data.dart';
import 'package:flutter/material.dart' show Icons;

import '../../services/alerts_center.dart';
import '../../services/bus_simulator.dart';
import '../../services/favorites_store.dart';
import '../../widgets/ios.dart';
import 'common.dart';
import 'sheet_nav.dart';

SheetContent buildStopSheet(BuildContext context, SheetNav nav, String stopId) {
  final sim = BusSimulator.instance;
  final alerts = AlertsCenter.instance;
  final favs = FavoritesStore.instance;
  final stop = MockData.stop(stopId);
  final ios = IosColors.of(context);

  final arrivals =
      [
        for (final lineId in stop.lineIds)
          (
            line: MockData.line(lineId),
            eta: sim.eta(lineId, stopId),
            bus: sim.nextBusAt(lineId, stopId),
          ),
      ]..sort(
        (a, b) =>
            (a.eta?.seconds ?? 1 << 30).compareTo(b.eta?.seconds ?? 1 << 30),
      );

  return SheetContent(
    headerHeight: SheetTitleHeader.height,
    header: SheetTitleHeader(
      title: stop.name,
      subtitle: 'Ponto de ônibus · ${stop.address}',
      actions: [
        FavoriteCircle(
          active: favs.hasStop(stopId),
          onTap: () => favs.toggleStop(stopId),
        ),
      ],
      onClose: nav.pop,
    ),
    body: [
      if (stop.accessible)
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: InsetGroup(
            children: [
              IosRow(
                leading: IconTile(Icons.accessible_rounded, AppColors.blue),
                title: 'Ponto acessível',
                subtitle: 'Rampa, piso tátil e espaço para cadeira de rodas.',
              ),
            ],
          ),
        ),
      for (final a in arrivals)
        if (a.line.alert != null) ServiceAlertCard(a.line.id),
      SectionHeader('Chegadas'),
      InsetGroup(
        separatorIndent: 74,
        footer:
            'Toque no sino para ser avisado quando o ônibus estiver a 3 min.',
        children: [
          for (final a in arrivals)
            IosRow(
              leading: SizedBox(width: 46, child: LineBadge(a.line)),
              title: a.line.name,
              subtitle: _busInfo(a.bus),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EtaLabel(a.eta),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => alerts.toggleArrivalAlert(a.line.id, stopId),
                    child: Icon(
                      alerts.hasArrivalAlert(a.line.id, stopId)
                          ? CupertinoIcons.bell_fill
                          : CupertinoIcons.bell,
                      size: 22,
                      color: alerts.hasArrivalAlert(a.line.id, stopId)
                          ? AppColors.orange
                          : ios.tint,
                    ),
                  ),
                ],
              ),
              onTap: a.bus == null ? null : () => nav.push(BusPage(a.bus!.id)),
            ),
        ],
      ),
      SectionHeader('Linhas neste ponto'),
      InsetGroup(
        separatorIndent: 74,
        children: [
          for (final a in arrivals)
            IosRow(
              leading: SizedBox(width: 46, child: LineBadge(a.line)),
              title: 'Ver itinerário',
              subtitle: 'A cada ~${a.line.headwayMinutes} min',
              chevron: true,
              onTap: () => nav.push(LinePage(a.line.id)),
            ),
        ],
      ),
      const SizedBox(height: 32),
    ],
  );
}

String _busInfo(SimulatedBus? bus) {
  if (bus == null) return '';
  if (!bus.hasSignal) {
    return 'Sem sinal há ${BusSimulator.instance.secondsSinceFix(bus)} s · estimado';
  }
  final report = AlertsCenter.instance.crowdReports[bus.id];
  final crowd =
      report?.level.label ??
      (bus.occupancy < 50
          ? 'Vazio'
          : bus.occupancy < 80
          ? 'Tem lugar'
          : 'Lotado');
  return '$crowd${bus.accessible ? ' · ♿︎' : ''}${bus.airConditioned ? ' · ar' : ''}';
}
