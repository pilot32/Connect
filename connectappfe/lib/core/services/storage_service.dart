import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the session across app launches.
///
/// The JWT goes into the OS keystore/keychain via [FlutterSecureStorage] rather
/// than SharedPreferences — it is a bearer credential, so plaintext prefs would
/// be the wrong home for it.
class StorageService {
  StorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'auth_user_id';
  static const String _emailKey = 'auth_email';
  static const String _roleKey = 'auth_role';
  static const String _statusKey = 'auth_status';
  static const String _rejectionReasonKey = 'auth_rejection_reason';

  /// Cached in memory so request interceptors stay synchronous and don't hit
  /// the keystore on every single call.
  String? _cachedToken;

  String? get cachedToken => _cachedToken;

  Future<String?> readToken() async {
    _cachedToken ??= await _readSafely(_tokenKey);
    return _cachedToken;
  }

  /// Role and status are persisted alongside the token so a returning user is
  /// routed to the right home — admin console, waiting room, or feed — on the
  /// very first frame, instead of landing on the feed and being bounced once
  /// the network catches up.
  ///
  /// They are a cache, not the authority: `AuthController.bootstrap` refreshes
  /// them from `GET /auth/status`, and the backend gates every request on the
  /// database regardless of what is stored here.
  Future<void> saveSession({
    required String token,
    required String userId,
    required String email,
    String? role,
    String? status,
    String? rejectionReason,
  }) async {
    _cachedToken = token;
    await Future.wait(<Future<void>>[
      _storage.write(key: _tokenKey, value: token),
      _storage.write(key: _userIdKey, value: userId),
      _storage.write(key: _emailKey, value: email),
      // A null value deletes the key, which is what clearing a stale
      // rejection reason on re-approval should do.
      _storage.write(key: _roleKey, value: role),
      _storage.write(key: _statusKey, value: status),
      _storage.write(key: _rejectionReasonKey, value: rejectionReason),
    ]);
  }

  Future<String?> readUserId() => _readSafely(_userIdKey);

  Future<String?> readEmail() => _readSafely(_emailKey);

  Future<String?> readRole() => _readSafely(_roleKey);

  Future<String?> readStatus() => _readSafely(_statusKey);

  Future<String?> readRejectionReason() => _readSafely(_rejectionReasonKey);

  Future<void> clear() async {
    _cachedToken = null;
    await Future.wait(<Future<void>>[
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _emailKey),
      _storage.delete(key: _roleKey),
      _storage.delete(key: _statusKey),
      _storage.delete(key: _rejectionReasonKey),
    ]);
  }

  /// A stored value that fails to decrypt is treated as absent, not as a
  /// crash. On web this backend decrypts via the browser's WebCrypto API; a
  /// mismatch between the stored ciphertext and the key held in localStorage
  /// (browser storage quirks, a half-cleared profile, anything) throws rather
  /// than returning null, and this was the *only* read in the app with
  /// nothing between it and `main()` — an uncaught exception here took the
  /// whole app down before the UI ever painted. Best-effort delete afterward
  /// so the corrupt entry doesn't keep failing every future launch.
  Future<String?> _readSafely(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('StorageService: failed to read "$key", treating as absent: $error');
      }
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'storage_service',
          context: ErrorDescription('reading "$key" from secure storage'),
        ),
      );
      unawaited(_storage.delete(key: key).catchError((_) {}));
      return null;
    }
  }
}
