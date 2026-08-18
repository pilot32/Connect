import 'dart:async';

import 'package:connectappfe/core/router/app_routes.dart';
import 'package:connectappfe/core/services/api_client.dart';
import 'package:connectappfe/core/services/api_exception.dart'
    show ApiException;
import 'package:connectappfe/core/services/storage_service.dart';
import 'package:connectappfe/features/auth/models/auth_models.dart';
import 'package:connectappfe/features/auth/services/auth_service.dart';
import 'package:flutter/foundation.dart';

enum AuthStatus {
  /// Still reading the stored token — the router shows a splash rather than
  /// flashing the login screen at a user who is already signed in.
  unknown,
  unauthenticated,
  authenticated,
}

/// Single source of truth for session state.
///
/// Doubles as the router's `refreshListenable`, so redirects re-evaluate the
/// moment a login succeeds or a token is rejected.
class AuthController extends ChangeNotifier {
  AuthController({
    required AuthService authService,
    required StorageService storage,
    required ApiClient apiClient,
  }) : _authService = authService,
       _storage = storage {
    apiClient.onUnauthorized = _handleUnauthorized;
  }

  final AuthService _authService;
  final StorageService _storage;

  AuthStatus _status = AuthStatus.unknown;
  AuthUser? _user;
  UserProfile? _profile;
  bool _isSubmitting = false;
  bool _isCheckingStatus = false;
  String? _statusCheckError;

  AuthStatus get status => _status;
  AuthUser? get user => _user;
  UserProfile? get profile => _profile;
  bool get isSubmitting => _isSubmitting;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// True while [checkApprovalStatus] is in flight, so the waiting screen's
  /// "Check status" button can show progress.
  bool get isCheckingStatus => _isCheckingStatus;

  /// Set when the last [checkApprovalStatus] failed, so the waiting screen can
  /// say the check didn't happen instead of silently looking like a no-change.
  String? get statusCheckError => _statusCheckError;

  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isApproved => _user?.isApproved ?? false;
  bool get isPending => _user?.isPending ?? false;
  bool get isRejected => _user?.isRejected ?? false;

  /// Whether the account is barred from the app's features. Distinct from
  /// `!isApproved`: an [AccountStatus.unknown] account isn't *known* to be
  /// barred, and treating it as such would strand a legacy session in the
  /// waiting room. Admins are reviewers, never applicants.
  bool get isAwaitingApproval => !isAdmin && (isPending || isRejected);

  /// Where this account belongs after signing in.
  ///
  /// One place decides, so the login screen, the signup screen, the splash and
  /// the router guard can't disagree about it.
  String get landingRoute {
    if (!isAuthenticated) return AppRoutes.login;
    if (isAdmin) return AppRoutes.admin;
    if (isAwaitingApproval) return AppRoutes.pendingApproval;
    return AppRoutes.afterLogin;
  }

  /// Restores a previous session, if any. Called once at startup, with
  /// nothing upstream of it (this runs straight out of `initState`) — so
  /// nothing here is allowed to throw. `StorageService` already treats a
  /// corrupt/undecryptable stored value as absent rather than throwing, but
  /// this outer guard is deliberate belt-and-suspenders: session restore is
  /// the one code path that runs unconditionally before the user has done
  /// anything, so any failure here — this one or one not yet foreseen —
  /// degrades to "not signed in" rather than crashing the app before it
  /// paints a single frame.
  Future<void> bootstrap() async {
    try {
      final token = await _storage.readToken();
      if (token == null || token.isEmpty) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      // We trust the stored token until the server says otherwise; the first
      // authenticated request will 401 and tear the session down if it's stale.
      final id = await _storage.readUserId();
      final email = await _storage.readEmail();
      _user = AuthUser(
        id: id ?? '',
        email: email ?? '',
        role: UserRole.parse(await _storage.readRole()),
        status: AccountStatus.restore(await _storage.readStatus()),
        rejectionReason: await _storage.readRejectionReason(),
      );
      _status = AuthStatus.authenticated;
      notifyListeners();

      // The cached status is a starting point, not the truth — an admin may
      // have decided while the app was closed. Unawaited so the splash hands
      // over on the stored value immediately and the screen swaps underneath
      // if the answer changed; a failure here leaves the cache in place.
      unawaited(checkApprovalStatus());
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'auth_controller',
          context: ErrorDescription('restoring session on startup'),
        ),
      );
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Throws [ApiException] on failure so the screen can show the message and
  /// highlight offending fields.
  Future<void> login({required String email, required String password}) async {
    _setSubmitting(true);
    try {
      final session = await _authService.login(
        email: email,
        password: password,
      );
      await _adopt(session);
    } finally {
      _setSubmitting(false);
    }
  }

  Future<void> signup(SignupDraft draft) async {
    _setSubmitting(true);
    try {
      final session = await _authService.signup(draft);
      await _adopt(session);
    } finally {
      _setSubmitting(false);
    }
  }

  /// Re-reads role, status and profile from `GET /auth/status`.
  ///
  /// The token's `status` claim is a snapshot from sign-in and stays `pending`
  /// for its full 7-day life, so this — not a re-login — is how an approved
  /// user gets in. Notifying afterwards is what moves them: the router listens
  /// to this controller, so the redirect re-runs and the waiting screen is
  /// replaced by the feed on its own.
  ///
  /// Never throws; the failure is exposed through [statusCheckError] because
  /// every caller (a background refresh, a button) wants to carry on either
  /// way.
  Future<void> checkApprovalStatus() async {
    if (_status != AuthStatus.authenticated || _isCheckingStatus) return;
    _isCheckingStatus = true;
    _statusCheckError = null;
    notifyListeners();

    try {
      final session = await _authService.checkStatus();
      // The endpoint mints no token, so keep the one already held.
      await _persist(session.user);
      _user = session.user;
      _profile = session.profile ?? _profile;
    } on ApiException catch (error) {
      // A 401 has already torn the session down via the client's interceptor;
      // surfacing "session expired" on a screen that is about to be replaced
      // by the login page would just be noise.
      if (!error.isUnauthorized) _statusCheckError = error.message;
    } catch (_) {
      _statusCheckError = 'Could not check your status. Please try again.';
    } finally {
      _isCheckingStatus = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _storage.clear();
    _user = null;
    _profile = null;
    _statusCheckError = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _adopt(AuthSession session) async {
    await _persist(session.user, token: session.token);
    _user = session.user;
    _profile = session.profile ?? _profile;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  /// Writes the account back to secure storage. [token] defaults to the one
  /// already stored, for refreshes that don't issue a new one.
  Future<void> _persist(AuthUser user, {String? token}) async {
    final resolved = token ?? await _storage.readToken();
    if (resolved == null || resolved.isEmpty) return;
    await _storage.saveSession(
      token: resolved,
      userId: user.id,
      email: user.email,
      role: user.role.wire,
      status: user.status.wire,
      rejectionReason: user.rejectionReason,
    );
  }

  /// A 401 on an authenticated request means the token is dead — drop it.
  ///
  /// Guarded on the current status because a failed *login* also returns 401,
  /// and that shouldn't be treated as a session expiry.
  void _handleUnauthorized() {
    if (_status != AuthStatus.authenticated) return;
    logout();
  }

  void _setSubmitting(bool value) {
    if (_isSubmitting == value) return;
    _isSubmitting = value;
    notifyListeners();
  }
}
