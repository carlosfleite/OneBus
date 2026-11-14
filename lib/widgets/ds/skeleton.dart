import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Shimmering placeholder block used while content loads.
class Skeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const Skeleton({super.key, this.width, this.height = 16, this.radius = 8});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final base = p.fill;
    final shine = Color.lerp(p.fill, p.cell, 0.7)!;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(-1.5 + _c.value * 3, 0),
            end: Alignment(-0.5 + _c.value * 3, 0),
            colors: [base, shine, base],
          ),
        ),
      ),
    );
  }
}

/// A card-shaped skeleton (icon, two lines and a chip) for list rows.
class SkeletonCard extends StatelessWidget {
  final double height;

  const SkeletonCard({super.key, this.height = 92});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.cell,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Skeleton(width: 44, height: 44, radius: 12),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 160, height: 14),
                SizedBox(height: 10),
                Skeleton(width: 100, height: 12),
              ],
            ),
          ),
          Skeleton(width: 46, height: 22, radius: 11),
        ],
      ),
    );
  }
}

/// [count] stacked [SkeletonCard]s.
class SkeletonList extends StatelessWidget {
  final int count;

  const SkeletonList({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Carregando',
    child: Column(
      children: [for (var i = 0; i < count; i++) const SkeletonCard()],
    ),
  );
}
