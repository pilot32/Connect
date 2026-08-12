import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_colors.dart';

/// Circular avatar that falls back to initials on a brand-tinted disc when the
/// user has no photo — which is common, since the profile photo is optional at
/// signup.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.profile,
    this.size = 48,
    this.onLight = true,
  });

  final UserProfile? profile;
  final double size;

  /// Whether the avatar sits on a light surface. Controls the fallback colours
  /// so initials stay legible on the dark brand gradients too.
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
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

    return Container(
      height: size,
      width: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: onLight
            ? theme.colorScheme.primary.withValues(alpha: 0.10)
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
              loadingBuilder: (
                BuildContext context,
                Widget child,
                ImageChunkEvent? progress,
              ) {
                if (progress == null) return child;
                return fallback;
              },
            ),
    );
  }
}
