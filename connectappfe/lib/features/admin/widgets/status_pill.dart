import 'package:connectappfe/core/models/models.dart';
import 'package:connectappfe/core/theme/app_colors.dart';
import 'package:connectappfe/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Colour-coded badge for an [AccountStatus].
///
/// Colour alone can't carry the meaning — a reviewer with a colour-vision
/// deficiency has to be able to read the queue too — so the label is always
/// spelled out beside the icon rather than the pill being a bare dot.
class StatusPill extends StatelessWidget {
  const StatusPill({required this.status, super.key});

  final AccountStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (Color fg, Color bg, IconData icon, String label) = switch (status) {
      AccountStatus.approved => (
        AppColors.success,
        AppColors.successWash,
        Icons.verified_rounded,
        'Approved',
      ),
      AccountStatus.rejected => (
        AppColors.error,
        AppColors.errorWash,
        Icons.cancel_rounded,
        'Rejected',
      ),
      AccountStatus.pending => (
        AppColors.warning,
        AppColors.warningWash,
        Icons.hourglass_top_rounded,
        'Pending',
      ),
      AccountStatus.unknown => (
        AppColors.textSecondary,
        AppColors.surfaceAlt,
        Icons.help_outline_rounded,
        'Unknown',
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: fg.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
