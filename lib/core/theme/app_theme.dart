import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// iOS-flavoured theme: Inter (closest open font to SF Pro), Apple's type
/// ramp and semantic colors, flat surfaces, no Material tints or ripples.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light, IosColors.light);

  static ThemeData dark() => _build(Brightness.dark, IosColors.dark);

  static ThemeData _build(Brightness brightness, IosColors ios) {
    final scheme = ColorScheme.fromSeed(
      seedColor: ios.tint,
      brightness: brightness,
      primary: ios.tint,
      onPrimary: Colors.white,
      surface: ios.cell,
      onSurface: ios.label,
      onSurfaceVariant: ios.secondaryLabel,
      outlineVariant: ios.separator,
      error: AppColors.red,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: ios.groupedBackground,
      splashFactory: NoSplash.splashFactory,
      highlightColor: ios.fill,
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: ios.tint,
        textTheme: CupertinoTextThemeData(
          primaryColor: ios.tint,
          textStyle: GoogleFonts.inter(fontSize: 17, color: ios.label),
          actionTextStyle: GoogleFonts.inter(fontSize: 17, color: ios.tint),
          navTitleTextStyle: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            color: ios.label,
          ),
          navLargeTitleTextStyle: GoogleFonts.inter(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            color: ios.label,
          ),
          navActionTextStyle: GoogleFonts.inter(fontSize: 17, color: ios.tint),
        ),
      ),
    );

    TextStyle s(double size, FontWeight w, {double spacing = 0}) =>
        GoogleFonts.inter(
          fontSize: size,
          fontWeight: w,
          letterSpacing: spacing,
          color: ios.label,
          height: 1.25,
        );

    // Apple HIG type ramp.
    final text = TextTheme(
      displaySmall: s(34, FontWeight.w700, spacing: -0.8), // Large Title
      headlineMedium: s(28, FontWeight.w700, spacing: -0.6), // Title 1
      headlineSmall: s(22, FontWeight.w700, spacing: -0.4), // Title 2
      titleLarge: s(20, FontWeight.w600, spacing: -0.4), // Title 3
      titleMedium: s(17, FontWeight.w600, spacing: -0.4), // Headline
      bodyLarge: s(17, FontWeight.w400, spacing: -0.4), // Body
      bodyMedium: s(15, FontWeight.w400, spacing: -0.2), // Subheadline
      bodySmall: s(13, FontWeight.w400, spacing: -0.1), // Footnote
      labelLarge: s(17, FontWeight.w500, spacing: -0.4),
      labelMedium: s(12, FontWeight.w400), // Caption 1
      labelSmall: s(11, FontWeight.w500, spacing: 0.1), // Caption 2
    );

    return base.copyWith(
      textTheme: text,
      extensions: [ios],
      dividerTheme: DividerThemeData(color: ios.separator, thickness: 0.5),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: ios.groupedBackground,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: ios.tertiaryLabel,
        dragHandleSize: const Size(36, 5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ios.tint,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          textStyle: text.titleMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ios.tint,
          textStyle: text.bodyLarge,
        ),
      ),
    );
  }
}
