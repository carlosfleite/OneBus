import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum ToastKind { success, info, warning, error }

/// Floating feedback shown near the bottom of the screen. One toast at a
/// time: a new one replaces the previous.
class AppToast {
  AppToast._();

  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static void success(String message) => show(message, ToastKind.success);
  static void info(String message) => show(message, ToastKind.info);
  static void warning(String message) => show(message, ToastKind.warning);
  static void error(String message, {VoidCallback? onRetry}) =>
      show(message, ToastKind.error, onRetry: onRetry);

  static void show(String message, ToastKind kind, {VoidCallback? onRetry}) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return;
    final (icon, color) = switch (kind) {
      ToastKind.success => (Icons.check_circle_rounded, AppColors.greenDark),
      ToastKind.info => (Icons.info_rounded, AppColors.brandYellow),
      ToastKind.warning => (Icons.warning_amber_rounded, AppColors.orange),
      ToastKind.error => (Icons.error_rounded, AppColors.red),
    };
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: Duration(seconds: onRetry == null ? 3 : 6),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          content: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          action: onRetry == null
              ? null
              : SnackBarAction(
                  label: 'Tentar novamente',
                  textColor: AppColors.brandYellow,
                  onPressed: onRetry,
                ),
        ),
      );
  }
}
