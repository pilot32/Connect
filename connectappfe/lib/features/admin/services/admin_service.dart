import 'package:connectappfe/core/config/api_config.dart';
import 'package:connectappfe/core/services/api_client.dart';
import 'package:connectappfe/features/admin/models/applicant.dart';

/// `GET/POST /admin/*` — the approval console's backend.
///
/// Every call here requires an admin token; the server answers a non-admin
/// with `403 ADMIN_ONLY`, which surfaces as an ordinary [ApiException].
class AdminService {
  const AdminService(this._api);

  final ApiClient _api;

  Future<List<Applicant>> fetchApplicants({
    ApplicantFilter filter = ApplicantFilter.pending,
  }) async {
    final dynamic data = await _api.get(
      ApiConfig.adminUsers,
      query: <String, dynamic>{'status': filter.wire},
    );
    if (data is! List) return <Applicant>[];
    return data
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => Applicant.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<Applicant> fetchApplicant(String userId) async {
    final dynamic data = await _api.get(ApiConfig.adminUser(userId));
    return Applicant.fromJson(_asMap(data));
  }

  /// Both actions return the updated applicant, which is what lets the list
  /// move a row between tabs without refetching.
  Future<Applicant> approveApplicant(String userId) async {
    final dynamic data = await _api.post(ApiConfig.approveUser(userId));
    return Applicant.fromJson(_asMap(data));
  }

  Future<Applicant> rejectApplicant(String userId, {String? reason}) async {
    final trimmed = (reason ?? '').trim();
    final dynamic data = await _api.post(
      ApiConfig.rejectUser(userId),
      // Omitted rather than sent empty: the server validates `reason` as
      // 1-500 characters *if present*, so '' would be a 400.
      data: <String, dynamic>{if (trimmed.isNotEmpty) 'reason': trimmed},
    );
    return Applicant.fromJson(_asMap(data));
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return data.cast<String, dynamic>();
    return <String, dynamic>{};
  }
}
