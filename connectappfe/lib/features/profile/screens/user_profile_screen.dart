import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/models.dart';
import '../../../core/services/api_exception.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../connections/state/connections_controller.dart';
import '../../connections/widgets/connect_button.dart';
import '../services/profile_service.dart';
import '../widgets/profile_header.dart';

/// Another official's public profile (`GET /profile/:id`).
///
/// Fetches on its own rather than through a shared controller: it is a
/// pushed, transient screen and several can be stacked, so per-screen state
/// keeps them independent.
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  PublicUser? _user;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final PublicUser user =
          await context.read<ProfileService>().getProfileById(widget.userId);
      if (!mounted) return;
      setState(() {
        _user = user;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load this profile.';
        _loading = false;
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ConnectionsController connections =
        context.watch<ConnectionsController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Builder(
        builder: (BuildContext context) {
          if (_loading) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2.6));
          }
          if (_error != null || _user == null) {
            return EmptyState(
              icon: Icons.person_off_outlined,
              title: "Couldn't load profile",
              message: _error ?? 'This official could not be found.',
              tone: EmptyStateTone.error,
              actionLabel: 'Retry',
              onAction: _load,
            );
          }

          final PublicUser user = _user!;
          final UserProfile? profile = user.profile;

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
                  action: Align(
                    alignment: Alignment.centerLeft,
                    child: ConnectButton(
                      userId: user.id,
                      controller: connections,
                      onError: _showError,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (profile != null && (profile.bio ?? '').isNotEmpty) ...<Widget>[
                FadeSlideIn(
                  delay: AppMotion.stagger,
                  child: _Card(
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
                child: _Card(
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
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

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
