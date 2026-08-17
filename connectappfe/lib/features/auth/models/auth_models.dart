import 'package:connectappfe/core/models/models.dart';

export '../../../core/models/models.dart';

/// What both `POST /auth/login` and `POST /auth/signup` hand back.
/// Login omits `profile`; signup includes it.
class AuthSession {
  const AuthSession({required this.token, required this.user, this.profile});

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

  final String token;
  final AuthUser user;
  final UserProfile? profile;
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
