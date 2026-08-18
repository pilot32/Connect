/// Route paths, kept as constants so navigation calls can't drift from the
/// router definition via typo'd string literals.
class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';

  // Bottom-navigation tabs.
  static const String feed = '/feed';

  /// Surfaced to users as "Search". The path follows the product name, while
  /// the backend endpoint and the `features/directory` code keep the API's
  /// "directory" wording — see `DirectoryService`.
  static const String search = '/search';
  static const String network = '/network';
  static const String profile = '/profile';

  // Pushed on top of the shell.
  static const String editProfile = '/profile/edit';
  static const String composePost = '/feed/compose';

  static const String userProfilePattern = '/user/:id';
  static String userProfile(String userId) => '/user/$userId';

  // Full-screen, outside the tab shell — each is the *only* screen its
  // audience may see, so neither gets bottom navigation.

  /// The approval console. Admins are pinned here; nobody else may enter.
  static const String admin = '/admin';

  /// Waiting room for accounts an admin hasn't cleared yet. Pending and
  /// rejected users are held here until their status changes.
  static const String pendingApproval = '/pending-approval';

  /// Where a freshly authenticated *approved* user lands. Admins and
  /// unapproved users go elsewhere — ask `AuthController.landingRoute` rather
  /// than using this directly.
  static const String afterLogin = feed;
}
