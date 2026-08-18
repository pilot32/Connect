import 'package:connectappfe/core/models/models.dart';
import 'package:connectappfe/core/theme/app_colors.dart';
import 'package:connectappfe/core/theme/app_tokens.dart';
import 'package:connectappfe/core/utils/relative_time.dart';
import 'package:connectappfe/core/widgets/user_avatar.dart';
import 'package:connectappfe/features/admin/models/applicant.dart';
import 'package:connectappfe/features/admin/widgets/id_card_viewer.dart';
import 'package:connectappfe/features/admin/widgets/status_pill.dart';
import 'package:flutter/material.dart';

/// One applicant, with everything the decision rests on and the two buttons
/// that make it.
///
/// Deliberately a card rather than a tap-through to a detail screen: an admin
/// works a queue, and making them open and back out of every applicant to see
/// a department would triple the taps for a decision that is usually obvious
/// from the summary. The one thing that genuinely can't fit — the ID card —
/// opens on demand.
class ApplicantCard extends StatelessWidget {
  const ApplicantCard({
    required this.applicant,
    required this.busy,
    required this.onApprove,
    required this.onReject,
    super.key,
  });

  final Applicant applicant;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = applicant.profile;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              UserAvatar(profile: profile, size: 52),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      applicant.displayName,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((profile?.designation ?? '').isNotEmpty)
                      Text(
                        profile!.designation,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              StatusPill(status: applicant.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          if (profile != null)
            Wrap(
              spacing: AppSpacing.xxs,
              runSpacing: AppSpacing.xxs,
              children: <Widget>[
                if (profile.service.isNotEmpty)
                  _Fact(
                    icon: Icons.shield_outlined,
                    value: profile.service,
                    emphasise: true,
                  ),
                if (profile.department.isNotEmpty)
                  _Fact(
                    icon: Icons.account_balance_outlined,
                    value: profile.department,
                  ),
                if (profile.stateOrCadre.isNotEmpty)
                  _Fact(icon: Icons.map_outlined, value: profile.stateOrCadre),
                _Fact(
                  icon: Icons.timeline_rounded,
                  value: '${profile.yearsInService} yrs in service',
                ),
              ],
            ),

          const SizedBox(height: AppSpacing.xs),
          _MetaLine(
            icon: Icons.alternate_email_rounded,
            text: applicant.email,
          ),
          _MetaLine(
            icon: Icons.schedule_rounded,
            text: applicant.createdAt == null
                ? 'Application date unknown'
                : 'Applied ${relativeTime(applicant.createdAt)} ago',
          ),
          if (applicant.reviewedAt != null)
            _MetaLine(
              icon: Icons.gavel_rounded,
              text: 'Reviewed ${relativeTime(applicant.reviewedAt)} ago',
            ),

          if ((applicant.rejectionReason ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.errorWash,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                'Reason given: ${applicant.rejectionReason}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.sm),
          _IdCardButton(applicant: applicant),
          const SizedBox(height: AppSpacing.sm),

          Row(
            children: <Widget>[
              // A rejected applicant has no Reject button and an approved one
              // has no Approve button — the action would be a no-op, and
              // offering it invites a tap that appears to do nothing.
              if (applicant.status != AccountStatus.rejected)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : onReject,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.4),
                      ),
                      minimumSize: const Size.fromHeight(46),
                    ),
                  ),
                ),
              if (applicant.status != AccountStatus.rejected &&
                  applicant.status != AccountStatus.approved)
                const SizedBox(width: AppSpacing.xs),
              if (applicant.status != AccountStatus.approved)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: busy ? null : onApprove,
                    icon: busy
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      applicant.status == AccountStatus.rejected
                          ? 'Approve anyway'
                          : 'Approve',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      minimumSize: const Size.fromHeight(46),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The ID card is the evidence the whole screen turns on, so it gets a
/// full-width affordance rather than a small thumbnail in a corner.
class _IdCardButton extends StatelessWidget {
  const _IdCardButton({required this.applicant});

  final Applicant applicant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!applicant.hasIdCard) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.warningWash,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.report_gmailerrorred_rounded,
              size: 18,
              color: AppColors.warning,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'No ID card on file — approve only if verified another way.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.warning,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: AppColors.brandWash,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showIdCardViewer(
          context,
          imageUrl: applicant.idCardPhotoUrl!,
          title: '${applicant.displayName} — government ID',
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.network(
                  applicant.idCardPhotoUrl!,
                  height: 46,
                  width: 62,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 46,
                    width: 62,
                    color: AppColors.brand.withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.broken_image_outlined,
                      size: 18,
                      color: AppColors.brand,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'View government ID card',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.brand,
                  ),
                ),
              ),
              const Icon(
                Icons.zoom_out_map_rounded,
                size: 18,
                color: AppColors.brand,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single labelled attribute chip.
class _Fact extends StatelessWidget {
  const _Fact({
    required this.icon,
    required this.value,
    this.emphasise = false,
  });

  final IconData icon;
  final String value;

  /// Service (IAS/IPS/…) is the first thing a reviewer looks for, so it reads
  /// in brand colour while the rest stay quiet.
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = emphasise ? AppColors.brand : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 5),
      decoration: BoxDecoration(
        color: emphasise ? AppColors.brandWash : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: emphasise ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
