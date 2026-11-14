import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'app_button.dart';

/// Friendly block for "nothing here yet" and "something went wrong".
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool error;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.error = false,
  });

  /// Network / request failure with a retry button.
  const EmptyState.error({
    super.key,
    this.title = 'Não deu certo',
    this.message = 'Verifique sua conexão e tente de novo.',
    required VoidCallback this.onAction,
  }) : icon = Icons.wifi_off_rounded,
       actionLabel = 'Tentar novamente',
       error = true;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: error
                  ? AppColors.red.withValues(alpha: 0.12)
                  : p.accent.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: error ? AppColors.red : p.label),
          ),
          const SizedBox(height: 18),
          Text(title, textAlign: TextAlign.center, style: text.titleLarge),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: 240,
              child: AppButton(
                label: actionLabel!,
                onPressed: onAction,
                secondary: error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
