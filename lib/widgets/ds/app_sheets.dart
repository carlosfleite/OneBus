import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'app_button.dart';

/// One choice in [showActionSheet].
class SheetAction {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool destructive;

  const SheetAction(
    this.label,
    this.onTap, {
    this.icon,
    this.destructive = false,
  });
}

/// Bottom sheet with a title and a list of choices (thumb friendly rows).
Future<void> showActionSheet(
  BuildContext context, {
  required String title,
  String? message,
  required List<SheetAction> actions,
  String cancelLabel = 'Cancelar',
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (ctx) {
      final p = AppPalette.of(ctx);
      final text = Theme.of(ctx).textTheme;
      return SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: text.titleLarge),
              if (message != null) ...[
                const SizedBox(height: 4),
                Text(
                  message,
                  style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
                ),
              ],
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Material(
                  color: p.cell,
                  child: Column(
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) Divider(height: 1, color: p.separator),
                        InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            actions[i].onTap();
                          },
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 56),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  if (actions[i].icon != null) ...[
                                    Icon(
                                      actions[i].icon,
                                      size: 22,
                                      color: actions[i].destructive
                                          ? AppColors.red
                                          : p.label,
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  Expanded(
                                    child: Text(
                                      actions[i].label,
                                      style: text.bodyLarge?.copyWith(
                                        color: actions[i].destructive
                                            ? AppColors.red
                                            : p.label,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: cancelLabel,
                secondary: true,
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Yes / no dialog for actions that are hard to undo. Returns true when the
/// user confirms.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  String cancelLabel = 'Cancelar',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            cancelLabel,
            style: TextStyle(color: AppPalette.of(ctx).secondaryLabel),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(110, 48),
            backgroundColor: destructive ? AppColors.red : null,
            foregroundColor: destructive ? Colors.white : null,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
