import 'package:connectappfe/core/router/app_router.dart';
import 'package:connectappfe/core/services/api_client.dart';
import 'package:connectappfe/core/services/storage_service.dart';
import 'package:connectappfe/core/theme/app_theme.dart';
import 'package:connectappfe/features/auth/services/auth_service.dart';
import 'package:connectappfe/features/auth/state/auth_controller.dart';
import 'package:connectappfe/features/connections/services/connections_service.dart';
import 'package:connectappfe/features/connections/state/connections_controller.dart';
import 'package:connectappfe/features/directory/services/directory_service.dart';
import 'package:connectappfe/features/directory/state/directory_controller.dart';
import 'package:connectappfe/features/feed/services/feed_service.dart';
import 'package:connectappfe/features/feed/state/feed_controller.dart';
import 'package:connectappfe/features/profile/services/profile_service.dart';
import 'package:connectappfe/features/profile/state/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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

  late final AuthService _authService = AuthService(_apiClient);
  late final ProfileService _profileService = ProfileService(_apiClient);
  late final DirectoryService _directoryService = DirectoryService(_apiClient);
  late final ConnectionsService _connectionsService = ConnectionsService(
    _apiClient,
  );
  late final FeedService _feedService = FeedService(_apiClient);

  late final AuthController _auth = AuthController(
    authService: _authService,
    storage: _storage,
    apiClient: _apiClient,
  );
  late final ProfileController _profile = ProfileController(_profileService);
  late final DirectoryController _directory = DirectoryController(
    _directoryService,
  );
  late final ConnectionsController _connections = ConnectionsController(
    _connectionsService,
  );
  late final FeedController _feed = FeedController(_feedService);

  late final GoRouter _router = buildRouter(_auth);

  @override
  void initState() {
    super.initState();
    // Kick off session restore; the router sits on the splash until it lands.
    _auth.bootstrap();
  }

  @override
  void dispose() {
    _feed.dispose();
    _connections.dispose();
    _directory.dispose();
    _profile.dispose();
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
        Provider<ProfileService>.value(value: _profileService),
        Provider<DirectoryService>.value(value: _directoryService),
        Provider<ConnectionsService>.value(value: _connectionsService),
        Provider<FeedService>.value(value: _feedService),
        ChangeNotifierProvider<AuthController>.value(value: _auth),
        ChangeNotifierProvider<ProfileController>.value(value: _profile),
        ChangeNotifierProvider<DirectoryController>.value(value: _directory),
        ChangeNotifierProvider<ConnectionsController>.value(
          value: _connections,
        ),
        ChangeNotifierProvider<FeedController>.value(value: _feed),
      ],
      child: MaterialApp.router(
        title: 'Connect',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        // Light-only by product decision: no darkTheme is supplied, so the
        // system setting cannot pull the app into a dark palette.
        themeMode: ThemeMode.light,
        routerConfig: _router,
      ),
    );
  }
}
