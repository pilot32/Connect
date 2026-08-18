import 'package:connectappfe/core/models/models.dart';

/// Which slice of the review queue to show.
///
/// Mirrors the `status` query parameter of `GET /admin/users`; [all] is the
/// API's own catch-all value, not a client-side "no filter".
enum ApplicantFilter {
  pending('pending', 'Pending'),
  approved('approved', 'Approved'),
  rejected('rejected', 'Rejected'),
  all('all', 'All');

  const ApplicantFilter(this.wire, this.label);

  /// The value sent as `?status=`.
  final String wire;

  /// Tab caption.
  final String label;

  bool matches(AccountStatus status) => switch (this) {
    ApplicantFilter.all => true,
    ApplicantFilter.pending => status == AccountStatus.pending,
    ApplicantFilter.approved => status == AccountStatus.approved,
    ApplicantFilter.rejected => status == AccountStatus.rejected,
  };
}

/// One person awaiting (or having received) a decision, as `/admin/*` returns
/// them.
///
/// This is the only shape in the app that carries [idCardPhotoUrl]: every other
/// endpoint treats it as a private verification asset and omits it. Reviewing
/// that photo against the claimed designation is the entire job of the admin
/// screen, which is why the model exists separately from [PublicUser] rather
/// than extending it.
class Applicant {
  const Applicant({
    required this.id,
    required this.email,
    required this.status,
    this.profile,
    this.idCardPhotoUrl,
    this.rejectionReason,
    this.reviewedAt,
    this.createdAt,
  });

  factory Applicant.fromJson(Map<String, dynamic> json) {
    final Object? profileJson = json['profile'];
    return Applicant(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      status: AccountStatus.parse(json['status'] as String?),
      profile: profileJson is Map
          ? UserProfile.fromJson(profileJson.cast<String, dynamic>())
          : null,
      idCardPhotoUrl: json['idCardPhotoUrl'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      reviewedAt: _parseDate(json['reviewedAt']),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  final String id;
  final String email;
  final AccountStatus status;

  /// Null only if the account somehow has no profile row — the API serialises
  /// `profile: null` rather than omitting the key.
  final UserProfile? profile;

  /// Cloudinary URL of the government ID uploaded at signup.
  final String? idCardPhotoUrl;

  final String? rejectionReason;

  /// When the latest decision was made; null while still unreviewed.
  final DateTime? reviewedAt;

  /// When they applied.
  final DateTime? createdAt;

  String get displayName => profile?.name ?? 'Unknown official';

  bool get hasIdCard => (idCardPhotoUrl ?? '').isNotEmpty;

  static DateTime? _parseDate(Object? raw) =>
      raw is String ? DateTime.tryParse(raw) : null;
}
