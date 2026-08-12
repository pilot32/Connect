import '../../../core/services/api_exception.dart';
import '../../../core/state/load_controller.dart';
import '../models/connection_models.dart';
import '../services/connections_service.dart';

/// How the current user relates to another official.
enum LinkStatus {
  none,

  /// The current user sent a request that hasn't been answered.
  outgoing,

  /// The other person sent a request awaiting the current user's decision.
  incoming,
  connected,
}

/// Network list and pending requests together.
///
/// They're fetched and held as one unit because the directory needs to know a
/// person's status across *both* to decide whether to show Connect, Pending,
/// or Connected — querying them separately would let the two drift.
class ConnectionsData {
  const ConnectionsData({required this.network, required this.requests});

  final List<NetworkConnection> network;
  final PendingRequests requests;
}

class ConnectionsController extends LoadController<ConnectionsData> {
  ConnectionsController(this._service);

  final ConnectionsService _service;

  /// Ids currently mid-request, so buttons can show a spinner and not be
  /// double-tapped.
  final Set<String> _busyIds = <String>{};

  bool isBusy(String id) => _busyIds.contains(id);

  @override
  Future<ConnectionsData> fetch() async {
    // Parallel: the two calls are independent and this halves the wait.
    final List<Object> results = await Future.wait(<Future<Object>>[
      _service.listConnections(),
      _service.listRequests(),
    ]);
    return ConnectionsData(
      network: results[0] as List<NetworkConnection>,
      requests: results[1] as PendingRequests,
    );
  }

  List<NetworkConnection> get network => data?.network ?? <NetworkConnection>[];
  PendingRequests get requests => data?.requests ?? const PendingRequests.empty();

  LinkStatus statusFor(String userId) {
    final ConnectionsData? current = data;
    if (current == null) return LinkStatus.none;

    for (final NetworkConnection c in current.network) {
      if (c.user.id == userId) return LinkStatus.connected;
    }
    for (final ConnectionRequest r in current.requests.incoming) {
      if (r.user.id == userId) return LinkStatus.incoming;
    }
    for (final ConnectionRequest r in current.requests.outgoing) {
      if (r.user.id == userId) return LinkStatus.outgoing;
    }
    return LinkStatus.none;
  }

  /// The row id needed to act on this relationship: a connection id when
  /// connected, otherwise the pending request id.
  String? actionableIdFor(String userId) {
    final ConnectionsData? current = data;
    if (current == null) return null;

    for (final NetworkConnection c in current.network) {
      if (c.user.id == userId) return c.connectionId;
    }
    for (final ConnectionRequest r in current.requests.incoming) {
      if (r.user.id == userId) return r.requestId;
    }
    for (final ConnectionRequest r in current.requests.outgoing) {
      if (r.user.id == userId) return r.requestId;
    }
    return null;
  }

  /// Each action refetches rather than patching local state: the server owns
  /// connection status, and a stale local guess here would show the wrong
  /// button on the directory.
  Future<String?> sendRequest(String userId) =>
      _run(userId, () => _service.sendRequest(userId));

  Future<String?> accept(String requestId) =>
      _run(requestId, () => _service.accept(requestId));

  Future<String?> decline(String requestId) =>
      _run(requestId, () => _service.decline(requestId));

  Future<String?> remove(String connectionId) =>
      _run(connectionId, () => _service.remove(connectionId));

  /// Returns null on success, or an error message to surface.
  Future<String?> _run(String busyId, Future<void> Function() action) async {
    if (_busyIds.contains(busyId)) return null;
    _busyIds.add(busyId);
    notifyListeners();

    String? failure;
    try {
      await action();
    } on ApiException catch (e) {
      failure = e.message;
    } catch (_) {
      failure = 'Something went wrong. Please try again.';
    } finally {
      _busyIds.remove(busyId);
    }

    await load(silent: true);
    return failure;
  }
}
