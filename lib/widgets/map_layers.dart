import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../core/theme/app_colors.dart';
import '../data/mock_data.dart';
import 'ios.dart';

/// Shared map pieces (basemap, stop pins, user dot) for the Mapa tab and
/// the mini map on Início.

/// OpenStreetMap tiles toned down to an Apple-like palette.
class OneBusTileLayer extends StatelessWidget {
  /// Draw the OSM tiles with their original colors (light mode), so small
  /// maps keep every street legible.
  final bool plain;

  const OneBusTileLayer({super.key, this.plain = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.onebus.app',
      maxNativeZoom: 19,
      tileBuilder: isDark
          ? _darkTiles
          : plain
          ? null
          : _lightTiles,
    );
  }
}

Color mapBackground(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF1C1C1E)
    : const Color(0xFFF2EFE9);

// Calmer, Apple-like basemap: OSM tiles with reduced saturation.
const _lightTone = ColorFilter.matrix([
  0.72, 0.24, 0.04, 0, 14, //
  0.12, 0.84, 0.04, 0, 14,
  0.12, 0.24, 0.64, 0, 18,
  0, 0, 0, 1, 0,
]);

Widget _lightTiles(BuildContext context, Widget tile, TileImage image) =>
    ColorFiltered(colorFilter: _lightTone, child: tile);

Widget _darkTiles(BuildContext context, Widget tile, TileImage image) =>
    ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        -0.62, -0.30, -0.08, 0, 232, //
        -0.20, -0.72, -0.08, 0, 232,
        -0.20, -0.30, -0.50, 0, 240,
        0, 0, 0, 1, 0,
      ]),
      child: tile,
    );

/// Transit stop pin. Shows the lines that serve it underneath, and a
/// "nearest stop" callout above when it is the closest one to the user.
class StopPin extends StatelessWidget {
  final bool selected;
  final String? nearest;
  final List<String> lineIds;
  final bool accessible;

  const StopPin({
    super.key,
    required this.selected,
    this.nearest,
    this.lineIds = const [],
    this.accessible = false,
  });

  @override
  Widget build(BuildContext context) {
    final ios = IosColors.of(context);
    final highlight = selected || nearest != null;
    final s = highlight ? 28.0 : 20.0;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: s,
          height: s,
          decoration: BoxDecoration(
            color: highlight ? ios.tint : ios.cell,
            borderRadius: BorderRadius.circular(s * 0.3),
            border: Border.all(
              color: highlight ? Colors.white : ios.separator,
              width: highlight ? 2 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Icon(
            CupertinoIcons.bus,
            size: s * 0.62,
            color: highlight ? Colors.white : ios.secondaryLabel,
          ),
        ),
        if (accessible)
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.2),
              ),
              child: const Icon(
                Icons.accessible_rounded,
                size: 10,
                color: Colors.white,
                semanticLabel: 'Ponto acessível',
              ),
            ),
          ),
        if (lineIds.isNotEmpty)
          Positioned(
            top: 30,
            left: -60,
            right: -60,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: ios.cell,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: const [
                    BoxShadow(color: Color(0x26000000), blurRadius: 3),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < lineIds.length; i++) ...[
                      if (i > 0) const SizedBox(width: 2),
                      LineBadge(MockData.line(lineIds[i]), height: 16),
                    ],
                  ],
                ),
              ),
            ),
          ),
        if (nearest != null)
          Positioned(
            bottom: 32,
            left: -120,
            right: -120,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ios.tint,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33000000), blurRadius: 4),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.directions_walk_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        'Mais próximo · $nearest',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// "You are here" dot with a soft halo.
class UserDot extends StatelessWidget {
  final Color color;

  const UserDot({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(color: Color(0x40000000), blurRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}
