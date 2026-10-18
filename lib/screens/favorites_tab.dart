import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/mock_data.dart';
import '../services/alerts_center.dart';
import '../services/bus_simulator.dart';
import '../services/favorites_store.dart';
import '../services/nearby.dart';
import '../services/notification_service.dart';
import '../widgets/ios.dart';
import '../widgets/tab_page.dart';
import 'app_shell.dart';
import 'sheet/sheet_nav.dart';

/// "Favoritos": favorite lines and stops, and the arrival notifications
/// that watch them.
class FavoritesTab extends StatelessWidget {
  const FavoritesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = AppNav.of(context);
    final notifications = NotificationService.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([
        BusSimulator.instance,
        FavoritesStore.instance,
        notifications.permission,
      ]),
      builder: (context, _) {
        final sim = BusSimulator.instance;
        final favs = FavoritesStore.instance;
        final ios = IosColors.of(context);
        final pairs = favs.watchedPairs;

        return TabPage(
          title: 'Favoritos',
          children: [
            const SectionHeader('Notificações de chegada'),
            InsetGroup(
              separatorIndent: 58,
              footer:
                  'Avisamos quando uma linha favorita estiver a '
                  '${favs.notifyMinutes} min de um ponto favorito por onde ela passa.',
              children: [
                IosRow(
                  leading: const IconTile(
                    CupertinoIcons.bell_fill,
                    AppColors.red,
                  ),
                  title: 'Avisar quando estiver chegando',
                  trailing: CupertinoSwitch(
                    value: favs.notifyArrivals,
                    activeTrackColor: ios.live,
                    onChanged: favs.setNotifyArrivals,
                  ),
                ),
                if (favs.notifyArrivals)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(58, 10, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Antecedência',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        CupertinoSlidingSegmentedControl<int>(
                          groupValue: favs.notifyMinutes,
                          onValueChanged: (v) {
                            if (v != null) favs.setNotifyMinutes(v);
                          },
                          children: {
                            for (final m in FavoritesStore.minuteOptions)
                              m: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: Text('$m min'),
                              ),
                          },
                        ),
                      ],
                    ),
                  ),
                _PermissionRow(service: notifications),
                IosRow(
                  leading: const IconTile(
                    CupertinoIcons.paperplane_fill,
                    AppColors.blue,
                  ),
                  title: 'Enviar notificação de teste',
                  titleColor: ios.tint,
                  onTap: () => AlertsCenter.instance.show(
                    const AppBanner(
                      icon: CupertinoIcons.star_fill,
                      color: AppColors.lineBlue,
                      title: 'Linha 214 chegando no seu ponto',
                      message: 'Teste: chega em 3 min em Rua Aimorés.',
                    ),
                    system: true,
                  ),
                ),
              ],
            ),
            const SectionHeader('Monitorando agora'),
            InsetGroup(
              separatorIndent: 74,
              children: [
                if (pairs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Nenhuma combinação ainda. Favorite um ponto por onde '
                      'passa uma das suas linhas favoritas.',
                      style: TextStyle(color: ios.secondaryLabel),
                    ),
                  ),
                for (final p in pairs)
                  IosRow(
                    leading: SizedBox(
                      width: 46,
                      child: LineBadge(MockData.line(p.lineId)),
                    ),
                    title: MockData.stop(p.stopId).name,
                    subtitle: favs.notifyArrivals
                        ? 'Aviso ${favs.notifyMinutes} min antes'
                        : 'Avisos desligados',
                    trailing: EtaLabel(sim.eta(p.lineId, p.stopId)),
                    onTap: () => nav.openOnMap(StopPage(p.stopId)),
                  ),
              ],
            ),
            const SectionHeader('Linhas'),
            InsetGroup(
              separatorIndent: 74,
              footer: 'Toque na estrela para favoritar.',
              children: [
                for (final line in MockData.lines)
                  IosRow(
                    leading: SizedBox(width: 46, child: LineBadge(line)),
                    title: line.name,
                    subtitle: 'A cada ~${line.headwayMinutes} min',
                    trailing: _Star(
                      active: favs.hasLine(line.id),
                      onTap: () => favs.toggleLine(line.id),
                    ),
                    onTap: () => nav.openOnMap(LinePage(line.id)),
                  ),
              ],
            ),
            const SectionHeader('Pontos'),
            InsetGroup(
              separatorIndent: 58,
              children: [
                for (final stopId in favs.stops)
                  IosRow(
                    leading: const IconTile(CupertinoIcons.bus, AppColors.gray),
                    title: MockData.stop(stopId).name,
                    subtitle:
                        '${distanceTo(stopId).distanceLabel} · linhas '
                        '${MockData.stop(stopId).lineIds.map((l) => MockData.line(l).number).join(', ')}',
                    trailing: _Star(
                      active: true,
                      onTap: () => favs.toggleStop(stopId),
                    ),
                    onTap: () => nav.openOnMap(StopPage(stopId)),
                  ),
                IosRow(
                  leading: Icon(
                    CupertinoIcons.add_circled_solid,
                    color: ios.tint,
                    size: 30,
                  ),
                  title: 'Adicionar ponto',
                  titleColor: ios.tint,
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

class _PermissionRow extends StatelessWidget {
  final NotificationService service;

  const _PermissionRow({required this.service});

  @override
  Widget build(BuildContext context) {
    final ios = IosColors.of(context);
    final (subtitle, canAsk) = switch (service.permission.value) {
      NotificationPermission.granted => ('Permitidas', false),
      NotificationPermission.denied => (
        'Bloqueadas. Ative nas configurações do aparelho/navegador. '
            'Os avisos continuam aparecendo dentro do app.',
        false,
      ),
      NotificationPermission.unsupported => (
        'Indisponíveis aqui. Os avisos aparecem dentro do app.',
        false,
      ),
      NotificationPermission.unknown => (
        'Permita para ser avisado mesmo fora do app.',
        true,
      ),
    };
    return IosRow(
      leading: const IconTile(CupertinoIcons.app_badge_fill, AppColors.orange),
      title: 'Notificações do sistema',
      subtitle: subtitle,
      trailing: canAsk
          ? CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 30),
              color: ios.tint,
              borderRadius: BorderRadius.circular(15),
              onPressed: service.requestPermission,
              child: const Text(
                'Permitir',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            )
          : service.permission.value == NotificationPermission.granted
          ? Icon(CupertinoIcons.checkmark_alt, color: ios.live)
          : null,
    );
  }
}

class _Star extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _Star({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          active ? CupertinoIcons.star_fill : CupertinoIcons.star,
          size: 22,
          color: active
              ? AppColors.orange
              : IosColors.of(context).tertiaryLabel,
        ),
      ),
    );
  }
}
