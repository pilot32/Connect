/// Endpoint paths and network timeouts, mirroring `API_CONTRACT.md`.
///
/// Keeping paths in one place means a backend route rename is a single-file
/// change on the client.
class ApiConfig {
  const ApiConfig._();

  static const Duration connectTimeout = Duration(seconds: 15);

  /// Generous: signup uploads images to Cloudinary server-side, so the
  /// response only comes back after the upload completes.
  static const Duration receiveTimeout = Duration(seconds: 45);
  static const Duration sendTimeout = Duration(seconds: 45);

  // ------------------------------------------------------------------ auth
  static const String signup = '/auth/signup';
  static const String login = '/auth/login';

  /// Authoritative account state. Unlike the token's `status` claim — frozen
  /// at sign-in — this reflects the database, so it is how the app notices an
  /// approval without making the user sign in again.
  static const String authStatus = '/auth/status';

  // ----------------------------------------------------------------- admin
  static const String adminUsers = '/admin/users';
  static String adminUser(String userId) => '/admin/users/$userId';
  static String approveUser(String userId) => '/admin/users/$userId/approve';
  static String rejectUser(String userId) => '/admin/users/$userId/reject';

  // --------------------------------------------------------------- profile
  static const String myProfile = '/profile/me';
  static String profileById(String userId) => '/profile/$userId';

  // ----------------------------------------------------------- connections
  static const String connections = '/connections';
  static const String connectionRequests = '/connections/requests';
  static String connectionRequest(String userId) =>
      '/connections/request/$userId';
  static String acceptConnection(String requestId) =>
      '/connections/$requestId/accept';
  static String declineConnection(String requestId) =>
      '/connections/$requestId/decline';
  static String deleteConnection(String connectionId) =>
      '/connections/$connectionId';

  // ------------------------------------------------------------- directory
  static const String directory = '/directory';

  // ------------------------------------------------------------------ feed
  static const String feed = '/feed';
}
