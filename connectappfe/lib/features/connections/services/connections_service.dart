import '../../../core/config/api_config.dart';
import '../../../core/services/api_client.dart';
import '../models/connection_models.dart';

/// The `/connections` endpoints: list, request, accept, decline, remove.
class ConnectionsService {
  const ConnectionsService(this._api);

  final ApiClient _api;

  /// "My Network" — accepted connections only.
  Future<List<NetworkConnection>> listConnections() async {
    final dynamic data = await _api.get(ApiConfig.connections);
    if (data is! List) return <NetworkConnection>[];
    return data
        .whereType<Map<dynamic, dynamic>>()
        .map((Map<dynamic, dynamic> e) =>
            NetworkConnection.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<PendingRequests> listRequests() async {
    final dynamic data = await _api.get(ApiConfig.connectionRequests);
    if (data is! Map) return const PendingRequests.empty();
    return PendingRequests.fromJson(data.cast<String, dynamic>());
  }

  Future<void> sendRequest(String userId) =>
      _api.post(ApiConfig.connectionRequest(userId));

  Future<void> accept(String requestId) =>
      _api.post(ApiConfig.acceptConnection(requestId));

  Future<void> decline(String requestId) =>
      _api.post(ApiConfig.declineConnection(requestId));

  /// Removes the connection row entirely.
  ///
  /// Semantics depend on status (see API_CONTRACT.md): a *pending* request can
  /// only be deleted by the requester (cancelling it), while an accepted one
  /// can be removed by either party. Deleting is also the only way to unblock
  /// re-requesting, since any surviving row blocks a new request.
  Future<void> remove(String connectionId) =>
      _api.delete(ApiConfig.deleteConnection(connectionId));
}
