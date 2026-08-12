import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/models.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/state/refresh_with_error_report.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../auth/state/auth_controller.dart';
import '../state/profile_controller.dart';
import '../widgets/profile_header.dart';

/// The signed-in user's own profile, with edit and sign-out.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfileController>().loadOnce();
    });
  }

  Future<void> _confirmSignOut() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Sign out?'),
          content: const Text("You'll need your email and password to sign back in."),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;
    await context.read<AuthController>().logout();
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ProfileController controller = context.watch<ProfileController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        titleSpacing: AppSpacing.gutter,
        actions: <Widget>[
          IconButton(
            onPressed: _confirmSignOut,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => refreshWithErrorReport(context, controller),
        child: AsyncView<MyProfile>(
          controller: controller,
          isEmpty: (MyProfile data) => false,
          emptyIcon: Icons.person_off_outlined,
          emptyTitle: 'No profile',
          emptyMessage: 'We could not find your profile.',
          builder: (BuildContext context, MyProfile me) {
            final UserProfile? profile = me.profile;

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.md,
                AppSpacing.gutter,
                AppSpacing.xxl,
              ),
              children: <Widget>[
                FadeSlideIn(
                  child: ProfileHeader(
                    profile: profile,
                    email: me.email,
                    action: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(AppRoutes.editProfile),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit profile'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                          minimumSize: const Size.fromHeight(46),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (profile != null && (profile.bio ?? '').isNotEmpty) ...<Widget>[
                  FadeSlideIn(
                    delay: AppMotion.stagger,
                    child: _Section(
                      title: 'About',
                      child: Text(
                        profile.bio!,
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                FadeSlideIn(
                  delay: AppMotion.stagger * 2,
                  child: _Section(
                    title: 'Posting details',
                    child: Column(
                      children: <Widget>[
                        ProfileDetailRow(
                          icon: Icons.work_outline_rounded,
                          label: 'DESIGNATION',
                          value: profile?.designation ?? '',
                        ),
                        const Divider(),
                        ProfileDetailRow(
                          icon: Icons.shield_outlined,
                          label: 'SERVICE',
                          value: profile?.service ?? '',
                        ),
                        const Divider(),
                        ProfileDetailRow(
                          icon: Icons.account_balance_outlined,
                          label: 'DEPARTMENT',
                          value: profile?.department ?? '',
                        ),
                        const Divider(),
                        ProfileDetailRow(
                          icon: Icons.map_outlined,
                          label: 'STATE / CADRE',
                          value: profile?.stateOrCadre ?? '',
                        ),
                        const Divider(),
                        ProfileDetailRow(
                          icon: Icons.timeline_rounded,
                          label: 'YEARS IN SERVICE',
                          value: '${profile?.yearsInService ?? 0}',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title.toUpperCase(), style: theme.textTheme.labelSmall),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}
