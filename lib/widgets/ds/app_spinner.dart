import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Small themed progress indicator for inline loading states.
class AppSpinner extends StatelessWidget {
  final double size;
  final Color? color;

  const AppSpinner({super.key, this.size = 22, this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CircularProgressIndicator(
      strokeWidth: 2.4,
      color: color ?? AppPalette.of(context).tint,
    ),
  );
}
