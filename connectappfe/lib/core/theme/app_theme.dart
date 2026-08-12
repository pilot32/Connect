import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

/// The app's single [ThemeData].
///
/// Light-only by product decision: Connect is a light-mode app and does not
/// follow the system setting. The dark palette in [AppColors] is kept in place
/// so a future dark theme doesn't start from scratch, but there is no dark
/// [ThemeData] to fall into and no `isDark` branching left anywhere.
///
/// Typography uses the platform font (no font files are bundled) but applies a
/// deliberate scale: tight, slightly negative tracking on large display text,
/// looser tracking on small caps-ish labels. That alone moves the app away from
/// stock Material without pulling a font dependency.
class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build();

  static ThemeData _build() {
    const ColorScheme scheme = ColorScheme.light(
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

    const Color textPrimary = AppColors.textPrimary;
    const Color textSecondary = AppColors.textSecondary;
    const Color border = AppColors.border;
    const Color fieldFill = AppColors.surfaceAlt;

    const TextTheme textTheme = TextTheme(
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
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: textPrimary,
        titleTextStyle: TextStyle(
          fontSize: 18,
          height: 1.35,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          color: textPrimary,
        ),
        // Dark status-bar icons: every AppBar in the app sits on a light surface.
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.brandWash,
        elevation: 0,
        height: 66,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (Set<WidgetState> states) => TextStyle(
            fontSize: 11.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.brand
                : AppColors.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (Set<WidgetState> states) => IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected)
                ? AppColors.brand
                : AppColors.textSecondary,
          ),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        dividerColor: border,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.brand,
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        labelStyle: textTheme.labelMedium,
        showCheckmark: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        // textTertiary on this fill is ~2.85:1 — well under the WCAG AA 4.5:1
        // floor for normal-weight 16px text, and there is no background in
        // this app it would pass against. textSecondary clears ~5.3:1.
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: AppColors.textSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1.6),
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: AppColors.error),
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
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand,
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brand,
        linearTrackColor: AppColors.brandWash,
        circularTrackColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.brandInk,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        insetPadding: const EdgeInsets.all(AppSpacing.md),
      ),
      // No pageTransitionsTheme: every route in app_router.dart supplies its
      // own CustomTransitionPage, so a global builder would never be consulted.
    );
  }
}
