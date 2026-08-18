import 'package:connectappfe/core/router/app_routes.dart';
import 'package:connectappfe/core/state/refresh_with_error_report.dart';
import 'package:connectappfe/core/theme/app_colors.dart';
import 'package:connectappfe/core/theme/app_tokens.dart';
import 'package:connectappfe/core/widgets/async_view.dart';
import 'package:connectappfe/core/widgets/fade_slide_in.dart';
import 'package:connectappfe/core/widgets/skeleton.dart';
import 'package:connectappfe/features/admin/models/applicant.dart';
import 'package:connectappfe/features/admin/state/admin_controller.dart';
import 'package:connectappfe/features/admin/widgets/applicant_card.dart';
import 'package:connectappfe/features/admin/widgets/reject_reason_sheet.dart';
import 'package:connectappfe/features/auth/state/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// The admin's entire app.
///
/// An admin account has no profile, no feed and no network, so this screen sits
/// outside the tab shell and has no bottom navigation — there is nowhere else
/// for them to go. The router pins them here.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  /// Entrance animations are per-filter: switching tabs is a genuinely new
  /// result set and should announce itself, where scrolling the same list back
  /// into view should not.
  final PlayedOnceTracker _played = PlayedOnceTracker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdminController>().loadOnce();
    });
  }

  void _report(String? message) {
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _confirm(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
        ),
      );
  }

  Future<void> _setFilter(ApplicantFilter filter) async {
    _played.reset();
    await context.read<AdminController>().setFilter(filter);
  }

  Future<void> _approve(Applicant applicant) async {
    final failure = await context.read<AdminController>().approve(applicant.id);
    if (failure != null) {
      _report(failure);
      return;
    }
    _confirm('${applicant.displayName} approved.');
  }

  Future<void> _reject(Applicant applicant) async {
    final decision = await showRejectReasonSheet(
      context,
      applicantName: applicant.displayName,
    );
    if (decision == null || !mounted) return;

    final failure = await context.read<AdminController>().reject(
      applicant.id,
      reason: decision.reason,
    );
    if (failure != null) {
      _report(failure);
      return;
    }
    _confirm('${applicant.displayName} rejected.');
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign out?'),
          content: const Text(
            "You'll need the admin email and password to sign back in.",
          ),
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
    final theme = Theme.of(context);
    final controller = context.watch<AdminController>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.gutter,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Admin Portal'),
            Text(
              'Verify officials before they get in',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _confirmSignOut,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _FilterBar(
            selected: controller.filter,
            onChanged: controller.isLoading ? null : _setFilter,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => refreshWithErrorReport(context, controller),
        child: AsyncView<List<Applicant>>(
          controller: controller,
          isEmpty: (data) => data.isEmpty,
          loadingPlaceholder: SkeletonList(
            itemBuilder: (context) => const UserTileSkeleton(),
          ),
          emptyIcon: switch (controller.filter) {
            ApplicantFilter.pending => Icons.inbox_rounded,
            ApplicantFilter.approved => Icons.verified_outlined,
            ApplicantFilter.rejected => Icons.block_outlined,
            ApplicantFilter.all => Icons.people_outline_rounded,
          },
          emptyTitle: switch (controller.filter) {
            ApplicantFilter.pending => 'No pending applications',
            ApplicantFilter.approved => 'No approved officials yet',
            ApplicantFilter.rejected => 'No rejected applications',
            ApplicantFilter.all => 'No applications yet',
          },
          emptyMessage: switch (controller.filter) {
            ApplicantFilter.pending =>
              'Every application has been reviewed. New signups will '
                  'appear here for verification.',
            _ => 'Nothing to show for this filter yet.',
          },
          builder: (context, applicants) {
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.md,
                AppSpacing.gutter,
                AppSpacing.xxl,
              ),
              itemCount: applicants.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final applicant = applicants[index];
                final alreadyShown = _played.consume(applicant.id);
                return FadeSlideIn(
                  // Keyed so a decision animates the remaining rows into place
                  // rather than replaying the whole list's entrance.
                  key: ValueKey<String>('applicant-${applicant.id}'),
                  delay: alreadyShown ? Duration.zero : context.stagger(index),
                  duration: alreadyShown ? Duration.zero : AppMotion.slow,
                  scaleFrom: 0.97,
                  child: ApplicantCard(
                    applicant: applicant,
                    busy: controller.isBusy(applicant.id),
                    onApprove: () => _approve(applicant),
                    onReject: () => _reject(applicant),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Horizontally scrollable filter chips.
///
/// Scrollable rather than a fixed [TabBar] so the four labels can't be
/// squeezed into unreadable slivers on a narrow phone.
class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final ApplicantFilter selected;
  final ValueChanged<ApplicantFilter>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          0,
          AppSpacing.gutter,
          AppSpacing.sm,
        ),
        children: <Widget>[
          for (final filter in ApplicantFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: ChoiceChip(
                label: Text(filter.label),
                selected: filter == selected,
                onSelected: onChanged == null
                    ? null
                    : (isSelected) {
                        if (isSelected) onChanged!(filter);
                      },
              ),
            ),
        ],
      ),
    );
  }
}
