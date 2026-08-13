import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/state/refresh_with_error_report.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/widgets/user_list_tile.dart';
import '../models/connection_models.dart';
import '../state/connections_controller.dart';

/// "My Network" and pending requests, split across two tabs.
///
/// Requests carry a count badge because they're the time-sensitive half —
/// someone is waiting on the user to act.
class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  /// Skips the entrance animation for rows already shown once, so scrolling
  /// a long network/requests list doesn't re-blank recycled rows. One tracker
  /// per tab — the two lists are unrelated, so a name only needs to be unique
  /// within its own list.
  final PlayedOnceTracker _networkPlayed = PlayedOnceTracker();
  final PlayedOnceTracker _requestsPlayed = PlayedOnceTracker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ConnectionsController>().loadOnce();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _showError(String? message) {
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ConnectionsController controller =
        context.watch<ConnectionsController>();
    final int pendingCount = controller.requests.incoming.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Network'),
        titleSpacing: AppSpacing.gutter,
        bottom: TabBar(
          controller: _tabs,
          labelStyle: theme.textTheme.labelLarge,
          tabs: <Widget>[
            Tab(text: 'Connections (${controller.network.length})'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Requests'),
                  if (pendingCount > 0) ...<Widget>[
                    const SizedBox(width: 6),
                    AnimatedContainer(
                      duration: context.motion(AppMotion.base),
                      curve: AppMotion.overshoot,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '$pendingCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: <Widget>[
          _NetworkTab(
            controller: controller,
            onError: _showError,
            played: _networkPlayed,
          ),
          _RequestsTab(
            controller: controller,
            onError: _showError,
            played: _requestsPlayed,
          ),
        ],
      ),
    );
  }
}

class _NetworkTab extends StatelessWidget {
  const _NetworkTab({
    required this.controller,
    required this.onError,
    required this.played,
  });

  final ConnectionsController controller;
  final ValueChanged<String?> onError;
  final PlayedOnceTracker played;

  Future<void> _confirmRemove(
    BuildContext context,
    NetworkConnection connection,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Remove connection?'),
          content: Text(
            'You and ${connection.user.displayName} will no longer be '
            "connected, and you'll stop seeing each other's posts.",
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    onError(await controller.remove(connection.connectionId));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => refreshWithErrorReport(context, controller),
      child: AsyncView<ConnectionsData>(
        controller: controller,
        isEmpty: (ConnectionsData data) => data.network.isEmpty,
        loadingPlaceholder: SkeletonList(
          itemBuilder: (BuildContext context) => const UserTileSkeleton(),
        ),
        emptyIcon: Icons.people_outline_rounded,
        emptyTitle: 'No connections yet',
        emptyMessage:
            'Find officials in Search and send a connection request to '
            'start building your network.',
        emptyActionLabel: 'Open search',
        onEmptyAction: () => context.go(AppRoutes.search),
        builder: (BuildContext context, ConnectionsData data) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.md,
              AppSpacing.gutter,
              AppSpacing.xxl,
            ),
            itemCount: data.network.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
            itemBuilder: (BuildContext context, int index) {
              final NetworkConnection connection = data.network[index];
              final bool alreadyShown = played.consume(connection.connectionId);
              return FadeSlideIn(
                // Keyed so removing one connection animates the rest into
                // place instead of the whole list replaying its entrance.
                key: ValueKey<String>('conn-${connection.connectionId}'),
                delay: alreadyShown ? Duration.zero : context.stagger(index),
                duration: alreadyShown ? Duration.zero : AppMotion.slow,
                scaleFrom: 0.97,
                child: UserListTile(
                  user: connection.user,
                  heroTag: AvatarHeroTag.network(connection.user.id),
                  onTap: () => context.push(
                    AppRoutes.userProfile(connection.user.id),
                    extra: AvatarHeroTag.network(connection.user.id),
                  ),
                  trailing: IconButton(
                    onPressed: controller.isBusy(connection.connectionId)
                        ? null
                        : () => _confirmRemove(context, connection),
                    icon: controller.isBusy(connection.connectionId)
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_remove_outlined, size: 20),
                    tooltip: 'Remove connection',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RequestsTab extends StatelessWidget {
  const _RequestsTab({
    required this.controller,
    required this.onError,
    required this.played,
  });

  final ConnectionsController controller;
  final ValueChanged<String?> onError;
  final PlayedOnceTracker played;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () => refreshWithErrorReport(context, controller),
      child: AsyncView<ConnectionsData>(
        controller: controller,
        isEmpty: (ConnectionsData data) => data.requests.total == 0,
        emptyIcon: Icons.inbox_outlined,
        emptyTitle: 'No pending requests',
        emptyMessage:
            'Connection requests you send or receive will show up here.',
        builder: (BuildContext context, ConnectionsData data) {
          final PendingRequests requests = data.requests;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.md,
              AppSpacing.gutter,
              AppSpacing.xxl,
            ),
            children: <Widget>[
              if (requests.incoming.isNotEmpty) ...<Widget>[
                _SectionLabel(
                  label: 'Awaiting your response',
                  count: requests.incoming.length,
                ),
                for (int i = 0; i < requests.incoming.length; i++)
                  Padding(
                    key: ValueKey<String>('incoming-${requests.incoming[i].requestId}'),
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Builder(
                      builder: (BuildContext context) {
                        final bool alreadyShown =
                            played.consume(requests.incoming[i].requestId);
                        return FadeSlideIn(
                          delay: alreadyShown ? Duration.zero : context.stagger(i),
                          duration: alreadyShown ? Duration.zero : AppMotion.slow,
                          child: _IncomingCard(
                            request: requests.incoming[i],
                            controller: controller,
                            onError: onError,
                          ),
                        );
                      },
                    ),
                  ),
              ],
              if (requests.outgoing.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                _SectionLabel(
                  label: 'Sent by you',
                  count: requests.outgoing.length,
                ),
                for (int i = 0; i < requests.outgoing.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: UserListTile(
                      user: requests.outgoing[i].user,
                      subtitleOverride: 'Waiting for a response',
                      onTap: () => context.push(
                        AppRoutes.userProfile(requests.outgoing[i].user.id),
                      ),
                      trailing: TextButton(
                        onPressed:
                            controller.isBusy(requests.outgoing[i].requestId)
                                ? null
                                : () async => onError(
                                      await controller.remove(
                                        requests.outgoing[i].requestId,
                                      ),
                                    ),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        '${label.toUpperCase()} · $count',
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

/// Incoming requests get a dedicated card rather than a list tile: accept and
/// decline both need to be full-width targets, which won't fit in a trailing
/// slot.
class _IncomingCard extends StatelessWidget {
  const _IncomingCard({
    required this.request,
    required this.controller,
    required this.onError,
  });

  final ConnectionRequest request;
  final ConnectionsController controller;
  final ValueChanged<String?> onError;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool busy = controller.isBusy(request.requestId);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: <Widget>[
          UserListTile(
            user: request.user,
            onTap: () => context.push(AppRoutes.userProfile(request.user.id)),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: busy
                      ? null
                      : () async =>
                          onError(await controller.decline(request.requestId)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: FilledButton(
                  onPressed: busy
                      ? null
                      : () async =>
                          onError(await controller.accept(request.requestId)),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
