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

  /// Cached in memory so request interceptors stay synchronous and don't hit
  /// the keystore on every single call.
  String? _cachedToken;

  String? get cachedToken => _cachedToken;

  Future<String?> readToken() async {
    _cachedToken ??= await _readSafely(_tokenKey);
    return _cachedToken;
  }

  Future<void> saveSession({
    required String token,
    required String userId,
    required String email,
  }) async {
    _cachedToken = token;
    await Future.wait(<Future<void>>[
      _storage.write(key: _tokenKey, value: token),
      _storage.write(key: _userIdKey, value: userId),
      _storage.write(key: _emailKey, value: email),
    ]);
  }

  Future<String?> readUserId() => _readSafely(_userIdKey);

  Future<String?> readEmail() => _readSafely(_emailKey);

  Future<void> clear() async {
    _cachedToken = null;
    await Future.wait(<Future<void>>[
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _emailKey),
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
