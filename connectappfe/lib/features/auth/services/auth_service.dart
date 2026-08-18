import 'package:connectappfe/core/config/api_config.dart';
import 'package:connectappfe/core/services/api_client.dart';
import 'package:connectappfe/features/auth/models/auth_models.dart';
import 'package:dio/dio.dart';

/// Talks to `POST /auth/login` and `POST /auth/signup`.
///
/// Shapes here follow `API_CONTRACT.md` exactly: login is plain JSON, signup is
/// `multipart/form-data` because it carries the ID card image.
class AuthService {
  const AuthService(this._api);

  final ApiClient _api;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final dynamic data = await _api.post(
      ApiConfig.login,
      data: <String, dynamic>{
        'email': email.trim(),
        'password': password,
      },
    );
    return AuthSession.fromJson(_asMap(data));
  }

  /// `GET /auth/status` — the account's live role/status/profile.
  ///
  /// Returns an [AuthSession] with an empty token: the endpoint doesn't mint
  /// one, and the caller is already holding a valid token to have reached it.
  Future<AuthSession> checkStatus() async {
    final dynamic data = await _api.get(ApiConfig.authStatus);
    return AuthSession.fromJson(_asMap(data));
  }

  Future<AuthSession> signup(SignupDraft draft) async {
    final fields = <String, dynamic>{
      'email': draft.email.trim(),
      'password': draft.password,
      'name': draft.name.trim(),
      'designation': draft.designation.trim(),
      'service': draft.service.trim(),
      'department': draft.department.trim(),
      'stateOrCadre': draft.stateOrCadre.trim(),
      // Sent as text; the backend coerces it with `z.coerce.number()`.
      'yearsInService': draft.yearsInService.trim(),
    };

    // Omit rather than send empty — `bio` is optional and an empty string is
    // noise in the database.
    final bio = draft.bio.trim();
    if (bio.isNotEmpty) {
      fields['bio'] = bio;
    }

    final idCard = draft.idCardPhoto;
    if (idCard == null) {
      // Guarded in the UI too, but failing here keeps the service honest if it
      // is ever called from somewhere else.
      throw StateError('idCardPhoto is required for signup');
    }
    fields['idCardPhoto'] = ApiClient.imagePart(idCard.bytes, idCard.filename);

    final avatar = draft.profilePhoto;
    if (avatar != null) {
      fields['profilePhoto'] = ApiClient.imagePart(
        avatar.bytes,
        avatar.filename,
      );
    }

    final dynamic data = await _api.post(
      ApiConfig.signup,
      data: FormData.fromMap(fields),
    );
    return AuthSession.fromJson(_asMap(data));
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return data.cast<String, dynamic>();
    return <String, dynamic>{};
  }
}
