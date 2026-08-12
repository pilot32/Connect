import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

enum StatusTone { error, success, info }

/// Inline message strip that animates its own height open and closed.
///
/// Preferred over a SnackBar for form-level failures: it stays put next to the
/// inputs the user is about to fix, instead of vanishing on a timer.
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.message,
    this.tone = StatusTone.error,
  });

  /// Null collapses the banner entirely.
  final String? message;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final (Color fg, Color bg, IconData icon) = switch (tone) {
      StatusTone.error => (
          AppColors.error,
          isDark ? AppColors.error.withValues(alpha: 0.16) : AppColors.errorWash,
          Icons.error_outline_rounded,
        ),
      StatusTone.success => (
          AppColors.success,
          isDark
              ? AppColors.success.withValues(alpha: 0.16)
              : AppColors.successWash,
          Icons.check_circle_outline_rounded,
        ),
      StatusTone.info => (
          AppColors.brand,
          isDark ? AppColors.brand.withValues(alpha: 0.16) : AppColors.brandWash,
          Icons.info_outline_rounded,
        ),
    };

    return AnimatedSize(
      duration: AppMotion.base,
      curve: AppMotion.emphasized,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: AppMotion.base,
        switchInCurve: AppMotion.enter,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1,
              child: child,
            ),
          );
        },
        child: message == null
            ? const SizedBox(width: double.infinity, key: ValueKey<String>('empty'))
            : Padding(
                key: ValueKey<String>('$tone:$message'),
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: fg.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(icon, size: 19, color: fg),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          message!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
