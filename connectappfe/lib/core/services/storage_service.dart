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
    _cachedToken ??= await _storage.read(key: _tokenKey);
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

  Future<String?> readUserId() => _storage.read(key: _userIdKey);

  Future<String?> readEmail() => _storage.read(key: _emailKey);

  Future<void> clear() async {
    _cachedToken = null;
    await Future.wait(<Future<void>>[
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _emailKey),
    ]);
  }
}
