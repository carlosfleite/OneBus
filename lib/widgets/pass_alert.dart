import 'package:flutter/cupertino.dart';

import '../core/theme/app_colors.dart';
import '../services/pass_store.dart';
import 'ios.dart';

/// "Seu passe está acabando" card, shown while the balance is low.
class LowBalanceCard extends StatelessWidget {
  final VoidCallback? onTap;

  const LowBalanceCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: PassStore.instance,
      builder: (context, balance, _) {
        final pass = PassStore.instance;
        if (!pass.isLow) return const SizedBox.shrink();
        final empty = pass.tripsLeft == 0;
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: InsetGroup(
            children: [
              IosRow(
                leading: IconTile(
                  CupertinoIcons.creditcard_fill,
                  empty ? AppColors.red : AppColors.orange,
                ),
                title: empty ? 'Seu passe acabou' : 'Seu passe está acabando',
                subtitle: 'Saldo ${formatMoney(balance)} · ${pass.tripsLabel}.',
                chevron: onTap != null,
                onTap: onTap,
              ),
            ],
          ),
        );
      },
    );
  }
}
