import 'package:connectappfe/core/config/api_config.dart';
import 'package:connectappfe/core/models/models.dart';
import 'package:connectappfe/core/services/api_client.dart';

/// `GET /directory` — browse and filter officials.
///
/// All three filters are optional and combine with AND. Blank values are
/// dropped rather than sent as empty strings, which the server would treat as
/// a "match anything containing ''" filter.
class DirectoryService {
  const DirectoryService(this._api);

  final ApiClient _api;

  Future<List<PublicUser>> search({
    String? service,
    String? department,
    String? state,
  }) async {
    final query = <String, dynamic>{};
    void put(String key, String? value) {
      final trimmed = (value ?? '').trim();
      if (trimmed.isNotEmpty) query[key] = trimmed;
    }

    put('service', service);
    put('department', department);
    put('state', state);

    final dynamic data = await _api.get(ApiConfig.directory, query: query);
    if (data is! List) return <PublicUser>[];
    return data
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => PublicUser.fromJson(e.cast<String, dynamic>()))
        .toList();
  }
}
