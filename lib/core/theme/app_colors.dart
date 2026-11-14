import 'package:flutter/material.dart';

/// OneBus palette: deep black / graphite surfaces, an urban yellow for
/// everything that asks for attention, and neutral grays for the rest.
class AppColors {
  AppColors._();

  // Brand.
  static const brandYellow = Color(0xFFFFD60A);
  static const brandYellowAlt = Color(0xFFFACC15);
  static const brandInk = Color(0xFF0D0D0F);
  static const graphite = Color(0xFF16161A);

  // Line colors (white text must stay readable on them).
  static const lineBlue = Color(0xFF0A7AFF);
  static const lineGreen = Color(0xFF1E9E50);
  static const lineIndigo = Color(0xFF5856D6);
  static const lineOrange = Color(0xFFF2612E);

  // Semantic colors.
  static const blue = Color(0xFF2F80ED);
  static const green = Color(0xFF22C55E);
  static const greenDark = Color(0xFF4ADE80);
  static const orange = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
  static const gray = Color(0xFF71717A);
}

/// Semantic colors that Material's ColorScheme has no slot for. The field
/// names are kept from the previous theme so every screen follows the new
/// identity without changes.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  /// Page background (behind inset sections).
  final Color groupedBackground;

  /// Card / row background inside lists.
  final Color cell;

  /// Translucent sheet material over the map.
  final Color sheet;
  final Color label;
  final Color secondaryLabel;
  final Color tertiaryLabel;
  final Color separator;

  /// Search field / segmented control fill.
  final Color fill;

  /// Color for links and text that must read on [cell] (a deep amber on
  /// light surfaces, the brand yellow on dark ones).
  final Color tint;

  /// Brand yellow for filled elements (buttons, active tab, badges).
  final Color accent;

  /// Text / icons drawn on top of [accent].
  final Color onAccent;

  /// Highlight surface (header, pass card, navigation bar).
  final Color ink;
  final Color onInk;
  final Color live;

  const AppPalette({
    required this.groupedBackground,
    required this.cell,
    required this.sheet,
    required this.label,
    required this.secondaryLabel,
    required this.tertiaryLabel,
    required this.separator,
    required this.fill,
    required this.tint,
    required this.accent,
    required this.onAccent,
    required this.ink,
    required this.onInk,
    required this.live,
  });

  static const light = AppPalette(
    groupedBackground: Color(0xFFF4F4F5),
    cell: Color(0xFFFFFFFF),
    sheet: Color(0xF2FFFFFF),
    label: Color(0xFF0D0D0F),
    secondaryLabel: Color(0xFF5E5E66),
    tertiaryLabel: Color(0xFF9A9AA3),
    separator: Color(0xFFE4E4E7),
    fill: Color(0xFFEDEDF0),
    tint: Color(0xFF8A6100),
    accent: AppColors.brandYellow,
    onAccent: AppColors.brandInk,
    ink: AppColors.brandInk,
    onInk: Color(0xFFFFFFFF),
    live: Color(0xFF15803D),
  );

  static const dark = AppPalette(
    groupedBackground: Color(0xFF0D0D0F),
    cell: Color(0xFF16161A),
    sheet: Color(0xEB16161A),
    label: Color(0xFFF5F5F5),
    secondaryLabel: Color(0xFFA1A1AA),
    tertiaryLabel: Color(0xFF6B6B73),
    separator: Color(0xFF26262C),
    fill: Color(0xFF23232A),
    tint: AppColors.brandYellow,
    accent: AppColors.brandYellow,
    onAccent: AppColors.brandInk,
    ink: Color(0xFF000000),
    onInk: Color(0xFFFFFFFF),
    live: AppColors.greenDark,
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>()!;

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      groupedBackground: c(groupedBackground, other.groupedBackground),
      cell: c(cell, other.cell),
      sheet: c(sheet, other.sheet),
      label: c(label, other.label),
      secondaryLabel: c(secondaryLabel, other.secondaryLabel),
      tertiaryLabel: c(tertiaryLabel, other.tertiaryLabel),
      separator: c(separator, other.separator),
      fill: c(fill, other.fill),
      tint: c(tint, other.tint),
      accent: c(accent, other.accent),
      onAccent: c(onAccent, other.onAccent),
      ink: c(ink, other.ink),
      onInk: c(onInk, other.onInk),
      live: c(live, other.live),
    );
  }
}
