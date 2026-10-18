import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/recharge_point.dart';
import '../services/nearby.dart';
import 'ios.dart';

IconData rechargeIcon(RechargeKind kind) => switch (kind) {
  RechargeKind.terminal => CupertinoIcons.bus,
  RechargeKind.loterica => Icons.local_activity_rounded,
  RechargeKind.banca => Icons.storefront_rounded,
  RechargeKind.farmacia => Icons.local_pharmacy_rounded,
};

/// Brand color of recharge points on the map and in lists.
const rechargeColor = AppColors.green;

/// "Open now · closes at 18h" style status line.
String rechargeStatus(RechargePoint p, [DateTime? now]) {
  final t = now ?? DateTime.now();
  if (p.open24h) return 'Aberto 24 horas';
  return p.isOpenAt(t)
      ? 'Aberto agora · fecha às ${p.closes}h'
      : 'Fechado · abre às ${p.opens}h';
}

/// Row for a recharge point: name, status and walking distance.
class RechargeRow extends StatelessWidget {
  final NearbyRecharge near;
  final VoidCallback onTap;

  const RechargeRow({super.key, required this.near, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = near.point;
    final open = p.isOpenAt(DateTime.now());
    return IosRow(
      leading: IconTile(rechargeIcon(p.kind), rechargeColor),
      title: p.name,
      subtitle: '${rechargeStatus(p)} · ${near.distanceLabel}',
      trailing: Text(
        near.walkLabel,
        style: TextStyle(
          fontSize: 13,
          color: open ? IosColors.of(context).secondaryLabel : AppColors.red,
        ),
      ),
      chevron: true,
      onTap: onTap,
    );
  }
}

/// Pin for the map.
class RechargePin extends StatelessWidget {
  final bool selected;

  const RechargePin({super.key, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final s = selected ? 30.0 : 24.0;
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: s,
        height: s,
        decoration: BoxDecoration(
          color: rechargeColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          CupertinoIcons.creditcard_fill,
          size: s * 0.55,
          color: Colors.white,
        ),
      ),
    );
  }
}
