import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  const AppEnv._();

  static String get apiBaseUrl {
    final envValue = dotenv.env['API_BASE_URL'] ?? '';
    if (envValue.isNotEmpty) return envValue.trim();

    if (kIsWeb) return 'http://localhost:3000';

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'http://10.0.2.2:3000',
      _ => 'http://localhost:3000',
    };
  }
}
