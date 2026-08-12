import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/services/api_client.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/state/auth_controller.dart';

/// Root widget: builds the dependency graph once, then hands off to the router.
///
/// The graph is wired by hand rather than through a DI package — at this size
/// the explicit construction is easier to follow than a service locator.
class ConnectApp extends StatefulWidget {
  const ConnectApp({super.key});

  @override
  State<ConnectApp> createState() => _ConnectAppState();
}

class _ConnectAppState extends State<ConnectApp> {
  late final StorageService _storage = StorageService();
  late final ApiClient _apiClient = ApiClient(storage: _storage);
  late final AuthController _auth = AuthController(
    authService: AuthService(_apiClient),
    storage: _storage,
    apiClient: _apiClient,
  );
  late final GoRouter _router = buildRouter(_auth);

  @override
  void initState() {
    super.initState();
    // Kick off session restore; the router sits on the splash until it lands.
    _auth.bootstrap();
  }

  @override
  void dispose() {
    _auth.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: _storage),
        Provider<ApiClient>.value(value: _apiClient),
        ChangeNotifierProvider<AuthController>.value(value: _auth),
      ],
      child: MaterialApp.router(
        title: 'Connect',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: _router,
      ),
    );
  }
}
