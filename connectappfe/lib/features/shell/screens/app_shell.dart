import 'package:connectappfe/core/theme/app_tokens.dart';
import 'package:connectappfe/features/connections/state/connections_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Bottom-navigation host for the four main tabs.
///
/// Backed by go_router's [StatefulNavigationShell], so each tab keeps its own
/// navigation stack and scroll position when you switch away and back.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Watched so the requests badge updates the moment a request arrives or is
    // actioned anywhere in the app.
    final pending = context
        .watch<ConnectionsController>()
        .requests
        .incoming
        .length;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.colorScheme.outline)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(
            index,
            // Tapping the current tab again pops it back to its root, which is
            // the platform convention users expect.
            initialLocation: index == navigationShell.currentIndex,
          ),
          destinations: <Widget>[
            const NavigationDestination(
              icon: Icon(Icons.dynamic_feed_outlined),
              selectedIcon: Icon(Icons.dynamic_feed_rounded),
              label: 'Feed',
            ),
            const NavigationDestination(
              icon: Icon(Icons.search_rounded),
              selectedIcon: Icon(Icons.saved_search_rounded),
              label: 'Search',
            ),
            NavigationDestination(
              icon: CountBadge(
                count: pending,
                child: const Icon(Icons.people_alt_outlined),
              ),
              selectedIcon: CountBadge(
                count: pending,
                child: const Icon(Icons.people_alt_rounded),
              ),
              label: 'Network',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

/// Cross-fades between navigation branches while keeping every branch alive.
///
/// go_router's `.indexedStack` constructor cuts straight to the new tab. This
/// keeps all branches in the tree (so state and scroll position survive) but
/// animates opacity and a small vertical drift, and holds the outgoing branch
/// painted until the fade completes.
class AnimatedBranchContainer extends StatelessWidget {
  const AnimatedBranchContainer({
    required this.currentIndex,
    required this.children,
    super.key,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: children.mapIndexed((index, child) {
        final active = index == currentIndex;
        return AnimatedSlide(
          offset: Offset(0, active ? 0 : 0.012),
          duration: context.motion(AppMotion.base),
          curve: AppMotion.emphasized,
          child: AnimatedOpacity(
            opacity: active ? 1 : 0,
            duration: context.motion(AppMotion.base),
            curve: AppMotion.emphasized,
            // Inactive branches must not swallow taps, and should be skipped by
            // screen readers and the focus order while hidden.
            child: _BranchGate(active: active, child: child),
          ),
        );
      }).toList(),
    );
  }
}

class _BranchGate extends StatelessWidget {
  const _BranchGate({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !active,
      child: ExcludeSemantics(
        excluding: !active,
        child: ExcludeFocus(
          excluding: !active,
          // TickerMode governs *tickers*, not just visible motion — without
          // it, an inactive branch's shimmer/floating-icon/etc. controllers
          // (anything using a Ticker, directly or via AnimatedBuilder) keep
          // requesting frames and repainting forever behind an opaque-0
          // AnimatedOpacity, so the app never reaches an idle frame while
          // sitting on a static tab. go_router's own default branch
          // container applies this; replacing it with this custom one (for
          // the cross-fade) had silently dropped it.
          child: TickerMode(enabled: active, child: child),
        ),
      ),
    );
  }
}

extension _IndexedMap<E> on List<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E element) transform) sync* {
    for (var i = 0; i < length; i++) {
      yield transform(i, this[i]);
    }
  }
}

/// Wraps an icon with a count bubble that springs in, morphs as the number
/// changes, and shrinks away when it reaches zero.
class CountBadge extends StatelessWidget {
  const CountBadge({required this.count, required this.child, super.key});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        child,
        Positioned(
          right: -7,
          top: -4,
          // `AnimatedScale(scale: 0)` hides the badge visually but a Scale
          // transform doesn't remove its child from the semantics tree, and
          // NavigationBar merges each destination's icon + label into one
          // node — so with no pending requests a screen reader announced
          // "0 Network, tab 3 of 4" on every pass through the bar.
          // ExcludeSemantics drops the whole bubble (count and all) exactly
          // when it's visually gone.
          child: ExcludeSemantics(
            excluding: count == 0,
            child: AnimatedScale(
              // Scale is driven by the count itself, so the bubble actually
              // animates on change instead of sitting at a constant 1.
              scale: count > 0 ? 1 : 0,
              duration: context.motion(AppMotion.slow),
              curve: count > 0 ? AppMotion.overshoot : AppMotion.exit,
              child: AnimatedSwitcher(
                duration: context.motion(AppMotion.base),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axis: Axis.horizontal,
                    child: child,
                  ),
                ),
                child: Container(
                  key: ValueKey<int>(count),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  constraints: const BoxConstraints(minWidth: 17),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
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
