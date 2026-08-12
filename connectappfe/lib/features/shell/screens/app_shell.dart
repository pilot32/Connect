import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_tokens.dart';
import '../../connections/state/connections_controller.dart';

/// Bottom-navigation host for the four main tabs.
///
/// Backed by go_router's [StatefulNavigationShell], so each tab keeps its own
/// navigation stack and scroll position when you switch away and back.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // Watched so the requests badge updates the moment a request arrives or is
    // actioned anywhere in the app.
    final int pending =
        context.watch<ConnectionsController>().requests.incoming.length;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.colorScheme.outline)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (int index) => navigationShell.goBranch(
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
              label: 'Directory',
            ),
            NavigationDestination(
              icon: _BadgedIcon(
                icon: Icons.people_alt_outlined,
                count: pending,
              ),
              selectedIcon: _BadgedIcon(
                icon: Icons.people_alt_rounded,
                count: pending,
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

class _BadgedIcon extends StatelessWidget {
  const _BadgedIcon({required this.icon, required this.count});

  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Icon(icon),
        if (count > 0)
          Positioned(
            right: -6,
            top: -4,
            child: AnimatedScale(
              scale: 1,
              duration: AppMotion.base,
              curve: AppMotion.overshoot,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  count > 9 ? '9+' : '$count',
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
