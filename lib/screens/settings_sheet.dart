import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/theme_controller.dart';
import '../widgets/ds/app_segmented.dart';
import '../widgets/ios.dart';
import '../widgets/onebus_logo.dart';
import '../services/auth_store.dart';
import 'auth_screen.dart';
import '../services/pass_store.dart';
import '../features/tour/tour_controller.dart';
import '../widgets/ds/app_sheets.dart';
import '../widgets/ds/app_toast.dart';

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
      final ios = AppPalette.of(ctx);
      final text = Theme.of(ctx).textTheme;
      return SingleChildScrollView(
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
                    backgroundColor: AppColors.brandYellow,
                    child: Text(
                      AuthStore.instance.initial,
                      style: const TextStyle(
                        color: AppColors.brandInk,
                        fontWeight: FontWeight.w800,
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
                      Icons.credit_card_rounded,
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
                      child: AppSegmented<ThemeMode>(
                        value: mode,
                        onChanged: ThemeController.instance.setMode,
                        options: const {
                          ThemeMode.system: 'Automático',
                          ThemeMode.light: 'Claro',
                          ThemeMode.dark: 'Escuro',
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            InsetGroup(
              separatorIndent: 58,
              children: [
                IosRow(
                  leading: const IconTile(
                    Icons.explore_rounded,
                    AppColors.brandInk,
                  ),
                  title: 'Rever tour do app',
                  subtitle: 'Uma volta rápida pelas abas',
                  chevron: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    TourController.instance.start();
                  },
                ),
                IosRow(
                  title: 'Sair',
                  titleColor: AppColors.red,
                  onTap: () async {
                    final ok = await showConfirmDialog(
                      ctx,
                      title: 'Sair da conta?',
                      message:
                          'Você precisará entrar de novo para ver seus '
                          'ônibus favoritos.',
                      confirmLabel: 'Sair',
                      destructive: true,
                    );
                    if (!ok || !ctx.mounted) return;
                    await AuthStore.instance.logout();
                    AppToast.info('Você saiu da conta.');
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
                    'Mapa © OpenStreetMap contributors.',
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
