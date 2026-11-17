import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// OneBus design system: black & yellow, Plus Jakarta Sans, generous radii.
class AppTheme {
  AppTheme._();

  /// Corner radius shared by cards, fields and buttons.
  static const radius = 16.0;

  static ThemeData light() => _build(Brightness.light, AppPalette.light);

  static ThemeData dark() => _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette p) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandYellow,
      brightness: brightness,
      primary: p.accent,
      onPrimary: p.onAccent,
      secondary: p.ink,
      onSecondary: p.onInk,
      surface: p.cell,
      onSurface: p.label,
      onSurfaceVariant: p.secondaryLabel,
      outlineVariant: p.separator,
      error: AppColors.red,
    );

    TextStyle s(double size, FontWeight w, {double spacing = 0}) =>
        GoogleFonts.plusJakartaSans(
          fontSize: size,
          fontWeight: w,
          letterSpacing: spacing,
          color: p.label,
          height: 1.3,
        );

    final text = TextTheme(
      displaySmall: s(34, FontWeight.w800, spacing: -1), // Large title
      headlineMedium: s(28, FontWeight.w800, spacing: -0.8), // Title 1
      headlineSmall: s(22, FontWeight.w800, spacing: -0.5), // Title 2
      titleLarge: s(20, FontWeight.w700, spacing: -0.4), // Title 3
      titleMedium: s(16, FontWeight.w700, spacing: -0.2), // Headline
      bodyLarge: s(16, FontWeight.w500, spacing: -0.2), // Body
      bodyMedium: s(14, FontWeight.w500, spacing: -0.1), // Subheadline
      bodySmall: s(12.5, FontWeight.w500), // Footnote
      labelLarge: s(16, FontWeight.w700, spacing: -0.2),
      labelMedium: s(12, FontWeight.w500), // Caption 1
      labelSmall: s(11, FontWeight.w600, spacing: 0.1), // Caption 2
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.groupedBackground,
      textTheme: text,
      extensions: [p],
      splashFactory: InkRipple.splashFactory,
      splashColor: p.accent.withValues(alpha: 0.18),
      highlightColor: p.fill,
      dividerTheme: DividerThemeData(
        color: p.separator,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.groupedBackground,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.tertiaryLabel,
        dragHandleSize: const Size(40, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.cell,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium?.copyWith(color: p.secondaryLabel),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          disabledBackgroundColor: p.accent.withValues(alpha: 0.4),
          disabledForegroundColor: p.onAccent.withValues(alpha: 0.6),
          minimumSize: const Size.fromHeight(54),
          textStyle: text.labelLarge,
          shape: shape,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.label,
          minimumSize: const Size.fromHeight(54),
          textStyle: text.labelLarge,
          side: BorderSide(color: p.separator, width: 1.5),
          shape: shape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.tint,
          minimumSize: const Size(48, 48),
          textStyle: text.labelLarge?.copyWith(fontSize: 15),
          shape: shape,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (st) => st.contains(WidgetState.selected) ? p.onAccent : p.cell,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (st) => st.contains(WidgetState.selected)
              ? p.accent
              : p.tertiaryLabel.withValues(alpha: 0.5),
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.cell,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: text.bodyLarge?.copyWith(color: p.tertiaryLabel),
        labelStyle: text.bodyMedium?.copyWith(color: p.secondaryLabel),
        floatingLabelStyle: text.labelMedium?.copyWith(
          color: p.label,
          fontWeight: FontWeight.w700,
        ),
        border: _border(p.separator, 1.5),
        enabledBorder: _border(p.separator, 1.5),
        focusedBorder: _border(p.accent, 2.5),
        errorBorder: _border(AppColors.red, 1.5),
        focusedErrorBorder: _border(AppColors.red, 2.5),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.brandInk,
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static OutlineInputBorder _border(Color color, double width) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: color, width: width),
      );
}
