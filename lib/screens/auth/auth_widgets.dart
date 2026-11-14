import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/password_rules.dart';
import '../../widgets/onebus_logo.dart';

/// Shared frame of the account screens: a black header with the logo and a
/// rounded light/dark card holding the form.
class AuthLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final VoidCallback? onBack;

  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.brandInk,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
              child: Row(
                children: [
                  if (onBack != null)
                    IconButton(
                      tooltip: 'Voltar',
                      onPressed: onBack,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    )
                  else
                    const SizedBox(width: 12),
                  const OneBusLogo(size: 44),
                  const SizedBox(width: 12),
                  const OneBusWordmark(fontSize: 26, color: Colors.white),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: p.groupedBackground,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    24,
                    28,
                    24,
                    24 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(title, style: text.headlineMedium),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: text.bodyMedium?.copyWith(
                          color: p.secondaryLabel,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ...children,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum NoticeKind { error, success, info }

/// Inline message (server error, e-mail sent, …).
class AuthNotice extends StatelessWidget {
  final NoticeKind kind;
  final String message;

  const AuthNotice(this.kind, this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final (icon, color) = switch (kind) {
      NoticeKind.error => (Icons.error_rounded, AppColors.red),
      NoticeKind.success => (Icons.mark_email_read_rounded, AppColors.green),
      NoticeKind.info => (Icons.info_rounded, p.tint),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Live checklist of the password policy, with a strength bar.
class PasswordRequirements extends StatelessWidget {
  final String password;

  const PasswordRequirements({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    final checks = PasswordRules.check(password);
    final score = checks.where((c) => c.ok).length;
    final color = switch (score) {
      <= 2 => AppColors.red,
      3 => AppColors.orange,
      4 => AppColors.brandYellowAlt,
      _ => AppColors.green,
    };
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.cell,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < checks.length; i++)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: 5,
                    margin: EdgeInsets.only(right: i == checks.length - 1 ? 0 : 4),
                    decoration: BoxDecoration(
                      color: i < score ? color : p.fill,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          for (final c in checks)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      c.ok
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      key: ValueKey(c.ok),
                      size: 18,
                      color: c.ok ? AppColors.green : p.tertiaryLabel,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c.label,
                      style: text.bodySmall?.copyWith(
                        color: c.ok ? p.label : p.secondaryLabel,
                        fontWeight: c.ok ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
