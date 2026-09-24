import 'package:flutter/material.dart';

/// Brand palette: warm paper, deep ink, paprika accent, sage support.
class AppColors {
  static const paprika = Color(0xFFE4572E);
  static const saffron = Color(0xFFF3A712);
  static const sage = Color(0xFF6B8F71);
  static const paper = Color(0xFFFBF6EE);
  static const paperDeep = Color(0xFFF3EADB);
  static const ink = Color(0xFF211C17);
  static const inkSoft = Color(0xFF6E655C);

  static const night = Color(0xFF161311);
  static const nightRaised = Color(0xFF221E1B);
  static const nightText = Color(0xFFF2EBE1);
  static const nightTextSoft = Color(0xFFA89E93);
}

class AppTheme {
  static const appName = 'Savora';

  static ThemeData light() => _build(
        brightness: Brightness.light,
        background: AppColors.paper,
        surface: Colors.white,
        surfaceAlt: AppColors.paperDeep,
        text: AppColors.ink,
        textSoft: AppColors.inkSoft,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        background: AppColors.night,
        surface: AppColors.nightRaised,
        surfaceAlt: const Color(0xFF2C2724),
        text: AppColors.nightText,
        textSoft: AppColors.nightTextSoft,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceAlt,
    required Color text,
    required Color textSoft,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.paprika,
      onPrimary: Colors.white,
      secondary: AppColors.sage,
      onSecondary: Colors.white,
      tertiary: AppColors.saffron,
      onTertiary: AppColors.ink,
      error: const Color(0xFFB3261E),
      onError: Colors.white,
      surface: background,
      onSurface: text,
      onSurfaceVariant: textSoft,
      surfaceContainerLowest: surface,
      surfaceContainerLow: surface,
      surfaceContainer: surfaceAlt,
      surfaceContainerHigh: surfaceAlt,
      outlineVariant: textSoft.withValues(alpha: 0.2),
    );

    final body = ThemeData(brightness: brightness)
        .textTheme
        .apply(fontFamily: 'Jakarta', bodyColor: text, displayColor: text);

    TextStyle? serif(TextStyle? s) => s?.copyWith(
          fontFamily: 'Fraunces',
          fontWeight: FontWeight.w600,
          color: text,
        );

    final textTheme = body.copyWith(
      displaySmall: serif(body.displaySmall),
      headlineLarge: serif(body.headlineLarge),
      headlineMedium: serif(body.headlineMedium),
      headlineSmall: serif(body.headlineSmall),
      titleLarge: serif(body.titleLarge),
      titleMedium: body.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      labelLarge: body.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Jakarta',
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
        foregroundColor: text,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.paprika.withValues(alpha: 0.14),
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.paprika
                : textSoft,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: TextStyle(color: textSoft),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.paprika, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
