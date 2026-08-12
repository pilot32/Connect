import 'package:flutter/material.dart';

/// Brand palette for Connect.
///
/// The identity leans on a deep "civic blue" (authority, trust) offset by a
/// brass accent that reads as institutional — closer to a government seal than
/// to a consumer social app. Neutrals are slightly blue-tinted so surfaces sit
/// cohesively against the brand rather than looking like flat greys.
class AppColors {
  const AppColors._();

  // ---------------------------------------------------------------- brand
  static const Color brand = Color(0xFF0F4C81);
  static const Color brandDeep = Color(0xFF0A3560);
  static const Color brandBright = Color(0xFF2E7ABF);
  static const Color brandInk = Color(0xFF071B2E);

  /// Very light brand wash, for selected rows / subtle fills on light surfaces.
  static const Color brandWash = Color(0xFFEAF2FA);

  // --------------------------------------------------------------- accent
  static const Color accent = Color(0xFFB8862F);
  static const Color accentBright = Color(0xFFD9A648);
  static const Color accentWash = Color(0xFFF7EFDF);

  // ------------------------------------------------------- neutrals (light)
  static const Color background = Color(0xFFF2F6FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF6F9FC);
  static const Color border = Color(0xFFDCE4ED);
  static const Color borderStrong = Color(0xFFC3D0DE);

  static const Color textPrimary = Color(0xFF0E1F30);
  static const Color textSecondary = Color(0xFF546A80);
  static const Color textTertiary = Color(0xFF8497A9);

  // -------------------------------------------------------- neutrals (dark)
  static const Color backgroundDark = Color(0xFF07111C);
  static const Color surfaceDark = Color(0xFF0E1D2C);
  static const Color surfaceAltDark = Color(0xFF152838);
  static const Color borderDark = Color(0xFF22394E);
  static const Color borderStrongDark = Color(0xFF31506B);

  static const Color textPrimaryDark = Color(0xFFE7EEF6);
  static const Color textSecondaryDark = Color(0xFF9BAFC3);
  static const Color textTertiaryDark = Color(0xFF6C8299);

  // ------------------------------------------------------------- semantic
  static const Color success = Color(0xFF17795E);
  static const Color successWash = Color(0xFFE3F4EE);
  static const Color error = Color(0xFFB3261E);
  static const Color errorWash = Color(0xFFFBEBE9);
  static const Color warning = Color(0xFFA96A00);
  static const Color warningWash = Color(0xFFFBF0E0);

  /// Gradient used behind the auth screens' decorative field.
  static const List<Color> authAurora = <Color>[
    Color(0xFF0F4C81),
    Color(0xFF11395F),
    Color(0xFF071B2E),
  ];
}
