import 'package:flutter/foundation.dart';

/// Build-time environment configuration.
///
/// Deliberately uses `String.fromEnvironment` rather than a bundled `.env`
/// file: `.env` is gitignored at the repo root, so an asset-based approach
/// would crash on a fresh clone. Override at run time with:
///
/// ```
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.5:3000
/// ```
class AppEnv {
  const AppEnv._();

  static const String _apiBaseUrlOverride =
      String.fromEnvironment('API_BASE_URL');

  /// Base URL of the Connect backend.
  ///
  /// Defaults are host-aware because "localhost" means different things
  /// depending on where the app runs: an Android emulator reaches the host
  /// machine on 10.0.2.2, while web/desktop can use localhost directly.
  /// A physical device needs your machine's LAN IP — pass it via
  /// `--dart-define=API_BASE_URL=...`.
  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
    if (kIsWeb) return 'http://localhost:3000';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'http://10.0.2.2:3000',
      _ => 'http://localhost:3000',
    };
  }
}
