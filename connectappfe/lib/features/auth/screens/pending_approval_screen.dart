import 'package:connectappfe/core/models/models.dart';
import 'package:connectappfe/core/router/app_routes.dart';
import 'package:connectappfe/core/theme/app_colors.dart';
import 'package:connectappfe/core/theme/app_tokens.dart';
import 'package:connectappfe/core/widgets/app_button.dart';
import 'package:connectappfe/core/widgets/auth_shell.dart';
import 'package:connectappfe/core/widgets/fade_slide_in.dart';
import 'package:connectappfe/core/widgets/status_banner.dart';
import 'package:connectappfe/features/auth/state/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// The waiting room for an account an admin hasn't cleared yet.
///
/// Reuses [AuthShell] rather than the app's normal chrome on purpose: this
/// screen belongs to the "not in yet" half of the app, alongside login and
/// signup, and giving it an app bar would imply there is something to navigate
/// back to. There isn't — the router pins unapproved users here.
class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  /// True once a check has come back without the status having moved, so the
  /// screen can say "still under review" rather than looking inert. Without
  /// this, a successful check that changes nothing is indistinguishable from a
  /// button that didn't work.
  bool _checkedWithNoChange = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Also populates the profile summary below: a restored session has a
      // token but no profile in memory until something fetches one.
      context.read<AuthController>().checkApprovalStatus();
    });
  }

  Future<void> _check() async {
    final auth = context.read<AuthController>();
    await auth.checkApprovalStatus();
    if (!mounted) return;
    // Approved is not handled here: the router is listening to the same
    // controller and will have already replaced this screen.
    setState(() => _checkedWithNoChange = auth.statusCheckError == null);
  }

  Future<void> _signOut() async {
    await context.read<AuthController>().logout();
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();
    final profile = auth.profile;
    final rejected = auth.isRejected;

    return AuthShell(
      title: rejected ? 'Application not approved' : 'Application under review',
      subtitle: rejected
          ? 'An administrator reviewed your submission.'
          : 'An administrator is verifying your government ID.',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.xl,
          AppSpacing.gutter,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            StatusBanner(message: auth.statusCheckError),

            FadeSlideIn(
              child: rejected
                  ? _RejectedNotice(reason: auth.user?.rejectionReason)
                  : const _PendingNotice(),
            ),

            const SizedBox(height: AppSpacing.lg),

            FadeSlideIn(
              delay: AppMotion.stagger,
              child: _SubmissionSummary(
                email: auth.user?.email ?? '',
                profile: profile,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            FadeSlideIn(
              delay: AppMotion.stagger * 2,
              child: AppButton(
                label: 'Check status',
                icon: Icons.refresh_rounded,
                state: auth.isCheckingStatus
                    ? AppButtonState.loading
                    : AppButtonState.idle,
                onPressed: _check,
              ),
            ),

            // Only after a check has actually completed, so it never appears
            // as a stale message on first paint.
            if (_checkedWithNoChange && !auth.isCheckingStatus) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                rejected
                    ? 'Your application is still marked as not approved.'
                    : 'Still under review — we checked just now.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],

            const SizedBox(height: AppSpacing.md),
            FadeSlideIn(
              delay: AppMotion.stagger * 3,
              child: TextButton.icon(
                onPressed: auth.isCheckingStatus ? null : _signOut,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Log out'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  minimumSize: const Size.fromHeight(46),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingNotice extends StatelessWidget {
  const _PendingNotice();

  @override
  Widget build(BuildContext context) {
    return const _Notice(
      icon: Icons.verified_user_outlined,
      tone: AppColors.brand,
      wash: AppColors.brandWash,
      title: 'Pending verification',
      body:
          'Your details and government ID card have been submitted. An '
          'administrator checks every application by hand, so the network '
          'stays limited to serving officials. You will get in as soon as '
          "you're approved — no need to sign up again.",
    );
  }
}

class _RejectedNotice extends StatelessWidget {
  const _RejectedNotice({this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) {
    final given = (reason ?? '').trim();
    return _Notice(
      icon: Icons.gpp_bad_outlined,
      tone: AppColors.error,
      wash: AppColors.errorWash,
      title: 'Not approved',
      body: given.isEmpty
          // No reason recorded: say so plainly instead of leaving a blank
          // space that reads as a rendering failure.
          ? 'An administrator could not verify this application, and did not '
                'record a reason. Contact your department administrator to '
                'find out what to correct.'
          : 'Reason given:\n$given',
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.tone,
    required this.wash,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color tone;
  final Color wash;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: wash,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: tone.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 22, color: tone),
              const SizedBox(width: AppSpacing.xs),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(color: tone),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// Read-back of what was submitted, so the applicant can spot a typo that
/// might be why they were rejected.
class _SubmissionSummary extends StatelessWidget {
  const _SubmissionSummary({required this.email, this.profile});

  final String email;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('YOUR SUBMISSION', style: theme.textTheme.labelSmall),
          const SizedBox(height: AppSpacing.xs),
          if (profile == null)
            Text(
              'Loading your submitted details…',
              style: theme.textTheme.bodySmall,
            )
          else ...<Widget>[
            _Row(label: 'Name', value: profile!.name),
            _Row(label: 'Designation', value: profile!.designation),
            _Row(label: 'Service', value: profile!.service),
            _Row(label: 'Department', value: profile!.department),
            _Row(label: 'State / cadre', value: profile!.stateOrCadre),
          ],
          _Row(label: 'Email', value: email),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 108,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
