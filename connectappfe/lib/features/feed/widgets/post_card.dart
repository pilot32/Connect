import 'package:connectappfe/core/theme/app_tokens.dart';
import 'package:connectappfe/core/utils/relative_time.dart';
import 'package:connectappfe/core/widgets/skeleton.dart';
import 'package:connectappfe/core/widgets/user_avatar.dart';
import 'package:connectappfe/features/feed/models/post.dart';
import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    required this.post,
    super.key,
    this.onAuthorTap,
    this.heroTag,
  });

  final Post post;
  final VoidCallback? onAuthorTap;

  /// Hero tag for the author avatar; namespaced per tab by the caller.
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photo = post.photoUrl;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                GestureDetector(
                  onTap: onAuthorTap,
                  child: UserAvatar(
                    profile: post.author.profile,
                    size: 42,
                    heroTag: heroTag,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      GestureDetector(
                        onTap: onAuthorTap,
                        child: Text(
                          post.author.displayName,
                          style: theme.textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        <String>[
                          if (post.author.profile?.headline.isNotEmpty ?? false)
                            post.author.profile!.headline,
                          relativeTime(post.createdAt),
                        ].where((s) => s.isNotEmpty).join(' · '),
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Text(
              post.content,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
            ),
          ),
          if (photo != null && photo.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 340),
              child: Image.network(
                photo,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
                // Fades the photo in over its shimmer once decoded, instead of
                // the image snapping into place and shoving the layout.
                frameBuilder:
                    (
                      context,
                      child,
                      frame,
                      wasSynchronouslyLoaded,
                    ) {
                      if (wasSynchronouslyLoaded) return child;
                      return AnimatedSwitcher(
                        duration: context.motion(AppMotion.slower),
                        switchInCurve: AppMotion.enter,
                        child: frame == null
                            ? const SizedBox(
                                key: ValueKey<String>('loading'),
                                height: 190,
                                width: double.infinity,
                                child: SkeletonBox(
                                  height: 190,
                                  radius: 0,
                                ),
                              )
                            : KeyedSubtree(
                                key: const ValueKey<String>('image'),
                                child: child,
                              ),
                      );
                    },
              ),
            ),
        ],
      ),
    );
  }
}
