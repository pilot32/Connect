/// Whether an account reviews applicants or is one.
///
/// Admins are seeded server-side (`prisma/seed.js`) — there is no signup path
/// that produces one, so the app never has to *create* this, only read it.
enum UserRole {
  user,
  admin;

  /// Anything unrecognised is treated as an ordinary user: the narrower of the
  /// two roles, so a server-side rename can't hand someone the admin console.
  static UserRole parse(String? raw) => switch (raw) {
    'admin' => UserRole.admin,
    _ => UserRole.user,
  };

  String get wire => name;
}

/// Where an account sits in the admin approval flow.
enum AccountStatus {
  pending,
  approved,
  rejected,

  /// Not read from the server yet.
  ///
  /// Only reachable when restoring a session saved by a build that predates
  /// approval, so there is no stored status to restore. Deliberately distinct
  /// from [pending]: those users are almost certainly already approved (the
  /// backend migration grandfathered every pre-existing account), so parking
  /// them in the waiting room on the strength of a missing key would lock out
  /// working accounts. The router lets [unknown] through, and the refresh
  /// `AuthController.bootstrap` fires resolves it a moment later.
  unknown;

  /// Unrecognised *server* values fall back to [pending] rather than [unknown]
  /// — if the API starts sending a status this build doesn't understand, the
  /// safe reading is "not cleared for access", not "carry on".
  static AccountStatus parse(String? raw) => switch (raw) {
    'pending' => AccountStatus.pending,
    'approved' => AccountStatus.approved,
    'rejected' => AccountStatus.rejected,
    _ => AccountStatus.pending,
  };

  /// Round-trips through [StorageService]; `null` for a value not worth
  /// persisting.
  static AccountStatus restore(String? raw) =>
      raw == null ? AccountStatus.unknown : parse(raw);

  String get wire => name;
}

/// The account record behind a profile.
///
/// [email] is only ever populated for the signed-in user — the API deliberately
/// omits it from other people's profiles, so it is empty for anyone else.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.role = UserRole.user,
    this.status = AccountStatus.unknown,
    this.rejectionReason,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: UserRole.parse(json['role'] as String?),
      status: AccountStatus.parse(json['status'] as String?),
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  final String id;
  final String email;
  final UserRole role;
  final AccountStatus status;

  /// The admin's note when [status] is [AccountStatus.rejected]. Null when the
  /// account wasn't rejected, or was rejected without a reason given.
  final String? rejectionReason;

  bool get isAdmin => role == UserRole.admin;
  bool get isApproved => status == AccountStatus.approved;
  bool get isPending => status == AccountStatus.pending;
  bool get isRejected => status == AccountStatus.rejected;
}
