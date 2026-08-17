import 'package:connectappfe/core/models/models.dart';
import 'package:connectappfe/core/theme/app_colors.dart';
import 'package:connectappfe/core/theme/app_tokens.dart';
import 'package:connectappfe/core/widgets/user_avatar.dart';
import 'package:flutter/material.dart';

/// Brand-gradient header card used by both the own-profile and public-profile
/// screens, so a person's identity is presented identically either way.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.profile,
    super.key,
    this.email,
    this.action,
    this.heroTag,
  });

  final UserProfile? profile;

  /// Only shown for the signed-in user — the API never returns other people's.
  final String? email;
  final Widget? action;

  /// Receives the avatar Hero flying in from the list the user tapped.
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.brand, AppColors.brandDeep],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.26),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              UserAvatar(
                profile: profile,
                size: 68,
                onLight: false,
                heroTag: heroTag,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      profile?.name ?? '—',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    if (profile != null && profile!.designation.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          profile!.designation,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    if (email != null && email!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          email!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.62),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (profile != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                if (profile!.service.isNotEmpty) _Chip(label: profile!.service),
                if (profile!.stateOrCadre.isNotEmpty)
                  _Chip(label: profile!.stateOrCadre),
                _Chip(
                  label: profile!.yearsInService == 1
                      ? '1 year in service'
                      : '${profile!.yearsInService} years in service',
                ),
              ],
            ),
          ],
          if (action != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            action!,
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Label/value row used for the detail list beneath the header.
class ProfileDetailRow extends StatelessWidget {
  const ProfileDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 19, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: theme.textTheme.labelSmall),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '—' : value,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
