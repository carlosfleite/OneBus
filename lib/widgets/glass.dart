import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../services/alerts_center.dart';
import 'ios.dart';

/// Translucent blurred material (sheets, panels, banners, tab bar).
class GlassFrame extends StatelessWidget {
  final BorderRadius radius;
  final Widget child;

  const GlassFrame({super.key, required this.radius, required this.child});

  @override
  Widget build(BuildContext context) {
    final ios = IosColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E000000),
            blurRadius: 24,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: ColoredBox(color: ios.sheet, child: child),
        ),
      ),
    );
  }
}

/// iOS notification-style banner sliding from the top.
class BannerHost extends StatelessWidget {
  final ValueNotifier<AppBanner?> listenable;
  final VoidCallback onTap;

  const BannerHost({super.key, required this.listenable, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ios = IosColors.of(context);
    final text = Theme.of(context).textTheme;
    return ValueListenableBuilder<AppBanner?>(
      valueListenable: listenable,
      builder: (context, banner, _) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => SlideTransition(
          position: Tween(
            begin: const Offset(0, -1.4),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
        child: banner == null
            ? const SizedBox(key: ValueKey('none'))
            : Center(
                key: ValueKey(banner),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: GestureDetector(
                    onTap: onTap,
                    onVerticalDragEnd: (_) => onTap(),
                    child: GlassFrame(
                      radius: BorderRadius.circular(22),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            IconTile(banner.icon, banner.color, size: 38),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          banner.title,
                                          style: text.titleMedium?.copyWith(
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'agora',
                                        style: text.labelMedium?.copyWith(
                                          color: ios.secondaryLabel,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(banner.message, style: text.bodyMedium),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
