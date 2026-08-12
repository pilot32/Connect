import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

/// Builds the light and dark [ThemeData] for Connect.
///
/// Typography uses the platform font (no font files are bundled) but applies a
/// deliberate scale: tight, slightly negative tracking on large display text,
/// looser tracking on small caps-ish labels. That alone moves the app away from
/// stock Material without pulling a font dependency.
class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    final ColorScheme scheme = isDark
        ? const ColorScheme.dark(
            primary: AppColors.brandBright,
            onPrimary: Color(0xFF04121F),
            primaryContainer: Color(0xFF10314F),
            onPrimaryContainer: Color(0xFFCFE3F6),
            secondary: AppColors.accentBright,
            onSecondary: Color(0xFF241802),
            secondaryContainer: Color(0xFF3A2C0E),
            onSecondaryContainer: Color(0xFFF3E2C2),
            tertiary: Color(0xFF4FB39A),
            onTertiary: Color(0xFF04211A),
            error: Color(0xFFE9877F),
            onError: Color(0xFF2B0906),
            errorContainer: Color(0xFF4A1712),
            onErrorContainer: Color(0xFFFAD9D5),
            surface: AppColors.surfaceDark,
            onSurface: AppColors.textPrimaryDark,
            outline: AppColors.borderDark,
            outlineVariant: Color(0xFF1A2E40),
            inverseSurface: Color(0xFFE7EEF6),
            onInverseSurface: Color(0xFF0E1D2C),
          )
        : const ColorScheme.light(
            primary: AppColors.brand,
            onPrimary: Colors.white,
            primaryContainer: AppColors.brandWash,
            onPrimaryContainer: AppColors.brandDeep,
            secondary: AppColors.accent,
            onSecondary: Colors.white,
            secondaryContainer: AppColors.accentWash,
            onSecondaryContainer: Color(0xFF5C420F),
            tertiary: AppColors.success,
            onTertiary: Colors.white,
            error: AppColors.error,
            onError: Colors.white,
            errorContainer: AppColors.errorWash,
            onErrorContainer: Color(0xFF6E170F),
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
            outline: AppColors.border,
            outlineVariant: Color(0xFFE8EEF5),
            inverseSurface: AppColors.brandInk,
            onInverseSurface: Colors.white,
          );

    final Color textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final Color textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final Color border = isDark ? AppColors.borderDark : AppColors.border;
    final Color fieldFill =
        isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt;

    final TextTheme textTheme = TextTheme(
      displaySmall: TextStyle(
        fontSize: 34,
        height: 1.14,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: textPrimary,
      ),
      headlineLarge: TextStyle(
        fontSize: 28,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 23,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        height: 1.35,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14.5,
        height: 1.55,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: 15,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: textPrimary,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: textSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 11.5,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: textSecondary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.background,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: textPrimary,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: scheme.error),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.surfaceAltDark : AppColors.brandInk,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        insetPadding: const EdgeInsets.all(AppSpacing.md),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
