import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/state/auth_controller.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../theme/app_tokens.dart';
import 'app_routes.dart';

/// Builds the app's [GoRouter].
///
/// The redirect only *guards* protected routes — it deliberately does not kick
/// an authenticated user off `/login`. That lets the login and signup screens
/// play their success animation and navigate themselves, instead of being
/// yanked away the instant the token lands.
GoRouter buildRouter(AuthController auth) {
  return GoRouter(
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
            ? AppRoutes.home
            : AppRoutes.login;
      }

      const Set<String> protected = <String>{AppRoutes.home};
      if (protected.contains(location) &&
          status != AuthStatus.authenticated) {
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
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fade(state, const HomeScreen()),
      ),
    ],
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
