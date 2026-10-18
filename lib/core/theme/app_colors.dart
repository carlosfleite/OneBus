import 'package:flutter/material.dart';

/// OneBus palette: a bus-sign yellow for the brand, iOS system colors for
/// everything interactive, and vivid line colors that read on the map.
class AppColors {
  AppColors._();

  // Brand.
  static const brandYellow = Color(0xFFFFC72C);
  static const brandInk = Color(0xFF141414);

  // Line colors (white text must stay readable on them).
  static const lineBlue = Color(0xFF0A7AFF);
  static const lineGreen = Color(0xFF1E9E50);
  static const lineIndigo = Color(0xFF5856D6);
  static const lineOrange = Color(0xFFF2612E);

  // iOS system colors (light / dark variants).
  static const blue = Color(0xFF007AFF);
  static const blueDark = Color(0xFF0A84FF);
  static const green = Color(0xFF34C759);
  static const greenDark = Color(0xFF30D158);
  static const orange = Color(0xFFFF9500);
  static const red = Color(0xFFFF3B30);
  static const gray = Color(0xFF8E8E93);
}

/// iOS semantic colors that Material's ColorScheme has no slot for.
@immutable
class IosColors extends ThemeExtension<IosColors> {
  /// Grouped list background (behind inset sections).
  final Color groupedBackground;

  /// Cell / card background inside grouped lists.
  final Color cell;

  /// Translucent sheet material over the map.
  final Color sheet;
  final Color label;
  final Color secondaryLabel;
  final Color tertiaryLabel;
  final Color separator;

  /// Search field / segmented control fill.
  final Color fill;
  final Color tint;
  final Color live;

  const IosColors({
    required this.groupedBackground,
    required this.cell,
    required this.sheet,
    required this.label,
    required this.secondaryLabel,
    required this.tertiaryLabel,
    required this.separator,
    required this.fill,
    required this.tint,
    required this.live,
  });

  static const light = IosColors(
    groupedBackground: Color(0xFFF2F2F7),
    cell: Color(0xFFFFFFFF),
    sheet: Color(0xF2F7F7F9),
    label: Color(0xFF000000),
    secondaryLabel: Color(0x993C3C43),
    tertiaryLabel: Color(0x4D3C3C43),
    separator: Color(0x4A3C3C43),
    fill: Color(0x1F767680),
    tint: AppColors.blue,
    live: Color(0xFF1FA34A),
  );

  static const dark = IosColors(
    groupedBackground: Color(0xFF000000),
    cell: Color(0xFF1C1C1E),
    sheet: Color(0xEB1C1C1E),
    label: Color(0xFFFFFFFF),
    secondaryLabel: Color(0x99EBEBF5),
    tertiaryLabel: Color(0x4DEBEBF5),
    separator: Color(0x99545458),
    fill: Color(0x3D767680),
    tint: AppColors.blueDark,
    live: AppColors.greenDark,
  );

  static IosColors of(BuildContext context) =>
      Theme.of(context).extension<IosColors>()!;

  @override
  IosColors copyWith() => this;

  @override
  IosColors lerp(IosColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return IosColors(
      groupedBackground: c(groupedBackground, other.groupedBackground),
      cell: c(cell, other.cell),
      sheet: c(sheet, other.sheet),
      label: c(label, other.label),
      secondaryLabel: c(secondaryLabel, other.secondaryLabel),
      tertiaryLabel: c(tertiaryLabel, other.tertiaryLabel),
      separator: c(separator, other.separator),
      fill: c(fill, other.fill),
      tint: c(tint, other.tint),
      live: c(live, other.live),
    );
  }
}
