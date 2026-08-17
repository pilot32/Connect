import 'package:connectappfe/core/router/app_routes.dart';
import 'package:connectappfe/core/theme/app_tokens.dart';
import 'package:connectappfe/features/auth/screens/login_screen.dart';
import 'package:connectappfe/features/auth/screens/signup_screen.dart';
import 'package:connectappfe/features/auth/state/auth_controller.dart';
import 'package:connectappfe/features/connections/screens/connections_screen.dart';
import 'package:connectappfe/features/directory/screens/search_screen.dart';
import 'package:connectappfe/features/feed/screens/compose_post_screen.dart';
import 'package:connectappfe/features/feed/screens/feed_screen.dart';
import 'package:connectappfe/features/profile/screens/edit_profile_screen.dart';
import 'package:connectappfe/features/profile/screens/profile_screen.dart';
import 'package:connectappfe/features/profile/screens/user_profile_screen.dart';
import 'package:connectappfe/features/shell/screens/app_shell.dart';
import 'package:connectappfe/features/splash/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Builds the app's [GoRouter].
///
/// The redirect only *guards* protected routes — it deliberately does not kick
/// an authenticated user off `/login`. That lets the login and signup screens
/// play their success animation and navigate themselves, instead of being
/// yanked away the instant the token lands.
GoRouter buildRouter(AuthController auth) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: auth,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final status = auth.status;

      // Still restoring the session: hold on the splash.
      if (status == AuthStatus.unknown) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      if (location == AppRoutes.splash) {
        return status == AuthStatus.authenticated
            ? AppRoutes.afterLogin
            : AppRoutes.login;
      }

      // Everything except the auth screens requires a session.
      const public = <String>{AppRoutes.login, AppRoutes.signup};
      if (!public.contains(location) && status != AuthStatus.authenticated) {
        return AppRoutes.login;
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => _fade(state, const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _fade(state, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.signup,
        pageBuilder: (context, state) => _slideUp(state, const SignupScreen()),
      ),

      // Pushed above the shell so they cover the bottom navigation bar.
      GoRoute(
        path: AppRoutes.editProfile,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _slideUp(state, const EditProfileScreen()),
      ),
      GoRoute(
        path: AppRoutes.composePost,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _slideUp(state, const ComposePostScreen()),
      ),
      GoRoute(
        path: AppRoutes.userProfilePattern,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _slideUp(
          state,
          UserProfileScreen(
            userId: state.pathParameters['id'] ?? '',
            // The source screen passes its namespaced avatar tag so the Hero
            // has a matching endpoint here. Null when arrived at by deep link,
            // in which case there is simply no flight.
            heroTag: state.extra is String ? state.extra! as String : null,
          ),
        ),
      ),

      // Each branch keeps its own navigator, so tab state and scroll position
      // survive switching away and back.
      //
      // Uses the general StatefulShellRoute rather than `.indexedStack` so the
      // branch container can be supplied: a plain IndexedStack cuts between
      // tabs, and a cross-fade needs both branches painted at once.
      StatefulShellRoute(
        builder:
            (
              context,
              state,
              navigationShell,
            ) => AppShell(navigationShell: navigationShell),
        navigatorContainerBuilder:
            (
              context,
              navigationShell,
              children,
            ) => AnimatedBranchContainer(
              currentIndex: navigationShell.currentIndex,
              children: children,
            ),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.feed,
                pageBuilder: (context, state) =>
                    _noTransition(state, const FeedScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.search,
                pageBuilder: (context, state) =>
                    _noTransition(state, const SearchScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.network,
                pageBuilder: (context, state) =>
                    _noTransition(state, const ConnectionsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.profile,
                pageBuilder: (context, state) =>
                    _noTransition(state, const ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Tabs don't animate: an IndexedStack swap with a page transition reads as a
/// glitch, since both tabs are already alive.
CustomTransitionPage<void> _noTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    child: child,
    transitionsBuilder:
        (
          context,
          animation,
          secondaryAnimation,
          child,
        ) => child,
  );
}

/// Cross-fade with a whisper of scale — used for root-level swaps where there
/// is no spatial relationship between the two screens.
CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: AppMotion.slow,
    reverseTransitionDuration: AppMotion.base,
    child: child,
    transitionsBuilder:
        (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          // `transitionsBuilder` runs every frame of the transition (the Navigator
          // wraps it in a ListenableBuilder on the route animation). No reverseCurve
          // here, so `.drive(CurveTween(...))` — a stateless proxy, nothing to leak —
          // covers it; contrast with `_slideUp` below, which does need reverseCurve.
          final eased = animation.drive(
            CurveTween(curve: AppMotion.emphasized),
          );
          return FadeTransition(
            opacity: eased,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.03, end: 1).animate(eased),
              child: child,
            ),
          );
        },
  );
}

/// One [CurvedAnimation] per route-transition animation, not per frame.
///
/// `_slideUp` needs a distinct `reverseCurve`, which `CurveTween`/`.drive()`
/// can't express — the only way to get one is `CurvedAnimation`, which adds a
/// status listener to its parent at construction and must be disposed to
/// remove it. Since `transitionsBuilder` is a free function invoked every
/// frame, constructing one there directly would leak a listener per frame for
/// the whole transition, and re-seeding `_curveDirection` from `parent.status`
/// on each of those breaks the class's deliberate direction-stickiness — an
/// interrupted push (a pop mid-rise) would visibly snap curves mid-flight
/// instead of continuing to ease out on the curve it started with.
/// [Expando] keys this by the route's own animation object, which is stable
/// for that route's whole lifetime and already owns the memoized entry's
/// lifetime — no separate dispose bookkeeping needed here.
final Expando<CurvedAnimation> _slideUpCurves = Expando<CurvedAnimation>();

/// Sheet-style rise, for screens pushed *on top of* the current context.
CustomTransitionPage<void> _slideUp(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: AppMotion.slow,
    reverseTransitionDuration: AppMotion.base,
    child: child,
    transitionsBuilder:
        (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          final eased = _slideUpCurves[animation] ??= CurvedAnimation(
            parent: animation,
            curve: AppMotion.emphasized,
            reverseCurve: AppMotion.exit,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(eased),
            child: FadeTransition(opacity: eased, child: child),
          );
        },
  );
}
