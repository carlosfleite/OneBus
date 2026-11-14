import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/mock_data.dart';
import '../services/alerts_center.dart';
import '../services/auth_store.dart';
import '../services/feed_service.dart';
import '../services/nearby.dart';
import '../services/pass_store.dart';
import '../widgets/ad_banner.dart';
import '../widgets/ds/app_sheets.dart';
import '../widgets/ds/skeleton.dart';
import '../widgets/ios.dart';
import '../widgets/onebus_logo.dart';
import '../widgets/pass_alert.dart';
import '../widgets/recharge_widgets.dart';
import '../widgets/tab_page.dart';
import 'app_shell.dart';
import 'sheet/sheet_nav.dart';

/// Wallet-style pass screen.
class PassScreen extends StatelessWidget {
  const PassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ios = AppPalette.of(context);
    final nav = AppNav.of(context);
    final nearby = rechargeByDistance().take(4);
    return Scaffold(
      backgroundColor: ios.groupedBackground,
      body: RefreshIndicator(
        color: ios.onAccent,
        backgroundColor: ios.accent,
        onRefresh: defaultRefresh,
        child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const LargeTitleBar(title: 'Passe'),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                ListenableBuilder(
                  listenable: FeedService.instance,
                  builder: (context, _) => FeedService.instance.loading
                      ? const AspectRatio(
                          aspectRatio: 1.586,
                          child: Skeleton(radius: 20),
                        )
                      : const _PassCard(),
                ),
                const LowBalanceCard(),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _recharge(context),
                  child: const Text('Recarregar'),
                ),
                SectionHeader(
                  'Pontos de recarga',
                  trailing: TextButton(
                    onPressed: () => nav.openOnMap(const RechargeListPage()),
                    child: const Text('Ver no mapa'),
                  ),
                ),
                ListenableBuilder(
                  listenable: FeedService.instance,
                  builder: (context, _) => FeedService.instance.loading
                      ? const SkeletonList(count: 3)
                      : InsetGroup(
                  separatorIndent: 58,
                  footer:
                      'A recarga pelo app tem taxa de serviço de '
                      '${formatMoney(PassStore.rechargeFee)}. Nos pontos de recarga, '
                      'consulte o atendente.',
                  children: [
                    for (final n in nearby)
                      RechargeRow(
                        near: n,
                        onTap: () => nav.openOnMap(RechargePage(n.point.id)),
                      ),
                  ],
                ),
                ),
                const SizedBox(height: 16),
                const AdBanner(),
                const SectionHeader('Últimas viagens'),
                InsetGroup(
                  separatorIndent: 74,
                  footer: 'Valores de demonstração.',
                  children: [
                    for (final (lineId, time) in const [
                      ('l214', 'Hoje, 08:12'),
                      ('l302', 'Ontem, 18:40'),
                      ('l214', 'Ontem, 07:55'),
                      ('l108', 'Seg., 12:20'),
                    ])
                      IosRow(
                        leading: SizedBox(
                          width: 46,
                          child: LineBadge(MockData.line(lineId)),
                        ),
                        title: MockData.line(lineId).name,
                        subtitle: time,
                        trailing: Text(
                          '− R\$ 5,00',
                          style: TextStyle(color: ios.secondaryLabel),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: PassStore.instance.chargeFare,
                  child: const Text('Simular embarque (− R\$ 5,00)'),
                ),
              ]),
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _recharge(BuildContext context) {
    showActionSheet(
      context,
      title: 'Valor da recarga',
      message:
          'Para facilitar sua vida e manter o app rodando liso, incluímos '
          'apenas uma taxinha de serviço na sua recarga :)',
      actions: [
        for (final v in const [10.0, 20.0, 50.0])
          SheetAction(
            '${formatMoney(v)}  ·  paga ${formatMoney(v + PassStore.rechargeFee)}',
            () {
              PassStore.instance.recharge(v);
              AlertsCenter.instance.show(
                AppBanner(
                  icon: Icons.credit_card_rounded,
                  color: AppColors.brandInk,
                  title: 'Recarga confirmada',
                  message:
                      '${formatMoney(v)} adicionados ao seu passe. '
                      'Total cobrado: ${formatMoney(v + PassStore.rechargeFee)} '
                      '(taxa de serviço ${formatMoney(PassStore.rechargeFee)}).',
                ),
              );
            },
            icon: Icons.add_card_rounded,
          ),
      ],
    );
  }
}

class _PassCard extends StatelessWidget {
  const _PassCard();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.586,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: ShapeDecoration(
          color: AppColors.brandInk,
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(22),
            // Keeps the black card visible on the dark theme background.
            side: const BorderSide(color: Color(0xFF3A3A42), width: 1.2),
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const OneBusLogo(size: 34),
                const SizedBox(width: 10),
                const OneBusWordmark(fontSize: 20, color: Colors.white),
                const Spacer(),
                Text(
                  'COMUM',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              'Saldo',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
            ValueListenableBuilder<double>(
              valueListenable: PassStore.instance,
              builder: (context, v, _) => Text(
                formatMoney(v),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${AuthStore.instance.firstName} · •••• 8823',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
