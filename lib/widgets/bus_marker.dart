import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Top-down bus icon (front pointing up), rotated by [bearing] degrees —
/// the same look as cars in ride-hailing apps.
class BusMarker extends StatelessWidget {
  final Color color;
  final double bearing;
  final String number;
  final bool selected;
  final bool dimmed;

  /// Accessible van: shorter body and a wheelchair badge instead of the
  /// line number.
  final bool van;

  /// No GPS fix: drawn gray at the last known position.
  final bool stale;

  const BusMarker({
    super.key,
    required this.color,
    required this.bearing,
    required this.number,
    this.selected = false,
    this.dimmed = false,
    this.van = false,
    this.stale = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = stale ? const Color(0xFF8E8E93) : this.color;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: dimmed ? 0.3 : (stale ? 0.75 : 1),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (selected)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.22),
                border: Border.all(
                  color: color.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
            ),
          Transform.rotate(
            angle: bearing * math.pi / 180,
            child: CustomPaint(
              size: van ? const Size(18, 32) : const Size(20, 42),
              painter: _BusPainter(color),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: van
                  ? Icon(
                      Icons.accessible_rounded,
                      size: 12,
                      color: Colors.white,
                      semanticLabel: 'Van acessível',
                    )
                  : Text(
                      stale ? '$number ?' : number,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BusPainter extends CustomPainter {
  final Color color;

  _BusPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(w * 0.3),
    );

    canvas.drawRRect(
      body.shift(const Offset(0, 2)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawRRect(body, Paint()..color = color);
    canvas.drawRRect(
      body.deflate(0.8),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.white.withValues(alpha: 0.9),
    );

    final glass = Paint()..color = const Color(0xFF16233A);
    // Windshield (front) and rear window.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.16, h * 0.06, w * 0.68, h * 0.13),
        Radius.circular(w * 0.15),
      ),
      glass,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.22, h * 0.88, w * 0.56, h * 0.06),
        Radius.circular(w * 0.1),
      ),
      glass,
    );
    // Roof hatches.
    final roof = Paint()..color = Colors.white.withValues(alpha: 0.35);
    for (final y in [0.32, 0.55]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.28, h * y, w * 0.44, h * 0.12),
          Radius.circular(w * 0.08),
        ),
        roof,
      );
    }
  }

  @override
  bool shouldRepaint(_BusPainter oldDelegate) => oldDelegate.color != color;
}
