import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/mock_data.dart';
import '../../services/alerts_center.dart';
import '../../widgets/ds/app_sheets.dart';
import '../../widgets/ios.dart';

const sheetPadding = EdgeInsets.symmetric(horizontal: 16);

/// Title block used by the line / stop / bus pages.
class SheetTitleHeader extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final VoidCallback onClose;

  const SheetTitleHeader({
    super.key,
    required this.title,
    required this.onClose,
    this.leading,
    this.subtitle,
    this.actions = const [],
  });

  static const height = 76.0;

  @override
  Widget build(BuildContext context) {
    final ios = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[
            Padding(padding: const EdgeInsets.only(top: 3), child: leading),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: text.headlineSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: text.bodyMedium?.copyWith(color: ios.secondaryLabel),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          for (final a in actions) ...[a, const SizedBox(width: 8)],
          CloseCircle(onTap: onClose),
        ],
      ),
    );
  }
}

/// Star toggle in a gray circle, next to the close button.
class FavoriteCircle extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const FavoriteCircle({super.key, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ios = AppPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(color: ios.fill, shape: BoxShape.circle),
        child: Icon(
          active ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 15,
          color: active ? AppColors.orange : ios.secondaryLabel,
        ),
      ),
    );
  }
}

/// Row of big rounded action buttons (Apple Maps place-card style).
class ActionButtons extends StatelessWidget {
  final List<({IconData icon, String label, VoidCallback onTap, bool primary})>
  actions;

  const ActionButtons(this.actions, {super.key});

  @override
  Widget build(BuildContext context) {
    final ios = AppPalette.of(context);
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: actions[i].onTap,
              child: Container(
                height: 58,
                decoration: BoxDecoration(
                  color: actions[i].primary ? ios.accent : ios.cell,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      actions[i].icon,
                      size: 20,
                      color: actions[i].primary ? ios.onAccent : ios.label,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      actions[i].label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: actions[i].primary ? ios.onAccent : ios.label,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Service notice (detours, works) for a line.
class ServiceAlertCard extends StatelessWidget {
  final String lineId;
  final VoidCallback? onTap;

  const ServiceAlertCard(this.lineId, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final line = MockData.line(lineId);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: InsetGroup(
        children: [
          IosRow(
            leading: const IconTile(
              Icons.warning_amber_rounded,
              AppColors.orange,
            ),
            title: 'Aviso · Linha ${line.number}',
            subtitle: line.alert,
            chevron: onTap != null,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

/// "Report a problem" action sheet (users asked for a direct channel).
void showReportSheet(BuildContext context, String lineId) {
  const problems = [
    'O ônibus não passou',
    'Muito atrasado',
    'Lotado demais',
    'Rampa/elevador não funciona',
    'Direção perigosa',
    'Ônibus sujo',
  ];
  showActionSheet(
    context,
    title: 'Reportar problema · Linha ${MockData.line(lineId).number}',
    message: 'Seu relato vai para a operadora e ajuda outros passageiros.',
    actions: [
      for (final p in problems)
        SheetAction(p, () => AlertsCenter.instance.reportProblem(lineId, p)),
    ],
  );
}
