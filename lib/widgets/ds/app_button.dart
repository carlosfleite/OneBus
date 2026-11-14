import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Primary / secondary button with a built-in loading state. While
/// [loading] the button ignores taps, so a request is never sent twice.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool secondary;
  final bool destructive;

  /// Secondary button drawn on a black surface (white text and outline).
  final bool onDark;

  /// Less horizontal padding, for narrow spaces (side-by-side buttons).
  final bool compact;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.secondary = false,
    this.destructive = false,
    this.onDark = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final fg = secondary
        ? (destructive ? AppColors.red : (onDark ? Colors.white : p.label))
        : (destructive ? Colors.white : p.onAccent);
    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: loading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.6, color: fg),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label, maxLines: 1, softWrap: false),
                  ),
                ),
              ],
            ),
    );
    final onTap = loading ? null : onPressed;
    if (secondary) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          disabledForegroundColor: loading ? fg : null,
          padding: compact ? const EdgeInsets.symmetric(horizontal: 8) : null,
          side: onDark ? const BorderSide(color: Colors.white38, width: 1.5) : null,
        ),
        child: child,
      );
    }
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        foregroundColor: fg,
        backgroundColor: destructive ? AppColors.red : null,
        // Keep the colors while loading instead of fading to "disabled".
        disabledBackgroundColor: loading
            ? (destructive ? AppColors.red : p.accent)
            : null,
        disabledForegroundColor: loading ? fg : null,
        padding: compact ? const EdgeInsets.symmetric(horizontal: 8) : null,
      ),
      child: child,
    );
  }
}
