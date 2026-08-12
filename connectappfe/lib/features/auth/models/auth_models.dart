import '../../../core/models/picked_image.dart';

export '../../../core/models/picked_image.dart';

/// Response models for the auth endpoints.
///
/// Hand-written `fromJson` rather than json_serializable: it avoids requiring a
/// `build_runner` step before the app will even compile, and these payloads are
/// small enough that codegen buys little.

class AuthUser {
  const AuthUser({required this.id, required this.email});

  final String id;

  /// Only ever populated for the signed-in user — the API omits email on other
  /// people's profiles.
  final String email;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.name,
    required this.designation,
    required this.service,
    required this.department,
    required this.stateOrCadre,
    required this.yearsInService,
    this.photoUrl,
    this.bio,
  });

  final String name;
  final String designation;
  final String service;
  final String department;
  final String stateOrCadre;
  final int yearsInService;
  final String? photoUrl;
  final String? bio;

  /// First letters of the first two words, e.g. "Asha Menon" -> "AM".
  /// Used as the avatar fallback when [photoUrl] is null.
  String get initials {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final String first = parts.first.substring(0, 1).toUpperCase();
    if (parts.length == 1) return first;
    return first + parts[1].substring(0, 1).toUpperCase();
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      service: json['service'] as String? ?? '',
      department: json['department'] as String? ?? '',
      stateOrCadre: json['stateOrCadre'] as String? ?? '',
      yearsInService: (json['yearsInService'] as num?)?.toInt() ?? 0,
      photoUrl: json['photoUrl'] as String?,
      bio: json['bio'] as String?,
    );
  }
}

/// What both `POST /auth/login` and `POST /auth/signup` hand back.
/// Login omits `profile`; signup includes it.
class AuthSession {
  const AuthSession({required this.token, required this.user, this.profile});

  final String token;
  final AuthUser user;
  final UserProfile? profile;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final Object? profileJson = json['profile'];
    return AuthSession(
      token: json['token'] as String? ?? '',
      user: AuthUser.fromJson(
        (json['user'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
      ),
      profile: profileJson is Map
          ? UserProfile.fromJson(profileJson.cast<String, dynamic>())
          : null,
    );
  }
}

/// Everything `POST /auth/signup` needs, gathered across the signup wizard's
/// steps before a single multipart request is sent.
class SignupDraft {
  SignupDraft();

  String email = '';
  String password = '';

  String name = '';
  String designation = '';
  String service = '';
  String department = '';
  String stateOrCadre = '';
  String yearsInService = '';
  String bio = '';

  /// Required by the backend — signup is rejected without it.
  PickedImage? idCardPhoto;
  PickedImage? profilePhoto;
}
