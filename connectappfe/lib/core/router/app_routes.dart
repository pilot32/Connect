/// Route paths, kept as constants so navigation calls can't drift from the
/// router definition via typo'd string literals.
class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';

  // Bottom-navigation tabs.
  static const String feed = '/feed';
  static const String directory = '/directory';
  static const String network = '/network';
  static const String profile = '/profile';

  // Pushed on top of the shell.
  static const String editProfile = '/profile/edit';
  static const String composePost = '/feed/compose';

  static const String userProfilePattern = '/user/:id';
  static String userProfile(String userId) => '/user/$userId';

  /// Where a freshly authenticated user lands.
  static const String afterLogin = feed;
}
