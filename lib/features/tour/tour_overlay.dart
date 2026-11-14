import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/ds/app_button.dart';
import 'tour_controller.dart';

/// One stop of the tour: a highlighted element plus its explanation.
class TourStep {
  final IconData icon;
  final String title;
  final String body;

  /// Element to spotlight.
  final GlobalKey target;

  const TourStep({
    required this.icon,
    required this.title,
    required this.body,
    required this.target,
  });
}

/// Dimmed layer with a spotlight over the real interface and a card that
/// explains it (coach marks).
class TourOverlay extends StatefulWidget {
  final List<TourStep> steps;

  /// Called whenever the step changes, so the app can show the matching tab.
  final ValueChanged<int> onStep;

  const TourOverlay({super.key, required this.steps, required this.onStep});

  @override
  State<TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<TourOverlay> {
  final _tour = TourController.instance;

  @override
  void initState() {
    super.initState();
    _tour.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onStep(_tour.step);
      // First build happens before the targets are laid out: measure again.
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tour.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    widget.onStep(_tour.step);
    // The tab bar animates when the tab changes; measure again afterwards.
    Future<void>.delayed(const Duration(milliseconds: 320), () {
      if (mounted) setState(() {});
    });
  }

  Rect? _targetRect(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    final me = context.findRenderObject() as RenderBox?;
    if (box == null || me == null || !box.attached || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: me);
    return topLeft & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    final i = _tour.step.clamp(0, widget.steps.length - 1);
    final step = widget.steps[i];
    final last = i == widget.steps.length - 1;
    final rect = _targetRect(step.target);
    final spot = rect?.inflate(6);

    return LayoutBuilder(
      builder: (context, c) => Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      label: 'Tour do aplicativo',
      child: Stack(
        children: [
          // Dim layer with a hole; absorbs taps so the app below is inert.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: TweenAnimationBuilder<Rect?>(
                tween: RectTween(
                  begin: spot ?? Rect.zero,
                  end: spot ?? Rect.zero,
                ),
                duration: const Duration(milliseconds: 300),
                builder: (context, r, _) =>
                    CustomPaint(painter: _SpotlightPainter(spot == null ? null : r)),
              ),
            ),
          ),
          if (spot != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: c.maxHeight - spot.top + 18,
              child: _TourCard(
                step: step,
                index: i,
                total: widget.steps.length,
                last: last,
                arrowX: spot.center.dx - 16,
                onSkip: _tour.finish,
                onPrev: i > 0 ? () => _tour.goTo(i - 1) : null,
                onNext: last ? _tour.finish : () => _tour.goTo(i + 1),
                p: p,
                text: text,
              ),
            ),
        ],
      ),
      ),
    );
  }
}

class _TourCard extends StatelessWidget {
  final TourStep step;
  final int index;
  final int total;
  final bool last;
  final double arrowX;
  final VoidCallback onSkip;
  final VoidCallback? onPrev;
  final VoidCallback onNext;
  final AppPalette p;
  final TextTheme text;

  const _TourCard({
    required this.step,
    required this.index,
    required this.total,
    required this.last,
    required this.arrowX,
    required this.onSkip,
    required this.onPrev,
    required this.onNext,
    required this.p,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          decoration: BoxDecoration(
            color: AppColors.brandInk,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.brandYellow, width: 1.5),
            boxShadow: const [
              BoxShadow(color: Color(0x66000000), blurRadius: 30),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.brandYellow,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      step.icon,
                      color: AppColors.brandInk,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step.title,
                      style: text.titleLarge?.copyWith(color: Colors.white),
                    ),
                  ),
                  Text(
                    '${index + 1}/$total',
                    style: text.labelLarge?.copyWith(
                      color: AppColors.brandYellow,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                step.body,
                style: text.bodyMedium?.copyWith(
                  color: Colors.white70,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (var d = 0; d < total; d++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.only(right: 5),
                      width: d == index ? 20 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: d == index
                            ? AppColors.brandYellow
                            : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  const Spacer(),
                  if (!last)
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        minimumSize: const Size(56, 44),
                      ),
                      onPressed: onSkip,
                      child: const Text('Pular'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (onPrev != null) ...[
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        label: 'Anterior',
                        secondary: true,
                        onDark: true,
                        compact: true,
                        onPressed: onPrev,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    flex: 3,
                    child: AppButton(
                      label: last ? 'Começar a usar' : 'Próximo',
                      onPressed: onNext,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Arrow pointing at the highlighted tab.
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: EdgeInsets.only(
              left: (arrowX - 10).clamp(12.0, 4000.0),
            ),
            child: CustomPaint(
              size: const Size(20, 10),
              painter: _ArrowPainter(),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.brandYellow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SpotlightPainter extends CustomPainter {
  final Rect? hole;

  _SpotlightPainter(this.hole);

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()..addRect(Offset.zero & size);
    final dim = Paint()..color = const Color(0xC70D0D0F);
    if (hole == null) {
      canvas.drawPath(full, dim);
      return;
    }
    final rrect = RRect.fromRectAndRadius(hole!, const Radius.circular(18));
    final cut = Path.combine(
      PathOperation.difference,
      full,
      Path()..addRRect(rrect),
    );
    canvas.drawPath(cut, dim);
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = AppColors.brandYellow,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) => old.hole != hole;
}
