import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/mock_data.dart';
import '../services/alerts_center.dart';
import '../services/auth_store.dart';
import '../services/nearby.dart';
import '../services/pass_store.dart';
import '../widgets/ios.dart';
import '../widgets/onebus_logo.dart';
import '../widgets/pass_alert.dart';
import '../widgets/recharge_widgets.dart';
import 'app_shell.dart';
import 'sheet/sheet_nav.dart';

/// Wallet-style pass screen.
class PassScreen extends StatelessWidget {
  const PassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ios = IosColors.of(context);
    final nav = AppNav.of(context);
    final nearby = rechargeByDistance().take(4);
    return Scaffold(
      backgroundColor: ios.groupedBackground,
      body: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Passe'),
            automaticallyImplyLeading: false,
            transitionBetweenRoutes: false,
            backgroundColor: ios.groupedBackground.withValues(alpha: 0.9),
            border: null,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const _PassCard(),
                const LowBalanceCard(),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _recharge(context),
                  child: const Text('Recarregar'),
                ),
                SectionHeader(
                  'Pontos de recarga',
                  trailing: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: () => nav.openOnMap(const RechargeListPage()),
                    child: const Text(
                      'Ver no mapa',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ),
                InsetGroup(
                  separatorIndent: 58,
                  footer: 'Também dá para recarregar pelo app, acima.',
                  children: [
                    for (final n in nearby)
                      RechargeRow(
                        near: n,
                        onTap: () => nav.openOnMap(RechargePage(n.point.id)),
                      ),
                  ],
                ),
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
                CupertinoButton(
                  onPressed: PassStore.instance.chargeFare,
                  child: const Text('Simular embarque (− R\$ 5,00)'),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _recharge(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Valor da recarga'),
        actions: [
          for (final v in const [10.0, 20.0, 50.0])
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                PassStore.instance.recharge(v);
                AlertsCenter.instance.show(
                  AppBanner(
                    icon: CupertinoIcons.creditcard_fill,
                    color: AppColors.brandInk,
                    title: 'Recarga confirmada',
                    message: '${formatMoney(v)} adicionados ao seu passe.',
                  ),
                );
              },
              child: Text(formatMoney(v)),
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
            borderRadius: BorderRadius.circular(18),
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
