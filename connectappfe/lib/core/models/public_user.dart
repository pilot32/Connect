import 'package:connectappfe/core/models/user_profile.dart';

/// The `{ id, profile }` shape the API uses wherever it refers to *another*
/// official: directory results, connection parties, and feed post authors.
///
/// No email — that is only ever returned for the requester's own account.
class PublicUser {
  const PublicUser({required this.id, this.profile});

  factory PublicUser.fromJson(Map<String, dynamic> json) {
    final Object? profileJson = json['profile'];
    return PublicUser(
      id: json['id'] as String? ?? '',
      profile: profileJson is Map
          ? UserProfile.fromJson(profileJson.cast<String, dynamic>())
          : null,
    );
  }

  final String id;

  /// Nullable because the backend serialises `profile: null` if a user somehow
  /// has no profile row, rather than omitting the entry.
  final UserProfile? profile;

  String get displayName => profile?.name ?? 'Unknown official';
}

/// The signed-in user's own profile: `GET /profile/me` returns account *and*
/// profile, unlike the public shape.
class MyProfile {
  const MyProfile({required this.id, required this.email, this.profile});

  factory MyProfile.fromJson(Map<String, dynamic> json) {
    final user =
        (json['user'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final Object? profileJson = json['profile'];
    return MyProfile(
      id: user['id'] as String? ?? '',
      email: user['email'] as String? ?? '',
      profile: profileJson is Map
          ? UserProfile.fromJson(profileJson.cast<String, dynamic>())
          : null,
    );
  }

  final String id;
  final String email;
  final UserProfile? profile;
}
