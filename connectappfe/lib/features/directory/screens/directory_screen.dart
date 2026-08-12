import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/models.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/user_list_tile.dart';
import '../../connections/state/connections_controller.dart';
import '../../connections/widgets/connect_button.dart';
import '../state/directory_controller.dart';

/// Browse and filter officials.
///
/// Service is exposed as chips because it's a small, known set and the most
/// common way to narrow a search; department and state are free text behind a
/// sheet, since their values vary too much to enumerate.
class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  static const List<String> _services = <String>[
    'IAS',
    'IPS',
    'IFS',
    'State Service',
  ];

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
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom +
                AppSpacing.lg,
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
              AppTextField(
                label: 'Department',
                hint: 'e.g. Revenue',
                controller: department,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'State / cadre',
                hint: 'e.g. Karnataka',
                controller: state,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        controller.clearFilters();
                      },
                      child: const Text('Clear all'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        controller.applyFilters(
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
    final ThemeData theme = Theme.of(context);
    final DirectoryController directory = context.watch<DirectoryController>();
    final ConnectionsController connections =
        context.watch<ConnectionsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Directory'),
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
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
              ),
              children: <Widget>[
                for (final String service in _services)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: ChoiceChip(
                      label: Text(service),
                      selected: directory.serviceFilter == service,
                      showCheckmark: false,
                      onSelected: (bool selected) {
                        directory.applyFilters(
                          service: selected ? service : '',
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => directory.load(silent: true),
              child: AsyncView<List<PublicUser>>(
                controller: directory,
                isEmpty: (List<PublicUser> data) => data.isEmpty,
                emptyIcon: Icons.search_off_rounded,
                emptyTitle: directory.hasFilters
                    ? 'No matches'
                    : 'Directory is empty',
                emptyMessage: directory.hasFilters
                    ? 'No officials match these filters. Try widening your search.'
                    : 'No officials have signed up yet.',
                emptyActionLabel: directory.hasFilters ? 'Clear filters' : null,
                onEmptyAction:
                    directory.hasFilters ? directory.clearFilters : null,
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
                      return FadeSlideIn(
                        // Cap the cascade: staggering the 40th row would leave
                        // it invisible for seconds.
                        delay: AppMotion.stagger * (index.clamp(0, 6)),
                        child: UserListTile(
                          user: person,
                          onTap: () => context.push(
                            AppRoutes.userProfile(person.id),
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
      backgroundColor: theme.scaffoldBackgroundColor,
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
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: AnimatedScale(
              scale: 1,
              duration: AppMotion.base,
              curve: AppMotion.overshoot,
              child: Container(
                height: 16,
                width: 16,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
