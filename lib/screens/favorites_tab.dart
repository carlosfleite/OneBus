import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/mock_data.dart';
import '../services/alerts_center.dart';
import '../services/bus_simulator.dart';
import '../services/favorites_store.dart';
import '../services/nearby.dart';
import '../services/notification_service.dart';
import '../widgets/ds/app_segmented.dart';
import '../widgets/ds/empty_state.dart';
import '../widgets/favorite_actions.dart';
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
        final ios = AppPalette.of(context);
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
                    Icons.notifications_rounded,
                    AppColors.red,
                  ),
                  title: 'Avisar quando estiver chegando',
                  trailing: Switch(
                    value: favs.notifyArrivals,
                    onChanged: favs.setNotifyArrivals,
                  ),
                ),
                if (favs.notifyArrivals)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Avisar com antecedência de',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 10),
                        AppSegmented<int>(
                          value: favs.notifyMinutes,
                          onChanged: favs.setNotifyMinutes,
                          options: {
                            for (final m in FavoritesStore.minuteOptions)
                              m: '$m min',
                          },
                        ),
                      ],
                    ),
                  ),
                _PermissionRow(service: notifications),
                IosRow(
                  leading: const IconTile(
                    Icons.send_rounded,
                    AppColors.blue,
                  ),
                  title: 'Enviar notificação de teste',
                  titleColor: ios.tint,
                  onTap: () => AlertsCenter.instance.show(
                    const AppBanner(
                      icon: Icons.star_rounded,
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
                  const EmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: 'Nada sendo monitorado',
                    message:
                        'Favorite uma linha e um ponto por onde ela passa '
                        'para ser avisado quando o ônibus estiver chegando.',
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
                      onTap: () => toggleLineFavorite(context, line.id),
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
                    leading: const IconTile(Icons.directions_bus_rounded, AppColors.gray),
                    title: MockData.stop(stopId).name,
                    subtitle:
                        '${distanceTo(stopId).distanceLabel} · linhas '
                        '${MockData.stop(stopId).lineIds.map((l) => MockData.line(l).number).join(', ')}',
                    trailing: _Star(
                      active: true,
                      onTap: () => toggleStopFavorite(context, stopId),
                    ),
                    onTap: () => nav.openOnMap(StopPage(stopId)),
                  ),
                IosRow(
                  leading: Icon(
                    Icons.add_circle_rounded,
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
    final ios = AppPalette.of(context);
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
      leading: const IconTile(Icons.notifications_active_rounded, AppColors.orange),
      title: 'Notificações do sistema',
      subtitle: subtitle,
      trailing: canAsk
          ? FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              onPressed: service.requestPermission,
              child: const Text('Permitir'),
            )
          : service.permission.value == NotificationPermission.granted
          ? Icon(Icons.check_rounded, color: ios.live)
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
          active ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 22,
          color: active
              ? AppColors.orange
              : AppPalette.of(context).tertiaryLabel,
        ),
      ),
    );
  }
}
