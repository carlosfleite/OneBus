import 'package:flutter/cupertino.dart';

import '../../core/theme/app_colors.dart';
import '../../services/nearby.dart';
import '../../widgets/ios.dart';
import '../../widgets/recharge_widgets.dart';
import 'common.dart';
import 'sheet_nav.dart';

SheetContent buildRechargeListSheet(BuildContext context, SheetNav nav) {
  return SheetContent(
    headerHeight: SheetTitleHeader.height,
    header: SheetTitleHeader(
      title: 'Pontos de recarga',
      subtitle: 'Onde recarregar o passe · mais perto primeiro',
      onClose: nav.pop,
    ),
    body: [
      const SizedBox(height: 12),
      InsetGroup(
        separatorIndent: 58,
        children: [
          for (final n in rechargeByDistance())
            RechargeRow(
              near: n,
              onTap: () => nav.push(RechargePage(n.point.id)),
            ),
        ],
      ),
      const SizedBox(height: 32),
    ],
  );
}

SheetContent buildRechargeSheet(
  BuildContext context,
  SheetNav nav,
  String pointId,
) {
  final near = rechargeDistanceTo(pointId);
  final p = near.point;
  final ios = IosColors.of(context);
  final open = p.isOpenAt(DateTime.now());

  return SheetContent(
    headerHeight: SheetTitleHeader.height,
    header: SheetTitleHeader(
      leading: IconTile(rechargeIcon(p.kind), rechargeColor, size: 34),
      title: p.name,
      subtitle: 'Recarga de passe · ${p.kind.label}',
      onClose: nav.pop,
    ),
    body: [
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          InfoPill(
            icon: CupertinoIcons.clock,
            label: rechargeStatus(p),
            color: open ? AppColors.green : AppColors.red,
          ),
          InfoPill(
            icon: CupertinoIcons.location,
            label: '${near.distanceLabel} · ${near.walkLabel}',
          ),
        ],
      ),
      const SectionHeader('Detalhes'),
      InsetGroup(
        children: [
          IosRow(
            leading: const IconTile(
              CupertinoIcons.placemark_fill,
              AppColors.gray,
            ),
            title: 'Endereço',
            subtitle: p.address,
          ),
          IosRow(
            leading: const IconTile(CupertinoIcons.clock_fill, AppColors.gray),
            title: 'Horário',
            subtitle: p.hoursLabel,
          ),
          IosRow(
            leading: const IconTile(
              CupertinoIcons.creditcard_fill,
              AppColors.brandInk,
            ),
            title: 'Leve seu passe',
            subtitle: 'Informe o número •••• 8823 ao atendente.',
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        child: Text(
          'Posição e horários de demonstração.',
          style: TextStyle(fontSize: 12, color: ios.secondaryLabel),
        ),
      ),
      const SizedBox(height: 32),
    ],
  );
}
