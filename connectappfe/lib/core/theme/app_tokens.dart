import 'package:flutter/animation.dart';

/// 4pt-based spacing scale. Using named steps instead of raw numbers keeps
/// rhythm consistent across screens built at different times.
class AppSpacing {
  const AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double huge = 64;

  /// Horizontal page gutter.
  static const double gutter = 24;
}

class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 22;
  static const double pill = 999;
}

/// Motion tokens. Durations and curves live together so every animated
/// surface in the app moves with the same personality.
class AppMotion {
  const AppMotion._();

  static const Duration instant = Duration(milliseconds: 90);
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration base = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration slower = Duration(milliseconds: 650);

  /// Decelerating curve for elements entering the screen.
  static const Curve enter = Curves.easeOutCubic;

  /// Accelerating curve for elements leaving.
  static const Curve exit = Curves.easeInCubic;

  /// Material 3 "emphasized" easing — snappy start, soft landing. Used for
  /// anything the user directly triggers.
  static const Curve emphasized = Cubic(0.2, 0, 0, 1);

  /// Slight overshoot, for confirmations and success states.
  static const Curve overshoot = Curves.easeOutBack;

  /// Per-item delay when staggering a list/form into view.
  static const Duration stagger = Duration(milliseconds: 65);
}
