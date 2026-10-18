import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';

/// OneBus app icon: the numeral "1" drawn as a transit-map route, with a
/// station at each end, on a bus-stop-sign yellow squircle.
///
/// [draw] (0..1) traces the route and [stations] (0..1) pops the station
/// rings — the splash screen animates both; elsewhere they stay at 1.
class OneBusLogo extends StatelessWidget {
  final double size;
  final double draw;
  final double stations;

  const OneBusLogo({
    super.key,
    this.size = 40,
    this.draw = 1,
    this.stations = 1,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: OneBusLogoPainter(draw: draw, stations: stations),
    );
  }
}

class OneBusLogoPainter extends CustomPainter {
  final double draw;
  final double stations;

  /// Full-bleed square background (platform icons apply their own mask).
  final bool square;

  /// Scale of the route inside the background (maskable icons need room).
  final double contentScale;

  const OneBusLogoPainter({
    this.draw = 1,
    this.stations = 1,
    this.square = false,
    this.contentScale = 1,
  });

  // Geometry in a 100×100 box.
  static const _start = Offset(31, 37);
  static const _bend = Offset(55, 23);
  static const _end = Offset(55, 75);
  static const _stroke = 11.0;

  /// The route path, scaled to [size]. Exposed so the splash can move a
  /// "bus" along it.
  static Path routePath(Size size) {
    final k = size.width / 100;
    return Path()
      ..moveTo(_start.dx * k, _start.dy * k)
      ..lineTo(_bend.dx * k, _bend.dy * k)
      ..lineTo(_end.dx * k, _end.dy * k);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 100;

    final bg = Paint()..color = AppColors.brandYellow;
    if (square) {
      canvas.drawRect(Offset.zero & size, bg);
    } else {
      canvas.drawRSuperellipse(
        RSuperellipse.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(22.5 * k),
        ),
        bg,
      );
    }
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(contentScale);
    canvas.translate(-size.width / 2, -size.height / 2);

    final ink = Paint()
      ..color = AppColors.brandInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (draw > 0) {
      final path = routePath(size);
      final drawn = Path();
      var remaining =
          path.computeMetrics().fold<double>(0, (a, m) => a + m.length) * draw;
      for (final m in path.computeMetrics()) {
        final take = remaining.clamp(0.0, m.length);
        drawn.addPath(m.extractPath(0, take), Offset.zero);
        remaining -= take;
      }
      canvas.drawPath(drawn, ink);
    }

    if (stations > 0) {
      _station(canvas, _start * k, 8.5 * k * stations);
      _station(canvas, _end * k, 10 * k * stations);
    }
    canvas.restore();
  }

  void _station(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c, r, Paint()..color = AppColors.brandInk);
    canvas.drawCircle(c, r * 0.48, Paint()..color = AppColors.brandYellow);
  }

  @override
  bool shouldRepaint(OneBusLogoPainter old) =>
      old.draw != draw ||
      old.stations != stations ||
      old.square != square ||
      old.contentScale != contentScale;
}

/// "onebus" wordmark.
class OneBusWordmark extends StatelessWidget {
  final double fontSize;
  final Color? color;

  const OneBusWordmark({super.key, this.fontSize = 34, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'one'),
          TextSpan(
            text: 'bus',
            style: TextStyle(color: c.withValues(alpha: 0.55)),
          ),
        ],
      ),
      style: GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: -fontSize * 0.045,
        color: c,
        height: 1,
      ),
    );
  }
}
