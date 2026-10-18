import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/bus_line.dart';
import '../services/bus_simulator.dart';

/// iOS-style building blocks (inset grouped lists, route shields, ETA
/// labels, map controls) shared by the sheets.

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Rounded group of rows with hairline separators, like Settings.app.
class InsetGroup extends StatelessWidget {
  final List<Widget> children;
  final double separatorIndent;
  final String? footer;
  final bool dividers;

  const InsetGroup({
    super.key,
    required this.children,
    this.separatorIndent = 16,
    this.footer,
    this.dividers = true,
  });

  @override
  Widget build(BuildContext context) {
    final ios = IosColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ColoredBox(
            color: ios.cell,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0 && dividers)
                    Padding(
                      padding: EdgeInsets.only(left: separatorIndent),
                      child: Container(height: 0.5, color: ios.separator),
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(
              footer!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: ios.secondaryLabel),
            ),
          ),
      ],
    );
  }
}

/// A tappable row with iOS press highlight (no ripple).
class IosRow extends StatefulWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool chevron;
  final VoidCallback? onTap;
  final Color? titleColor;

  const IosRow({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.chevron = false,
    this.onTap,
    this.titleColor,
  });

  @override
  State<IosRow> createState() => _IosRowState();
}

class _IosRowState extends State<IosRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ios = IosColors.of(context);
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _pressed ? ios.fill : Colors.transparent,
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            if (widget.leading != null) ...[
              widget.leading!,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: text.bodyLarge?.copyWith(color: widget.titleColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        widget.subtitle!,
                        style: text.bodyMedium?.copyWith(
                          color: ios.secondaryLabel,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            if (widget.trailing != null) ...[
              const SizedBox(width: 8),
              widget.trailing!,
            ],
            if (widget.chevron) ...[
              const SizedBox(width: 6),
              Icon(
                CupertinoIcons.chevron_forward,
                size: 16,
                color: ios.tertiaryLabel,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Route shield: the line number on its color, like Apple Maps transit.
class LineBadge extends StatelessWidget {
  final BusLine line;
  final double height;

  const LineBadge(this.line, {super.key, this.height = 26});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      constraints: BoxConstraints(minWidth: height * 1.5),
      padding: EdgeInsets.symmetric(horizontal: height * 0.28),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: line.color,
        borderRadius: BorderRadius.circular(height * 0.24),
      ),
      child: Text(
        line.number,
        maxLines: 1,
        softWrap: false,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: height * 0.56,
          letterSpacing: -0.2,
          height: 1,
        ),
      ),
    );
  }
}

/// Square icon tile used as a row's leading (Settings-style).
class IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const IconTile(this.icon, this.color, {super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.6),
    );
  }
}

/// "4 min" in green with a live-signal glyph, or "~6 min" in gray with a
/// clock when the prediction isn't backed by live GPS.
class EtaLabel extends StatelessWidget {
  final Eta? eta;
  final double fontSize;

  const EtaLabel(this.eta, {super.key, this.fontSize = 17});

  @override
  Widget build(BuildContext context) {
    final ios = IosColors.of(context);
    final e = eta;
    if (e == null) {
      return Text('—', style: TextStyle(color: ios.secondaryLabel));
    }
    final color = e.live ? ios.live : ios.secondaryLabel;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          e.live
              ? CupertinoIcons.antenna_radiowaves_left_right
              : CupertinoIcons.clock,
          size: fontSize * 0.75,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          e.label,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Gray circular close button (Apple Maps card style).
class CloseCircle extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;

  const CloseCircle({
    super.key,
    required this.onTap,
    this.icon = CupertinoIcons.xmark,
  });

  @override
  Widget build(BuildContext context) {
    final ios = IosColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(color: ios.fill, shape: BoxShape.circle),
        child: Icon(icon, size: 14, color: ios.secondaryLabel),
      ),
    );
  }
}

/// Floating translucent box for map controls.
class MapControlBox extends StatelessWidget {
  final List<Widget> children;

  const MapControlBox({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final ios = IosColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: ColoredBox(
            color: ios.sheet,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    Container(width: 44, height: 0.5, color: ios.separator),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool active;

  const MapControlButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final ios = IosColors.of(context);
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            size: 20,
            color: active ? ios.tint : ios.secondaryLabel,
          ),
        ),
      ),
    );
  }
}

/// Small pill used for amenities and status ("Acessível", "Sem sinal").
class InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const InfoPill({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ios = IosColors.of(context);
    final c = color ?? ios.secondaryLabel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.14) ?? ios.fill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}
