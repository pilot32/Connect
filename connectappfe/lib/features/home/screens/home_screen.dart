import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../auth/models/auth_models.dart';
import '../../auth/state/auth_controller.dart';

/// Landing screen after authentication.
///
/// Deliberately a placeholder: Directory, Connections, and Feed are the next
/// frontend passes. It proves the session survives (it renders the signed-in
/// user) and gives logout a home, so the auth loop can be exercised end to end.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AuthController auth = context.watch<AuthController>();
    final AuthUser? user = auth.user;
    final UserProfile? profile = auth.profile;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.gutter,
        title: Row(
          children: <Widget>[
            const BrandMark(size: 30, heroTag: null),
            const SizedBox(width: AppSpacing.xs),
            const BrandWordmark(fontSize: 20),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await auth.logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.md,
          AppSpacing.gutter,
          AppSpacing.xxl,
        ),
        children: <Widget>[
          FadeSlideIn(
            child: _SessionCard(
              name: profile?.name,
              email: user?.email ?? '',
              initials: profile?.initials ?? '·',
              photoUrl: profile?.photoUrl,
              designation: profile?.designation,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FadeSlideIn(
            delay: AppMotion.stagger,
            child: Text('Coming next', style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (int i = 0; i < _upcoming.length; i++)
            FadeSlideIn(
              delay: AppMotion.stagger * (i + 2),
              child: _UpcomingTile(feature: _upcoming[i]),
            ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.name,
    required this.email,
    required this.initials,
    required this.photoUrl,
    required this.designation,
  });

  final String? name;
  final String email;
  final String initials;
  final String? photoUrl;
  final String? designation;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
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
            color: AppColors.brand.withValues(alpha: 0.28),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            height: 58,
            width: 58,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: photoUrl == null
                ? Center(
                    child: Text(
                      initials,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(color: Colors.white),
                    ),
                  )
                : Image.network(
                    photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Center(
                      child: Text(
                        initials,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name ?? 'Signed in',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  designation ?? email,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The frontend passes still to come, surfaced so the placeholder screen
/// communicates the roadmap instead of looking unfinished.
class _UpcomingFeature {
  const _UpcomingFeature(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;
}

const List<_UpcomingFeature> _upcoming = <_UpcomingFeature>[
  _UpcomingFeature(
    Icons.badge_outlined,
    'Profile',
    'View and edit your professional details',
  ),
  _UpcomingFeature(
    Icons.search_rounded,
    'Directory',
    'Find officials by service, department, or state',
  ),
  _UpcomingFeature(
    Icons.people_alt_outlined,
    'Connections',
    'Send requests and build your network',
  ),
  _UpcomingFeature(
    Icons.dynamic_feed_outlined,
    'Feed',
    'Updates from officials you are connected with',
  ),
];

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.feature});

  final _UpcomingFeature feature;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: <Widget>[
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              feature.icon,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(feature.title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(feature.subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
