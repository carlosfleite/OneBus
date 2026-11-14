import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../services/auth_store.dart';
import '../services/feed_service.dart';

/// Pull-to-refresh that keeps the simulated feed in sync and gives the user
/// the usual gesture feedback.
Future<void> defaultRefresh() => FeedService.instance.refresh();

/// Large collapsing title bar shared by every tab.
class LargeTitleBar extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const LargeTitleBar({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    return SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: true,
      backgroundColor: p.groupedBackground,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      toolbarHeight: 56,
      expandedHeight: 116,
      flexibleSpace: FlexibleSpaceBar(
        expandedTitleScale: 1.55,
        titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 14),
        title: Text(
          title,
          style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      actions: [
        if (trailing != null)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: trailing),
          ),
      ],
    );
  }
}

/// A tab with a large title that collapses on scroll, with pull-to-refresh.
class TabPage extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  const TabPage({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Scaffold(
      backgroundColor: p.groupedBackground,
      body: RefreshIndicator(
        color: p.onAccent,
        backgroundColor: p.accent,
        onRefresh: onRefresh ?? defaultRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            LargeTitleBar(title: title, trailing: trailing),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
              sliver: SliverList(delegate: SliverChildListDelegate(children)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round initials avatar that opens the account sheet.
class AvatarButton extends StatelessWidget {
  final VoidCallback onTap;

  const AvatarButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Conta',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.brandYellow,
          ),
          child: Text(
            AuthStore.instance.initial,
            style: const TextStyle(
              color: AppColors.brandInk,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
