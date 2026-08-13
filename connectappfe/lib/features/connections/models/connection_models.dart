import '../../../core/models/models.dart';

/// An accepted connection, as returned by `GET /connections`.
///
/// The API has already resolved which side of the connection is "the other
/// person", so the client never has to compare ids against the current user.
class NetworkConnection {
  const NetworkConnection({
    required this.connectionId,
    required this.user,
    this.since,
  });

  final String connectionId;
  final PublicUser user;
  final DateTime? since;

  factory NetworkConnection.fromJson(Map<String, dynamic> json) {
    return NetworkConnection(
      connectionId: json['connectionId'] as String? ?? '',
      user: PublicUser.fromJson(
        (json['user'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
      ),
      since: DateTime.tryParse(json['since'] as String? ?? ''),
    );
  }
}

/// A pending request from `GET /connections/requests`, in either direction.
class ConnectionRequest {
  const ConnectionRequest({
    required this.requestId,
    required this.user,
    required this.incoming,
    this.createdAt,
  });

  final String requestId;
  final PublicUser user;

  /// True when the current user is the *recipient* — i.e. this request is
  /// actionable via accept/decline. Outgoing requests can only be cancelled.
  final bool incoming;
  final DateTime? createdAt;

  factory ConnectionRequest.fromJson(
    Map<String, dynamic> json, {
    required bool incoming,
  }) {
    return ConnectionRequest(
      requestId: json['requestId'] as String? ?? '',
      user: PublicUser.fromJson(
        (json['user'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
      ),
      incoming: incoming,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}

/// Both directions of `GET /connections/requests` in one object.
class PendingRequests {
  const PendingRequests({required this.incoming, required this.outgoing});

  const PendingRequests.empty()
      : incoming = const <ConnectionRequest>[],
        outgoing = const <ConnectionRequest>[];

  final List<ConnectionRequest> incoming;
  final List<ConnectionRequest> outgoing;

  int get total => incoming.length + outgoing.length;

  factory PendingRequests.fromJson(Map<String, dynamic> json) {
    List<ConnectionRequest> parse(Object? raw, {required bool incoming}) {
      if (raw is! List) return <ConnectionRequest>[];
      return raw
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> e) =>
              ConnectionRequest.fromJson(e.cast<String, dynamic>(),
                  incoming: incoming))
          .toList();
    }

    return PendingRequests(
      incoming: parse(json['incoming'], incoming: true),
      outgoing: parse(json['outgoing'], incoming: false),
    );
  }
}
