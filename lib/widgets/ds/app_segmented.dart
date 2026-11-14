import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Pill-shaped segmented control: the selected option is filled yellow.
class AppSegmented<T> extends StatelessWidget {
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  const AppSegmented({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.fill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final e in options.entries)
            Expanded(
              child: Semantics(
                button: true,
                selected: e.key == value,
                label: e.value,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: e.key == value ? p.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      e.value,
                      style: text.labelMedium?.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: e.key == value ? p.onAccent : p.secondaryLabel,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
