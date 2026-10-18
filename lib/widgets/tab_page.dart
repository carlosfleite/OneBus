import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/auth_store.dart';

import '../core/theme/app_colors.dart';

/// A tab with an iOS large title that collapses on scroll.
class TabPage extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final List<Widget> children;

  const TabPage({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final ios = IosColors.of(context);
    return Scaffold(
      backgroundColor: ios.groupedBackground,
      body: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(title),
            trailing: trailing,
            automaticallyImplyLeading: false,
            // Several tabs live in one route; no hero between their bars.
            transitionBetweenRoutes: false,
            backgroundColor: ios.groupedBackground.withValues(alpha: 0.88),
            border: null,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            sliver: SliverList(delegate: SliverChildListDelegate(children)),
          ),
        ],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFFA1A1AA), Color(0xFF71717A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Text(
          AuthStore.instance.initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
