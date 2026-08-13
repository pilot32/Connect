import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_tokens.dart';
import 'user_avatar.dart';

/// One official in a list — directory results, network, and pending requests
/// all render through this so a person looks identical everywhere in the app.
class UserListTile extends StatelessWidget {
  const UserListTile({
    super.key,
    required this.user,
    this.trailing,
    this.onTap,
    this.subtitleOverride,
    this.heroTag,
  });

  final PublicUser user;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Hero tag for the avatar, so it flies into the profile screen. Must be
  /// namespaced per source tab — see [AvatarHeroTag].
  final Object? heroTag;

  /// Replaces the default "Designation · State" line, e.g. to show when a
  /// connection request arrived.
  final String? subtitleOverride;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final UserProfile? profile = user.profile;

    final String secondary = subtitleOverride ??
        <String>[
          if (profile != null && profile.designation.isNotEmpty)
            profile.designation,
          if (profile != null && profile.stateOrCadre.isNotEmpty)
            profile.stateOrCadre,
        ].join(' · ');

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            children: <Widget>[
              UserAvatar(profile: profile, size: 46, heroTag: heroTag),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      user.displayName,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (profile != null && profile.headline.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          profile.headline,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (secondary.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          secondary,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: AppSpacing.xs),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
