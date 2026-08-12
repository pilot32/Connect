import 'package:flutter/foundation.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';

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
  })  : _authService = authService,
        _storage = storage {
    apiClient.onUnauthorized = _handleUnauthorized;
  }

  final AuthService _authService;
  final StorageService _storage;

  AuthStatus _status = AuthStatus.unknown;
  AuthUser? _user;
  UserProfile? _profile;
  bool _isSubmitting = false;

  AuthStatus get status => _status;
  AuthUser? get user => _user;
  UserProfile? get profile => _profile;
  bool get isSubmitting => _isSubmitting;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Restores a previous session, if any. Called once at startup.
  Future<void> bootstrap() async {
    final String? token = await _storage.readToken();
    if (token == null || token.isEmpty) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    // We trust the stored token until the server says otherwise; the first
    // authenticated request will 401 and tear the session down if it's stale.
    final String? id = await _storage.readUserId();
    final String? email = await _storage.readEmail();
    _user = AuthUser(id: id ?? '', email: email ?? '');
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  /// Throws [ApiException] on failure so the screen can show the message and
  /// highlight offending fields.
  Future<void> login({required String email, required String password}) async {
    _setSubmitting(true);
    try {
      final AuthSession session =
          await _authService.login(email: email, password: password);
      await _adopt(session);
    } finally {
      _setSubmitting(false);
    }
  }

  Future<void> signup(SignupDraft draft) async {
    _setSubmitting(true);
    try {
      final AuthSession session = await _authService.signup(draft);
      await _adopt(session);
    } finally {
      _setSubmitting(false);
    }
  }

  Future<void> logout() async {
    await _storage.clear();
    _user = null;
    _profile = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _adopt(AuthSession session) async {
    await _storage.saveSession(
      token: session.token,
      userId: session.user.id,
      email: session.user.email,
    );
    _user = session.user;
    _profile = session.profile ?? _profile;
    _status = AuthStatus.authenticated;
    notifyListeners();
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
