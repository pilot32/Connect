import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/models.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/state/refresh_with_error_report.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/widgets/user_list_tile.dart';
import '../../connections/state/connections_controller.dart';
import '../../connections/widgets/connect_button.dart';
import '../state/directory_controller.dart';

/// Browse and filter officials — presented to users as "Search".
///
/// The feature folder, service, and controller keep the name "Directory" to
/// match the backend's `GET /directory`; only the product surface is Search.
///
/// Service is exposed as chips because it's a small, known set and the most
/// common way to narrow a search; department and state are free text behind a
/// sheet, since their values vary too much to enumerate.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const List<String> _services = <String>[
    'IAS',
    'IPS',
    'IFS',
    'State Service',
  ];

  /// Skips the entrance animation for rows already shown once — reset on
  /// every filter change so the *new* result set still announces itself.
  final PlayedOnceTracker _played = PlayedOnceTracker();

  @override
  void initState() {
    super.initState();
    // Deferred: controllers live above this widget, so touching them during
    // initState would notify listeners mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DirectoryController>().loadOnce();
      context.read<ConnectionsController>().loadOnce();
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Filter changes are silent loads (they keep the current results on screen
  /// while the new ones fetch), so a failure needs the same explicit surfacing
  /// as pull-to-refresh — otherwise tapping a chip that fails to load just
  /// silently leaves the old results showing with no explanation.
  Future<void> _applyFilters({String? service, String? department, String? state}) async {
    final DirectoryController controller = context.read<DirectoryController>();
    _played.reset();
    await controller.applyFilters(
      service: service,
      department: department,
      state: state,
    );
    final String? failure = controller.consumeSilentError();
    if (failure != null) _showError(failure);
  }

  Future<void> _clearFilters() async {
    final DirectoryController controller = context.read<DirectoryController>();
    _played.reset();
    await controller.clearFilters();
    final String? failure = controller.consumeSilentError();
    if (failure != null) _showError(failure);
  }

  Future<void> _openFilterSheet() async {
    final DirectoryController controller = context.read<DirectoryController>();
    final TextEditingController department =
        TextEditingController(text: controller.departmentFilter);
    final TextEditingController state =
        TextEditingController(text: controller.stateFilter);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.gutter,
            right: AppSpacing.gutter,
            bottom:
                MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Refine search',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              FadeSlideIn(
                offset: 12,
                child: AppTextField(
                  label: 'Department',
                  hint: 'e.g. Revenue',
                  controller: department,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeSlideIn(
                delay: AppMotion.stagger,
                offset: 12,
                child: AppTextField(
                  label: 'State / cadre',
                  hint: 'e.g. Karnataka',
                  controller: state,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _clearFilters();
                      },
                      child: const Text('Clear all'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _applyFilters(
                          department: department.text,
                          state: state.text,
                        );
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    department.dispose();
    state.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DirectoryController directory = context.watch<DirectoryController>();
    final ConnectionsController connections =
        context.watch<ConnectionsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        titleSpacing: AppSpacing.gutter,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: _FilterButton(
              count: directory.activeFilterCount,
              onPressed: _openFilterSheet,
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
              children: <Widget>[
                for (int i = 0; i < _services.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: FadeSlideIn(
                      delay: context.stagger(i),
                      offset: 0,
                      scaleFrom: 0.85,
                      duration: AppMotion.base,
                      child: _ServiceChip(
                        label: _services[i],
                        selected: directory.serviceFilter == _services[i],
                        onSelected: (bool selected) => _applyFilters(
                          service: selected ? _services[i] : '',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // A hairline progress bar during a silent refilter: the list stays
          // put, so this is the only cue that new results are on the way.
          _RefineIndicator(active: directory.isRefreshing),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => refreshWithErrorReport(context, directory),
              child: AsyncView<List<PublicUser>>(
                controller: directory,
                isEmpty: (List<PublicUser> data) => data.isEmpty,
                loadingPlaceholder: SkeletonList(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.xs,
                    AppSpacing.gutter,
                    AppSpacing.xxl,
                  ),
                  itemBuilder: (BuildContext context) =>
                      const UserTileSkeleton(),
                ),
                emptyIcon: Icons.search_off_rounded,
                emptyTitle:
                    directory.hasFilters ? 'No matches' : 'Nobody to show yet',
                emptyMessage: directory.hasFilters
                    ? 'No officials match these filters. Try widening your search.'
                    : 'No officials have signed up yet.',
                emptyActionLabel: directory.hasFilters ? 'Clear filters' : null,
                onEmptyAction:
                    directory.hasFilters ? _clearFilters : null,
                builder: (BuildContext context, List<PublicUser> people) {
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.xs,
                      AppSpacing.gutter,
                      AppSpacing.xxl,
                    ),
                    itemCount: people.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (BuildContext context, int index) {
                      final PublicUser person = people[index];
                      // `_played` is reset on every filter change, so a new
                      // result set still replays; recycling within the same
                      // set (scrolling) does not.
                      final bool alreadyShown = _played.consume(person.id);
                      return FadeSlideIn(
                        key: ValueKey<String>('search-${person.id}'),
                        delay: alreadyShown ? Duration.zero : context.stagger(index),
                        duration: alreadyShown ? Duration.zero : AppMotion.slow,
                        scaleFrom: 0.97,
                        child: UserListTile(
                          user: person,
                          heroTag: AvatarHeroTag.search(person.id),
                          onTap: () => context.push(
                            AppRoutes.userProfile(person.id),
                            extra: AvatarHeroTag.search(person.id),
                          ),
                          trailing: ConnectButton(
                            userId: person.id,
                            controller: connections,
                            onError: _showError,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip that grows slightly and gains a shadow when selected, so the filter
/// state registers as a physical change rather than only a colour swap.
class _ServiceChip extends StatelessWidget {
  const _ServiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AnimatedScale(
      scale: selected ? 1.04 : 1,
      duration: context.motion(AppMotion.base),
      curve: AppMotion.overshoot,
      child: AnimatedContainer(
        duration: context.motion(AppMotion.base),
        curve: AppMotion.emphasized,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          onSelected: onSelected,
          labelStyle: theme.textTheme.labelMedium?.copyWith(
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.textTheme.labelMedium?.color,
          ),
          side: BorderSide(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
        ),
      ),
    );
  }
}

class _RefineIndicator extends StatelessWidget {
  const _RefineIndicator({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: context.motion(AppMotion.fast),
      curve: AppMotion.emphasized,
      child: SizedBox(
        height: active ? 2 : 0,
        width: double.infinity,
        child: active ? const LinearProgressIndicator(minHeight: 2) : null,
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        IconButton(
          onPressed: onPressed,
          icon: const Icon(Icons.tune_rounded),
          tooltip: 'Filters',
        ),
        Positioned(
          right: 3,
          top: 3,
          // Scale-to-0 doesn't remove a child from the semantics tree, so
          // without this a screen reader hears a stray "0" node sitting next
          // to the Filters button even when no filters are active.
          child: ExcludeSemantics(
            excluding: count == 0,
            child: AnimatedScale(
              scale: count > 0 ? 1 : 0,
              duration: context.motion(AppMotion.slow),
              curve: count > 0 ? AppMotion.overshoot : AppMotion.exit,
              child: AnimatedSwitcher(
                duration: context.motion(AppMotion.base),
                transitionBuilder: (Widget child, Animation<double> animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Container(
                  key: ValueKey<int>(count),
                  height: 17,
                  width: 17,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
