import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Circular avatar that falls back to initials on a brand-tinted disc when the
/// user has no photo — which is common, since the profile photo is optional at
/// signup.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.profile,
    this.size = 48,
    this.onLight = true,
    this.heroTag,
  });

  final UserProfile? profile;
  final double size;

  /// Whether the avatar sits on a light surface. Controls the fallback colours
  /// so initials stay legible on the dark brand gradients too.
  final bool onLight;

  /// Opt-in Hero tag for flying this avatar into a profile screen.
  ///
  /// Deliberately caller-supplied rather than derived from the user id: the
  /// bottom-nav shell keeps every tab alive at once, so the same person can be
  /// on screen in Feed and Search simultaneously. Two Heroes sharing a tag in
  /// one route throws, so callers namespace by source (see `AvatarHeroTag`).
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final String initials = profile?.initials ?? '?';
    final String? url = profile?.photoUrl;

    final Widget fallback = Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: onLight ? AppColors.brand : Colors.white,
        ),
      ),
    );

    Widget avatar = Container(
      height: size,
      width: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: onLight
            ? AppColors.brand.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.18),
        border: onLight
            ? null
            : Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
      ),
      child: url == null || url.isEmpty
          ? fallback
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
              frameBuilder: (
                BuildContext context,
                Widget child,
                int? frame,
                bool wasSynchronouslyLoaded,
              ) {
                if (wasSynchronouslyLoaded) return child;
                // Cross-fade the photo in over the initials rather than
                // popping, which is jarring in a scrolling list.
                return AnimatedSwitcher(
                  duration: context.motion(AppMotion.slow),
                  child: frame == null
                      ? KeyedSubtree(
                          key: const ValueKey<String>('placeholder'),
                          child: fallback,
                        )
                      : KeyedSubtree(
                          key: const ValueKey<String>('photo'),
                          child: child,
                        ),
                );
              },
            ),
    );

    if (heroTag != null) {
      avatar = Hero(
        tag: heroTag!,
        // Keep it a circle mid-flight; the default rect tween would square it
        // off as the size interpolates.
        flightShuttleBuilder: (
          BuildContext flightContext,
          Animation<double> animation,
          HeroFlightDirection direction,
          BuildContext fromContext,
          BuildContext toContext,
        ) =>
            ClipOval(child: Material(type: MaterialType.transparency, child: avatar)),
        child: avatar,
      );
    }

    return avatar;
  }
}

/// Builds Hero tags that are unique within the whole mounted tree.
///
/// Two rules drive the shape of these:
///
/// 1. The shell keeps all four tabs mounted at once, so tagging purely by user
///    id would collide the moment the same official appears in two tabs.
///    Hence the per-source namespace.
/// 2. Within the feed, one author can have many posts, so the feed tag is keyed
///    by *post* id rather than author id — keying by author would put two
///    identical tags in one list as soon as someone posts twice, and Flutter
///    throws on duplicate Hero tags in a subtree.
class AvatarHeroTag {
  const AvatarHeroTag._();

  /// Keyed by post, not author — see rule 2 above.
  static String feedPost(String postId) => 'avatar-feed-post-$postId';

  /// Directory results are one row per official, so the user id is unique here.
  static String search(String userId) => 'avatar-search-$userId';

  /// A user appears at most once in the accepted-connections list.
  static String network(String userId) => 'avatar-network-$userId';
}
