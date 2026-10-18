import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/theme_controller.dart';
import '../widgets/ios.dart';
import '../widgets/onebus_logo.dart';
import '../services/auth_store.dart';
import 'auth_screen.dart';
import '../services/pass_store.dart';

/// Account card: profile, pass, appearance.
void showSettingsSheet(
  BuildContext context, {
  required VoidCallback onOpenPass,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      final ios = IosColors.of(ctx);
      final text = Theme.of(ctx).textTheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Conta', style: text.headlineSmall)),
                CloseCircle(onTap: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 16),
            InsetGroup(
              separatorIndent: 58,
              children: [
                IosRow(
                  leading: CircleAvatar(
                    radius: 15,
                    backgroundColor: AppColors.gray,
                    child: Text(
                      AuthStore.instance.initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  title: AuthStore.instance.name ?? '',
                  subtitle: AuthStore.instance.email,
                ),
                ValueListenableBuilder<double>(
                  valueListenable: PassStore.instance,
                  builder: (context, v, _) => IosRow(
                    leading: const IconTile(
                      CupertinoIcons.creditcard_fill,
                      AppColors.brandInk,
                    ),
                    title: 'Passe OneBus',
                    subtitle: 'Saldo ${formatMoney(v)}',
                    chevron: true,
                    onTap: () {
                      Navigator.pop(ctx);
                      onOpenPass();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 6),
              child: Text(
                'APARÊNCIA',
                style: text.bodySmall?.copyWith(color: ios.secondaryLabel),
              ),
            ),
            InsetGroup(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ValueListenableBuilder<ThemeMode>(
                    valueListenable: ThemeController.instance,
                    builder: (context, mode, _) => SizedBox(
                      width: double.infinity,
                      child: CupertinoSlidingSegmentedControl<ThemeMode>(
                        groupValue: mode,
                        onValueChanged: (m) {
                          if (m != null) ThemeController.instance.setMode(m);
                        },
                        children: const {
                          ThemeMode.system: Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Text('Automático'),
                          ),
                          ThemeMode.light: Text('Claro'),
                          ThemeMode.dark: Text('Escuro'),
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            InsetGroup(
              children: [
                IosRow(
                  title: 'Sair',
                  titleColor: AppColors.red,
                  onTap: () async {
                    await AuthStore.instance.logout();
                    if (ctx.mounted) replaceWith(ctx, const AuthScreen());
                  },
                ),
              ],
            ),
            const SizedBox(height: 28),
            Center(
              child: Column(
                children: [
                  const OneBusLogo(size: 44),
                  const SizedBox(height: 8),
                  Text(
                    'Tudo sobre ônibus em um lugar só.',
                    style: text.bodySmall?.copyWith(color: ios.secondaryLabel),
                  ),
                  Text(
                    'Sem anúncios. Mapa © OpenStreetMap contributors.',
                    style: text.labelMedium?.copyWith(color: ios.tertiaryLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
