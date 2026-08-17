import 'package:connectappfe/core/config/api_config.dart';
import 'package:connectappfe/core/models/models.dart';
import 'package:connectappfe/core/services/api_client.dart';
import 'package:dio/dio.dart';

/// `GET /profile/me`, `GET /profile/:id`, `PUT /profile/me`.
class ProfileService {
  const ProfileService(this._api);

  final ApiClient _api;

  Future<MyProfile> getMyProfile() async {
    final dynamic data = await _api.get(ApiConfig.myProfile);
    return MyProfile.fromJson(_asMap(data));
  }

  Future<PublicUser> getProfileById(String userId) async {
    final dynamic data = await _api.get(ApiConfig.profileById(userId));
    final json = _asMap(data);
    // The endpoint nests the id under `user`, so flatten it into the shape
    // PublicUser expects.
    return PublicUser(
      id: (json['user'] as Map?)?['id'] as String? ?? userId,
      profile: json['profile'] is Map
          ? UserProfile.fromJson(
              (json['profile'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }

  /// Partial update — only non-null values are sent, so omitted fields keep
  /// their current server-side value.
  Future<MyProfile> updateMyProfile({
    String? name,
    String? designation,
    String? service,
    String? department,
    String? stateOrCadre,
    int? yearsInService,
    String? bio,
    PickedImage? photo,
  }) async {
    final fields = <String, dynamic>{};
    void put(String key, String? value) {
      if (value != null) fields[key] = value;
    }

    put('name', name);
    put('designation', designation);
    put('service', service);
    put('department', department);
    put('stateOrCadre', stateOrCadre);
    // Sent as text; the backend coerces it.
    put('yearsInService', yearsInService?.toString());
    // Bio is deliberately allowed through empty — that is how you clear it.
    put('bio', bio);

    if (photo != null) {
      fields['photo'] = ApiClient.imagePart(photo.bytes, photo.filename);
    }

    final dynamic data = await _api.put(
      ApiConfig.myProfile,
      data: FormData.fromMap(fields),
    );
    return MyProfile.fromJson(_asMap(data));
  }

  Map<String, dynamic> _asMap(dynamic data) =>
      data is Map ? data.cast<String, dynamic>() : <String, dynamic>{};
}
