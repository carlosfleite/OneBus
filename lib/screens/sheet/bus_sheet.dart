import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/mock_data.dart';
import '../../services/alerts_center.dart';
import '../../services/bus_simulator.dart';
import '../../widgets/bus_mini_map.dart';
import '../../widgets/ios.dart';
import 'common.dart';
import 'sheet_nav.dart';

SheetContent buildBusSheet(BuildContext context, SheetNav nav, String busId) {
  final sim = BusSimulator.instance;
  final alerts = AlertsCenter.instance;
  final bus = sim.bus(busId);
  final line = MockData.line(bus.lineId);
  final ios = IosColors.of(context);
  final upcoming = sim.upcomingStopsOf(bus, count: 5);
  final atStop = sim.currentStopOf(bus);
  final sinceFix = sim.secondsSinceFix(bus);
  final report = alerts.crowdReports[busId];

  final level = bus.occupancy < 35
      ? Crowding.empty
      : bus.occupancy < 60
      ? Crowding.seated
      : bus.occupancy < 85
      ? Crowding.standing
      : Crowding.packed;

  return SheetContent(
    headerHeight: SheetTitleHeader.height,
    header: SheetTitleHeader(
      leading: LineBadge(line, height: 30),
      title: line.name,
      subtitle: bus.hasSignal
          ? '${bus.isVan ? 'Van acessível · ' : ''}${bus.plate} · atualizado agora'
          : '${bus.isVan ? 'Van acessível · ' : ''}${bus.plate} · último sinal há $sinceFix s',
      onClose: nav.pop,
    ),
    body: [
      BusMiniMap(key: ValueKey('mini-$busId'), busId: busId),
      const SizedBox(height: 12),
      ActionButtons([
        (
          icon: nav.following
              ? CupertinoIcons.location_fill
              : CupertinoIcons.location,
          label: nav.following ? 'Seguindo' : 'Seguir',
          primary: nav.following,
          onTap: nav.follow,
        ),
        (
          icon: CupertinoIcons.flag,
          label: 'Avisar descida',
          primary: false,
          onTap: () => _pickAlightStop(
            context,
            busId,
            upcoming.map((u) => u.stop.id).toList(),
          ),
        ),
        (
          icon: CupertinoIcons.exclamationmark_bubble,
          label: 'Reportar',
          primary: false,
          onTap: () => showReportSheet(context, line.id),
        ),
      ]),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (!bus.hasSignal)
            const InfoPill(
              icon: CupertinoIcons.wifi_slash,
              label: 'Sem sinal de GPS',
              color: AppColors.orange,
            )
          else
            InfoPill(
              icon: CupertinoIcons.speedometer,
              label: atStop != null
                  ? 'Parado no ponto'
                  : '${bus.speedKmh} km/h',
            ),
          if (bus.accessible)
            InfoPill(
              icon: Icons.accessible_rounded,
              label: bus.isVan
                  ? 'Van acessível · só pontos acessíveis'
                  : 'Acessível',
              color: AppColors.blue,
            ),
          if (bus.airConditioned)
            const InfoPill(
              icon: Icons.ac_unit_rounded,
              label: 'Ar-condicionado',
            ),
        ],
      ),
      if (!bus.hasSignal)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: InsetGroup(
            children: [
              IosRow(
                leading: const IconTile(
                  CupertinoIcons.wifi_slash,
                  AppColors.orange,
                ),
                title: 'Posição desatualizada',
                subtitle:
                    'Mostramos onde ele estava há $sinceFix s. Os horários abaixo são estimados.',
              ),
            ],
          ),
        ),
      if (alerts.alight?.busId == busId)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: InsetGroup(
            children: [
              IosRow(
                leading: const IconTile(
                  CupertinoIcons.flag_fill,
                  AppColors.blue,
                ),
                title: 'Aviso de descida ativo',
                subtitle: MockData.stop(alerts.alight!.stopId).name,
                trailing: CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: alerts.clearAlight,
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ),
      SectionHeader('Próximas paradas'),
      InsetGroup(
        separatorIndent: 52,
        children: [
          for (final u in upcoming)
            IosRow(
              leading: Icon(
                alerts.alight?.busId == busId &&
                        alerts.alight?.stopId == u.stop.id
                    ? CupertinoIcons.flag_fill
                    : CupertinoIcons.circle,
                size: 20,
                color: line.color,
              ),
              title: u.stop.name,
              subtitle: u.stop.address,
              trailing: EtaLabel(
                atStop?.id == u.stop.id ? const Eta(0, live: true) : u.eta,
                fontSize: 15,
              ),
            ),
        ],
      ),
      SectionHeader('Lotação'),
      InsetGroup(
        footer: report != null
            ? 'Informado por um passageiro ${_ago(report.at)}.'
            : 'Estimativa pelo contador de passageiros. Está no ônibus? Conte pra gente.',
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                for (final c in Crowding.values) ...[
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: c.index <= (report?.level ?? level).index
                            ? _crowdColor(report?.level ?? level)
                            : ios.fill,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  if (c != Crowding.packed) const SizedBox(width: 4),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Text(
                  (report?.level ?? level).label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                Text(
                  (report?.level ?? level).description,
                  style: TextStyle(color: ios.secondaryLabel, fontSize: 15),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                for (final c in Crowding.values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: Size.zero,
                        color: ios.fill,
                        borderRadius: BorderRadius.circular(8),
                        onPressed: () => alerts.reportCrowding(busId, c),
                        child: Text(
                          c.label,
                          style: TextStyle(
                            fontSize: 13,
                            color: ios.tint,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

Color _crowdColor(Crowding c) => switch (c) {
  Crowding.empty || Crowding.seated => AppColors.green,
  Crowding.standing => AppColors.orange,
  Crowding.packed => AppColors.red,
};

String _ago(DateTime t) {
  final s = DateTime.now().difference(t).inSeconds;
  return s < 60 ? 'agora' : 'há ${s ~/ 60} min';
}

void _pickAlightStop(BuildContext context, String busId, List<String> stopIds) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: const Text('Em qual ponto você vai descer?'),
      message: const Text('Avisamos 1 minuto antes, para você dar o sinal.'),
      actions: [
        for (final id in stopIds)
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              AlertsCenter.instance.setAlight(busId, id);
            },
            child: Text(MockData.stop(id).name),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.pop(ctx),
        child: const Text('Cancelar'),
      ),
    ),
  );
}
