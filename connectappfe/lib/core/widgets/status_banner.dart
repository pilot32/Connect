import 'package:connectappfe/core/theme/app_colors.dart';
import 'package:connectappfe/core/theme/app_tokens.dart';
import 'package:connectappfe/core/widgets/app_animated_size.dart';
import 'package:flutter/material.dart';

enum StatusTone { error, success, info }

/// Inline message strip that animates its own height open and closed.
///
/// Preferred over a SnackBar for form-level failures: it stays put next to the
/// inputs the user is about to fix, instead of vanishing on a timer.
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    required this.message,
    super.key,
    this.tone = StatusTone.error,
  });

  /// Null collapses the banner entirely.
  final String? message;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (Color fg, Color bg, IconData icon) = switch (tone) {
      StatusTone.error => (
        AppColors.error,
        AppColors.errorWash,
        Icons.error_outline_rounded,
      ),
      StatusTone.success => (
        AppColors.success,
        AppColors.successWash,
        Icons.check_circle_outline_rounded,
      ),
      StatusTone.info => (
        AppColors.brand,
        AppColors.brandWash,
        Icons.info_outline_rounded,
      ),
    };

    return AppAnimatedSize(
      child: AnimatedSwitcher(
        duration: context.motion(AppMotion.base),
        switchInCurve: AppMotion.enter,
        transitionBuilder: (child, animation) {
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
            ? const SizedBox(
                width: double.infinity,
                key: ValueKey<String>('empty'),
              )
            : Padding(
                key: ValueKey<String>('$tone:$message'),
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                // This banner is the *only* error surface on login, signup,
                // edit-profile and the post composer — all of which unfocus
                // the form right before showing it, so nothing else would
                // move accessibility focus here. `liveRegion: true` makes a
                // screen reader announce it the moment it appears, same as it
                // would for a SnackBar, instead of the failure being visible
                // but silent to a screen-reader user.
                child: Semantics(
                  liveRegion: true,
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
      ),
    );
  }
}
