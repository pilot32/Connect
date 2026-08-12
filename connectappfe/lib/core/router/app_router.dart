import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/state/auth_controller.dart';
import '../../features/connections/screens/connections_screen.dart';
import '../../features/directory/screens/directory_screen.dart';
import '../../features/feed/screens/compose_post_screen.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/user_profile_screen.dart';
import '../../features/shell/screens/app_shell.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../theme/app_tokens.dart';
import 'app_routes.dart';

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
    redirect: (BuildContext context, GoRouterState state) {
      final String location = state.matchedLocation;
      final AuthStatus status = auth.status;

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
      const Set<String> public = <String>{AppRoutes.login, AppRoutes.signup};
      if (!public.contains(location) && status != AuthStatus.authenticated) {
        return AppRoutes.login;
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fade(state, const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fade(state, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.signup,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideUp(state, const SignupScreen()),
      ),

      // Pushed above the shell so they cover the bottom navigation bar.
      GoRoute(
        path: AppRoutes.editProfile,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideUp(state, const EditProfileScreen()),
      ),
      GoRoute(
        path: AppRoutes.composePost,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideUp(state, const ComposePostScreen()),
      ),
      GoRoute(
        path: AppRoutes.userProfilePattern,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (BuildContext context, GoRouterState state) => _slideUp(
          state,
          UserProfileScreen(userId: state.pathParameters['id'] ?? ''),
        ),
      ),

      // Each branch keeps its own navigator, so tab state and scroll position
      // survive switching away and back.
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) =>
            AppShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.feed,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    _noTransition(state, const FeedScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.directory,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    _noTransition(state, const DirectoryScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.network,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    _noTransition(state, const ConnectionsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.profile,
                pageBuilder: (BuildContext context, GoRouterState state) =>
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
    transitionsBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) =>
        child,
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
    transitionsBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      final Animation<double> eased = CurvedAnimation(
        parent: animation,
        curve: AppMotion.emphasized,
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

/// Sheet-style rise, for screens pushed *on top of* the current context.
CustomTransitionPage<void> _slideUp(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: AppMotion.slow,
    reverseTransitionDuration: AppMotion.base,
    child: child,
    transitionsBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      final Animation<double> eased = CurvedAnimation(
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
