import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'providers/token_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/token/active_token_screen.dart';
import 'services/notification_service.dart';
import 'services/profile_service.dart';
import 'services/socket_service.dart';
import 'services/token_service.dart';
import 'widgets/smartq_splash_view.dart';
import 'utils/brand_colors.dart';

const Color smartQBrandBlue =
Color(0xFF1E6DFB);

final GlobalKey<NavigatorState> navigatorKey =
GlobalKey<NavigatorState>();

final AppNavigatorObserver appNavigatorObserver =
AppNavigatorObserver();

class AppNavigatorObserver
    extends NavigatorObserver {
  String? currentRouteName;

  @override
  void didPush(
      Route<dynamic> route,
      Route<dynamic>? previousRoute,
      ) {
    currentRouteName =
        route.settings.name;

    debugPrint(
      'Navigator pushed route: '
          '$currentRouteName',
    );

    super.didPush(
      route,
      previousRoute,
    );
  }

  @override
  void didReplace({
    Route<dynamic>? newRoute,
    Route<dynamic>? oldRoute,
  }) {
    currentRouteName =
        newRoute?.settings.name;

    debugPrint(
      'Navigator replaced route: '
          '$currentRouteName',
    );

    super.didReplace(
      newRoute: newRoute,
      oldRoute: oldRoute,
    );
  }

  @override
  void didPop(
      Route<dynamic> route,
      Route<dynamic>? previousRoute,
      ) {
    currentRouteName =
        previousRoute?.settings.name;

    debugPrint(
      'Navigator returned to route: '
          '$currentRouteName',
    );

    super.didPop(
      route,
      previousRoute,
    );
  }

  @override
  void didRemove(
      Route<dynamic> route,
      Route<dynamic>? previousRoute,
      ) {
    debugPrint(
      'Navigator removed route: '
          '${route.settings.name}',
    );

    super.didRemove(
      route,
      previousRoute,
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Render Flutter immediately so Android can remove
  // the native splash as soon as possible.
  runApp(
    const SmartQBootstrap(),
  );
}

class SmartQBootstrap
    extends StatefulWidget {
  const SmartQBootstrap({
    super.key,
  });

  @override
  State<SmartQBootstrap> createState() =>
      _SmartQBootstrapState();
}

class _SmartQBootstrapState
    extends State<SmartQBootstrap> {
  ThemeProvider? _themeProvider;

  Object? _initializationError;

  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();

    _initializeApplication();
  }

  Future<void> _initializeApplication() async {
    if (_isInitializing) {
      return;
    }

    _isInitializing = true;

    if (mounted) {
      setState(() {
        _initializationError = null;
      });
    }

    try {
      final ThemeProvider themeProvider =
      ThemeProvider();

      // Firebase and the saved theme are independent,
      // so initialize them at the same time.
      await Future.wait<void>([
        Firebase.initializeApp(
          options:
          DefaultFirebaseOptions
              .currentPlatform,
        ),
        themeProvider.initialize(),
      ]);

      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _themeProvider =
            themeProvider;
      });
    } catch (
    error,
    stackTrace,
    )
    {
    debugPrint(
    'Application initialization failed: '
    '$error',
    );

    debugPrintStack(
    stackTrace: stackTrace,
    );

    if (!mounted) {
    return;
    }

    setState(() {
    _initializationError =
    error;
    });
    } finally {
    _isInitializing = false;
    }
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final Object? initializationError =
        _initializationError;

    if (initializationError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner:
        false,
        title:
        'Hospital Queue Management',
        theme:
        _buildLightTheme(),
        darkTheme:
        _buildDarkTheme(),
        home:
        _InitializationErrorScreen(
          onRetry:
          _initializeApplication,
        ),
      );
    }

    final ThemeProvider? themeProvider =
        _themeProvider;

    if (themeProvider == null) {
      return MaterialApp(
        debugShowCheckedModeBanner:
        false,
        title:
        'Hospital Queue Management',
        theme:
        _buildLightTheme(),
        darkTheme:
        _buildDarkTheme(),
        home:
        const _BootstrapSplashScreen(),
      );
    }

    return HospitalQueueApp(
      themeProvider:
      themeProvider,
    );
  }
}

class _BootstrapSplashScreen
    extends StatelessWidget {
  const _BootstrapSplashScreen();

  @override
  Widget build(BuildContext context) {
    return const SmartQSplashView();
  }
}

class _InitializationErrorScreen
    extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _InitializationErrorScreen({
    required this.onRetry,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final ThemeData theme =
    Theme.of(context);

    return Scaffold(
      backgroundColor:
      theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
            const EdgeInsets.all(
              24,
            ),
            child: Container(
              width: double.infinity,
              padding:
              const EdgeInsets.all(
                24,
              ),
              decoration: BoxDecoration(
                color:
                theme.cardColor,
                borderRadius:
                BorderRadius.circular(
                  22,
                ),
                border: Border.all(
                  color:
                  theme.dividerColor,
                ),
              ),
              child: Column(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  Icon(
                    Icons
                        .error_outline_rounded,
                    size: 58,
                    color: theme
                        .colorScheme
                        .error,
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Text(
                    'SmartQ could not start',
                    textAlign:
                    TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                      FontWeight.bold,
                      color: theme
                          .colorScheme
                          .onSurface,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    'Please check your internet connection and try again.',
                    textAlign:
                    TextAlign.center,
                    style: TextStyle(
                      color: theme
                          .colorScheme
                          .onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(
                    height: 22,
                  ),
                  SizedBox(
                    width:
                    double.infinity,
                    height: 52,
                    child:
                    ElevatedButton.icon(
                      onPressed: () {
                        unawaited(
                          onRetry(),
                        );
                      },
                      icon: const Icon(
                        Icons
                            .refresh_rounded,
                      ),
                      label: const Text(
                        'Retry',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HospitalQueueApp
    extends StatelessWidget {
  final ThemeProvider themeProvider;

  const HospitalQueueApp({
    super.key,
    required this.themeProvider,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<
            ThemeProvider>.value(
          value:
          themeProvider,
        ),
        ChangeNotifierProvider<
            TokenProvider>(
          create: (_) =>
              TokenProvider(),
        ),
      ],
      child:
      const AppSocketBootstrap(),
    );
  }
}

class AppSocketBootstrap
    extends StatefulWidget {
  const AppSocketBootstrap({
    super.key,
  });

  @override
  State<AppSocketBootstrap> createState() =>
      _AppSocketBootstrapState();
}

class _AppSocketBootstrapState
    extends State<AppSocketBootstrap>
    with WidgetsBindingObserver {
  final TokenService _tokenService =
  TokenService();

  final ProfileService _profileService =
  ProfileService();

  final SocketService _socketService =
      SocketService.instance;

  final NotificationService
  _notificationService =
      NotificationService.instance;

  StreamSubscription<User?>?
  _authSubscription;

  bool _isRestoringToken = false;
  bool _isInitializingNotifications =
  false;
  bool _isSavingFcmToken = false;
  bool _isOpeningNotificationScreen =
  false;

  String? _joinedTokenId;

  Map<String, dynamic>?
  _pendingNotificationData;

  String?
  _lastOpenedNotificationTokenId;

  DateTime?
  _lastNotificationNavigationTime;

  AppLifecycleState _appLifecycleState =
      AppLifecycleState.resumed;

  String?
  _lastForegroundNotificationKey;

  DateTime?
  _lastForegroundNotificationTime;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(
      this,
    );

    _appLifecycleState =
        WidgetsBinding
            .instance
            .lifecycleState ??
            AppLifecycleState.resumed;

    _authSubscription =
        FirebaseAuth.instance
            .authStateChanges()
            .listen(
          _handleAuthenticationChange,
          onError: (
              Object error,
              ) {
            debugPrint(
              'Authentication state error: '
                  '$error',
            );
          },
        );
  }

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state,
      ) {
    _appLifecycleState = state;

    debugPrint(
      'App lifecycle state changed: '
          '$state',
    );

    if (state ==
        AppLifecycleState.resumed &&
        _pendingNotificationData !=
            null) {
      unawaited(
        _openPendingNotification(),
      );
    }
  }

  Future<void>
  _handleAuthenticationChange(
      User? firebaseUser,
      ) async {
    if (!mounted) {
      return;
    }

    if (firebaseUser == null) {
      await _handleLogout();
      return;
    }

    debugPrint(
      'Authenticated Firebase UID: '
          '${firebaseUser.uid}',
    );

    _connectGlobalSocket();

    await _initializeNotifications();

    await Future<void>.delayed(
      const Duration(
        seconds: 2,
      ),
    );

    await _forceSaveFcmToken();

    await _restoreActiveToken();

    await _openPendingNotification();
  }

  Future<void> _forceSaveFcmToken() async {
    if (_isSavingFcmToken) {
      return;
    }

    _isSavingFcmToken = true;

    try {
      const int maximumAttempts = 3;

      for (
      int attempt = 1;
      attempt <= maximumAttempts;
      attempt++
      ) {
        try {
          debugPrint(
            'Requesting FCM token, '
                'attempt $attempt',
          );

          final NotificationSettings settings =
          await FirebaseMessaging
              .instance
              .requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );

          debugPrint(
            'FCM permission status: '
                '${settings.authorizationStatus}',
          );

          final String? rawToken =
          await FirebaseMessaging
              .instance
              .getToken();

          final String fcmToken =
              rawToken?.trim() ?? '';

          debugPrint(
            'DIRECT FCM TOKEN: '
                '${fcmToken.isEmpty ? 'EMPTY' : fcmToken}',
          );

          if (fcmToken.isEmpty) {
            if (attempt <
                maximumAttempts) {
              await Future<void>.delayed(
                const Duration(
                  seconds: 3,
                ),
              );

              continue;
            }

            debugPrint(
              'DIRECT FCM ERROR: '
                  'token is empty',
            );

            return;
          }

          await _profileService
              .updateFcmToken(
            fcmToken,
          );

          debugPrint(
            'DIRECT FCM TOKEN SAVED '
                'TO MONGODB',
          );

          return;
        } catch (error) {
          debugPrint(
            'DIRECT FCM SAVE ATTEMPT '
                '$attempt ERROR: $error',
          );

          if (attempt <
              maximumAttempts) {
            await Future<void>.delayed(
              const Duration(
                seconds: 3,
              ),
            );
          }
        }
      }

      debugPrint(
        'DIRECT FCM SAVE FAILED '
            'AFTER ALL ATTEMPTS',
      );
    } finally {
      _isSavingFcmToken = false;
    }
  }

  Future<void> _handleLogout() async {
    final String? joinedTokenId =
        _joinedTokenId;

    if (joinedTokenId != null &&
        joinedTokenId.isNotEmpty) {
      _socketService.leaveTokenRoom(
        joinedTokenId,
      );
    }

    _joinedTokenId = null;

    _pendingNotificationData = null;
    _lastOpenedNotificationTokenId =
    null;
    _lastNotificationNavigationTime =
    null;

    _lastForegroundNotificationKey =
    null;
    _lastForegroundNotificationTime =
    null;

    if (mounted) {
      context
          .read<TokenProvider>()
          .clearToken();
    }

    _socketService.disconnect();

    await _notificationService
        .unsubscribeFromAllListeners();

    debugPrint(
      'Global services disconnected: '
          'user logged out',
    );
  }

  void _connectGlobalSocket() {
    _socketService.connect(
      onTokenUpdated:
      _handleTokenUpdated,
      onQueueUpdated:
      _handleQueueUpdated,
      onTokenDeleted:
      _handleTokenDeleted,
      onNotificationReceived:
      _handleSocketNotification,
    );
  }

  Future<void>
  _initializeNotifications() async {
    if (_isInitializingNotifications) {
      return;
    }

    _isInitializingNotifications =
    true;

    try {
      await _notificationService
          .initialize(
        onTokenAvailable: (
            String fcmToken,
            ) async {
          final String normalizedToken =
          fcmToken.trim();

          if (normalizedToken.isEmpty) {
            debugPrint(
              'Notification service '
                  'returned an empty FCM token',
            );

            return;
          }

          try {
            await _profileService
                .updateFcmToken(
              normalizedToken,
            );

            debugPrint(
              'FCM token saved to MongoDB',
            );
          } catch (error) {
            debugPrint(
              'FCM token save error: '
                  '$error',
            );
          }
        },
        onNotificationOpened: (
            Map<String, dynamic> data,
            ) {
          _handleNotificationOpened(
            data,
          );
        },
      );
    } catch (
    error,
    stackTrace
    ) {
      debugPrint(
        'Notification initialization '
            'error: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );
    } finally {
      _isInitializingNotifications =
      false;
    }
  }

  void _handleNotificationOpened(
      Map<String, dynamic> data,
      ) {
    debugPrint(
      'Notification opened: $data',
    );

    _pendingNotificationData =
    Map<String, dynamic>.from(
      data,
    );

    unawaited(
      _openPendingNotification(),
    );
  }

  Future<bool>
  _waitUntilHomeScreenIsReady() async {
    const int maximumAttempts = 60;

    for (
    int attempt = 1;
    attempt <= maximumAttempts;
    attempt++
    ) {
      if (!mounted) {
        return false;
      }

      final NavigatorState? navigator =
          navigatorKey.currentState;

      final String? currentRoute =
          appNavigatorObserver
              .currentRouteName;

      debugPrint(
        'Waiting for HomeScreen: '
            'attempt=$attempt, '
            'route=$currentRoute',
      );

      if (navigator != null &&
          currentRoute == '/home') {
        await Future<void>.delayed(
          const Duration(
            milliseconds: 500,
          ),
        );

        debugPrint(
          'HomeScreen ready for '
              'notification navigation',
        );

        return true;
      }

      await Future<void>.delayed(
        const Duration(
          milliseconds: 250,
        ),
      );
    }

    debugPrint(
      'HomeScreen did not become ready',
    );

    return false;
  }

  Future<void>
  _openPendingNotification() async {
    if (_isOpeningNotificationScreen) {
      return;
    }

    final Map<String, dynamic>? data =
        _pendingNotificationData;

    if (data == null) {
      return;
    }

    if (FirebaseAuth
        .instance
        .currentUser ==
        null) {
      debugPrint(
        'Notification navigation '
            'waiting for login',
      );

      return;
    }

    _isOpeningNotificationScreen =
    true;

    try {
      if (!mounted) {
        return;
      }

      TokenProvider provider =
      context.read<TokenProvider>();

      if (!provider.hasActiveToken) {
        await _restoreActiveToken();

        if (!mounted) {
          return;
        }

        provider =
            context.read<TokenProvider>();
      }

      if (!provider.hasActiveToken) {
        debugPrint(
          'Notification navigation '
              'skipped: no active token '
              'available',
        );

        _pendingNotificationData =
        null;
        return;
      }

      final String notificationTokenId =
          data['tokenId']
              ?.toString()
              .trim() ??
              '';

      final String activeTokenId =
          provider.tokenId?.trim() ?? '';

      if (activeTokenId.isEmpty) {
        debugPrint(
          'Notification navigation '
              'skipped: active token ID '
              'is empty',
        );

        _pendingNotificationData =
        null;
        return;
      }

      if (notificationTokenId
          .isNotEmpty &&
          notificationTokenId !=
              activeTokenId) {
        debugPrint(
          'Notification token does '
              'not match the restored '
              'active token',
        );

        _pendingNotificationData =
        null;
        return;
      }

      if (_isDuplicateNotificationNavigation(
        activeTokenId,
      )) {
        debugPrint(
          'Duplicate notification '
              'navigation ignored',
        );

        _pendingNotificationData =
        null;
        return;
      }

      final bool homeReady =
      await _waitUntilHomeScreenIsReady();

      if (!homeReady || !mounted) {
        debugPrint(
          'Notification navigation '
              'delayed: HomeScreen is '
              'not ready',
        );

        return;
      }

      final NavigatorState? navigator =
          navigatorKey.currentState;

      if (navigator == null) {
        debugPrint(
          'Navigator is not ready; '
              'notification navigation '
              'will retry',
        );

        return;
      }

      _rememberNotificationNavigation(
        activeTokenId,
      );

      _pendingNotificationData = null;

      await navigator.push(
        MaterialPageRoute<void>(
          settings: RouteSettings(
            name:
            '/active-token/$activeTokenId',
          ),
          builder: (_) =>
              ActiveTokenScreen(
                tokenId: activeTokenId,
                tokenNumber:
                provider.tokenNumber
                    ?.trim() ??
                    data['tokenCode']
                        ?.toString()
                        .trim() ??
                    '',
                hospitalName:
                provider.hospitalName
                    ?.trim() ??
                    '',
                departmentName:
                provider.departmentName
                    ?.trim() ??
                    '',
                currentQueue:
                provider.currentQueue ??
                    0,
                estimatedTime:
                provider.estimatedTime
                    ?.trim() ??
                    '--',
                issuedTime:
                provider.issuedTime
                    ?.trim() ??
                    '--',
                status: provider.status
                    .trim()
                    .isEmpty
                    ? data['status']
                    ?.toString()
                    .trim() ??
                    'Waiting'
                    : provider.status.trim(),
              ),
        ),
      );

      debugPrint(
        'Active Token screen opened '
            'from notification',
      );
    } catch (
    error,
    stackTrace
    ) {
      debugPrint(
        'Notification navigation '
            'error: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );
    } finally {
      _isOpeningNotificationScreen =
      false;
    }
  }

  bool _isDuplicateNotificationNavigation(
      String tokenId,
      ) {
    final DateTime? previousTime =
        _lastNotificationNavigationTime;

    if (_lastOpenedNotificationTokenId !=
        tokenId ||
        previousTime == null) {
      return false;
    }

    return DateTime.now()
        .difference(
      previousTime,
    )
        .inSeconds <
        3;
  }

  void _rememberNotificationNavigation(
      String tokenId,
      ) {
    _lastOpenedNotificationTokenId =
        tokenId;

    _lastNotificationNavigationTime =
        DateTime.now();
  }

  Future<void>
  _restoreActiveToken() async {
    if (_isRestoringToken) {
      while (_isRestoringToken) {
        await Future<void>.delayed(
          const Duration(
            milliseconds: 100,
          ),
        );
      }

      return;
    }

    _isRestoringToken = true;

    try {
      final Map<String, dynamic>?
      activeToken =
      await _tokenService
          .getActiveToken();

      if (!mounted) {
        return;
      }

      if (activeToken == null) {
        debugPrint(
          'No active token found',
        );

        context
            .read<TokenProvider>()
            .clearToken();

        return;
      }

      final String tokenId =
          activeToken['id']
              ?.toString()
              .trim() ??
              '';

      final String tokenNumber =
          activeToken['tokenCode']
              ?.toString()
              .trim() ??
              '';

      if (tokenId.isEmpty ||
          tokenNumber.isEmpty) {
        debugPrint(
          'Active token recovery '
              'failed: token ID or code '
              'is empty',
        );

        return;
      }

      final int currentQueue =
      _parseInteger(
        activeToken['currentQueue'],
      );

      final int peopleAhead =
      _parseInteger(
        activeToken['peopleAhead'],
      );

      final int estimatedMinutes =
      _parseInteger(
        activeToken[
        'estimatedMinutes'],
      );

      final String estimatedTime =
          activeToken['estimatedTime']
              ?.toString()
              .trim() ??
              '--';

      final String status =
          activeToken['status']
              ?.toString()
              .trim() ??
              'Waiting';

      context
          .read<TokenProvider>()
          .setToken(
        tokenId: tokenId,
        tokenNumber: tokenNumber,
        hospitalId:
        activeToken['hospitalId']
            ?.toString()
            .trim() ??
            '',
        hospitalName:
        activeToken['hospitalName']
            ?.toString()
            .trim() ??
            '',
        departmentId:
        activeToken['departmentId']
            ?.toString()
            .trim() ??
            '',
        departmentName:
        activeToken[
        'departmentName']
            ?.toString()
            .trim() ??
            '',
        currentQueue: currentQueue,
        peopleAhead: peopleAhead,
        estimatedMinutes:
        estimatedMinutes,
        estimatedTime: estimatedTime,
        issuedTime:
        _formatIssuedTime(
          activeToken['createdAt'],
        ),
        status: status.isEmpty
            ? 'Waiting'
            : status,
      );

      _joinTokenRoom(
        tokenId,
      );

      debugPrint(
        'Active token restored '
            'globally: $tokenNumber',
      );
    } catch (error) {
      debugPrint(
        'Active token recovery error: '
            '$error',
      );
    } finally {
      _isRestoringToken = false;
    }
  }

  void _joinTokenRoom(
      String tokenId,
      ) {
    final String normalizedId =
    tokenId.trim();

    if (normalizedId.isEmpty ||
        _joinedTokenId ==
            normalizedId) {
      return;
    }

    final String? previousTokenId =
        _joinedTokenId;

    if (previousTokenId != null &&
        previousTokenId.isNotEmpty) {
      _socketService.leaveTokenRoom(
        previousTokenId,
      );
    }

    _joinedTokenId = normalizedId;

    _socketService.joinTokenRoom(
      normalizedId,
    );

    debugPrint(
      'Global socket joining token '
          'room: token:$normalizedId',
    );
  }

  void _handleTokenUpdated(
      Map<String, dynamic> data,
      ) {
    if (!mounted) {
      return;
    }

    final TokenProvider provider =
    context.read<TokenProvider>();

    final String updatedTokenId =
        data['tokenId']
            ?.toString()
            .trim() ??
            '';

    if (updatedTokenId.isEmpty) {
      return;
    }

    final String providerTokenId =
        provider.tokenId?.trim() ?? '';

    if (providerTokenId.isNotEmpty &&
        providerTokenId !=
            updatedTokenId) {
      return;
    }

    provider.updateToken(
      status:
      data['status']
          ?.toString()
          .trim(),
      currentQueue:
      _tryParseInteger(
        data['currentQueue'],
      ),
      peopleAhead:
      _tryParseInteger(
        data['peopleAhead'],
      ),
      estimatedMinutes:
      _tryParseInteger(
        data['estimatedMinutes'],
      ),
      estimatedTime:
      data['estimatedTime']
          ?.toString()
          .trim(),
    );

    debugPrint(
      'Global token update received: '
          '$data',
    );
  }

  void _handleQueueUpdated(
      Map<String, dynamic> data,
      ) {
    if (!mounted) {
      return;
    }

    final TokenProvider provider =
    context.read<TokenProvider>();

    if (!provider.hasActiveToken) {
      return;
    }

    final String eventDepartmentId =
        data['departmentId']
            ?.toString()
            .trim() ??
            '';

    final String providerDepartmentId =
        provider.departmentId?.trim() ??
            '';

    if (eventDepartmentId.isNotEmpty &&
        providerDepartmentId
            .isNotEmpty &&
        eventDepartmentId !=
            providerDepartmentId) {
      return;
    }

    provider.updateQueue(
      currentQueue:
      _tryParseInteger(
        data['currentQueue'],
      ),
      peopleAhead:
      _tryParseInteger(
        data['peopleAhead'],
      ),
      estimatedMinutes:
      _tryParseInteger(
        data['estimatedMinutes'],
      ),
      estimatedTime:
      data['estimatedTime']
          ?.toString()
          .trim(),
    );
  }

  bool _isDuplicateForegroundNotification(
      String notificationKey,
      ) {
    final DateTime? previousTime =
        _lastForegroundNotificationTime;

    if (_lastForegroundNotificationKey !=
        notificationKey ||
        previousTime == null) {
      return false;
    }

    return DateTime.now()
        .difference(
      previousTime,
    )
        .inSeconds <
        5;
  }

  void _rememberForegroundNotification(
      String notificationKey,
      ) {
    _lastForegroundNotificationKey =
        notificationKey;

    _lastForegroundNotificationTime =
        DateTime.now();
  }

  void _handleSocketNotification(
      Map<String, dynamic> data,
      ) {
    if (!mounted) {
      return;
    }

    final bool appIsVisible =
        _appLifecycleState ==
            AppLifecycleState.resumed ||
            _appLifecycleState ==
                AppLifecycleState.inactive;

    if (!appIsVisible) {
      return;
    }

    final TokenProvider provider =
    context.read<TokenProvider>();

    final String message =
        data['message']
            ?.toString()
            .trim() ??
            '';

    final RegExpMatch? match = RegExp(
      r'Token\s+([A-Za-z0-9_-]+)\s+status changed to\s+(.+)',
      caseSensitive: false,
    ).firstMatch(
      message,
    );

    final String tokenCode =
        match?.group(1)?.trim() ??
            provider.tokenNumber
                ?.trim() ??
            'Token';

    final String status =
        match?.group(2)?.trim() ??
            provider.status.trim();

    if (status.isEmpty) {
      return;
    }

    final String notificationKey =
        'socket-notification:$message';

    if (_isDuplicateForegroundNotification(
      notificationKey,
    )) {
      return;
    }

    _rememberForegroundNotification(
      notificationKey,
    );

    unawaited(
      _notificationService
          .showTokenUpdateNotification(
        tokenId:
        provider.tokenId?.trim() ??
            '',
        tokenCode: tokenCode,
        status: status,
        hospitalId:
        provider.hospitalId
            ?.trim() ??
            '',
        departmentId:
        provider.departmentId
            ?.trim() ??
            '',
      ),
    );
  }

  void _handleTokenDeleted(
      Map<String, dynamic> data,
      ) {
    if (!mounted) {
      return;
    }

    final TokenProvider provider =
    context.read<TokenProvider>();

    final String deletedTokenId =
        data['tokenId']
            ?.toString()
            .trim() ??
            '';

    final String providerTokenId =
        provider.tokenId?.trim() ?? '';

    if (deletedTokenId.isNotEmpty &&
        providerTokenId.isNotEmpty &&
        deletedTokenId !=
            providerTokenId) {
      return;
    }

    provider.clearToken();

    final String? joinedTokenId =
        _joinedTokenId;

    if (joinedTokenId != null &&
        joinedTokenId.isNotEmpty) {
      _socketService.leaveTokenRoom(
        joinedTokenId,
      );
    }

    _joinedTokenId = null;
  }

  int _parseInteger(
      dynamic value,
      ) {
    return _tryParseInteger(
      value,
    ) ??
        0;
  }

  int? _tryParseInteger(
      dynamic value,
      ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString().trim() ?? '',
    );
  }

  String _formatIssuedTime(
      dynamic value,
      ) {
    if (value == null) {
      return '--';
    }

    final DateTime? dateTime =
    DateTime.tryParse(
      value.toString(),
    )?.toLocal();

    if (dateTime == null) {
      return '--';
    }

    int hour = dateTime.hour;

    final String minute =
    dateTime.minute
        .toString()
        .padLeft(
      2,
      '0',
    );

    final String period =
    hour >= 12 ? 'PM' : 'AM';

    hour %= 12;

    if (hour == 0) {
      hour = 12;
    }

    return '$hour:$minute $period';
  }

  @override
  void dispose() {
    WidgetsBinding.instance
        .removeObserver(
      this,
    );

    _authSubscription?.cancel();

    final String? joinedTokenId =
        _joinedTokenId;

    if (joinedTokenId != null &&
        joinedTokenId.isNotEmpty) {
      _socketService.leaveTokenRoom(
        joinedTokenId,
      );
    }

    _socketService.disconnect();

    unawaited(
      _notificationService
          .unsubscribeFromAllListeners(),
    );

    super.dispose();
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Consumer<ThemeProvider>(
      builder: (
          BuildContext context,
          ThemeProvider themeProvider,
          Widget? child,
          ) {
        debugPrint(
          'MaterialApp rebuilding: '
              'darkMode='
              '${themeProvider.isDarkMode}, '
              'themeMode='
              '${themeProvider.themeMode}',
        );

        return MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [
            appNavigatorObserver,
          ],
          debugShowCheckedModeBanner:
          false,
          title:
          'Hospital Queue Management',
          themeMode:
          themeProvider.themeMode,
          theme:
          _buildLightTheme(),
          darkTheme:
          _buildDarkTheme(),

          // Keep the branded Flutter splash.
          home:
          const SplashScreen(),
        );
      },
    );
  }
}

ThemeData _buildLightTheme() {
  const Color backgroundColor =
  Color(0xFFF7F9FC);

  const Color cardColor =
  Color(0xFFFFFFFF);

  const Color borderColor =
  Color(0xFFE2E8F0);

  const Color primaryTextColor =
  Color(0xFF0F172A);

  const Color secondaryTextColor =
  Color(0xFF64748B);

  final ColorScheme colorScheme =
  ColorScheme.fromSeed(
    seedColor: smartQBrandBlue,
    brightness: Brightness.light,
    primary: smartQBrandBlue,
    onPrimary: Colors.white,
    surface: cardColor,
    onSurface: primaryTextColor,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    scaffoldBackgroundColor:
    backgroundColor,
    cardColor: cardColor,
    dividerColor: borderColor,
    canvasColor: cardColor,
    dialogBackgroundColor: cardColor,
    splashColor:
    smartQBrandBlue.withOpacity(
      0.08,
    ),
    highlightColor:
    smartQBrandBlue.withOpacity(
      0.04,
    ),
    appBarTheme:
    const AppBarTheme(
      backgroundColor: cardColor,
      surfaceTintColor: cardColor,
      foregroundColor:
      primaryTextColor,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(
        color: primaryTextColor,
      ),
      titleTextStyle: TextStyle(
        color: primaryTextColor,
        fontSize: 21,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme:
    const TextTheme(
      headlineSmall: TextStyle(
        color: primaryTextColor,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        color: primaryTextColor,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        color: primaryTextColor,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: primaryTextColor,
      ),
      bodyMedium: TextStyle(
        color: primaryTextColor,
      ),
      bodySmall: TextStyle(
        color: secondaryTextColor,
      ),
    ),
    inputDecorationTheme:
    InputDecorationTheme(
      filled: true,
      fillColor: cardColor,
      labelStyle:
      const TextStyle(
        color: secondaryTextColor,
      ),
      hintStyle:
      const TextStyle(
        color: secondaryTextColor,
      ),
      prefixIconColor:
      smartQBrandBlue,
      suffixIconColor:
      secondaryTextColor,
      enabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        borderSide:
        const BorderSide(
          color: borderColor,
        ),
      ),
      disabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        borderSide:
        const BorderSide(
          color: borderColor,
        ),
      ),
      focusedBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        borderSide:
        const BorderSide(
          color: smartQBrandBlue,
          width: 1.3,
        ),
      ),
      errorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        borderSide:
        const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        borderSide:
        const BorderSide(
          color: Colors.red,
          width: 1.3,
        ),
      ),
    ),
    elevatedButtonTheme:
    ElevatedButtonThemeData(
      style:
      ElevatedButton.styleFrom(
        backgroundColor:
        smartQBrandBlue,
        foregroundColor:
        Colors.white,
        disabledBackgroundColor:
        borderColor,
        disabledForegroundColor:
        secondaryTextColor,
        elevation: 0,
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
        ),
      ),
    ),
    outlinedButtonTheme:
    OutlinedButtonThemeData(
      style:
      OutlinedButton.styleFrom(
        foregroundColor:
        smartQBrandBlue,
        side: const BorderSide(
          color: smartQBrandBlue,
        ),
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
        ),
      ),
    ),
    textButtonTheme:
    TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor:
        smartQBrandBlue,
      ),
    ),
    switchTheme:
    SwitchThemeData(
      thumbColor:
      WidgetStateProperty
          .resolveWith(
            (
            Set<WidgetState> states,
            ) {
          if (states.contains(
            WidgetState.selected,
          )) {
            return smartQBrandBlue;
          }

          return Colors.white;
        },
      ),
      trackColor:
      WidgetStateProperty
          .resolveWith(
            (
            Set<WidgetState> states,
            ) {
          if (states.contains(
            WidgetState.selected,
          )) {
            return smartQBrandBlue
                .withOpacity(
              0.45,
            );
          }

          return borderColor;
        },
      ),
    ),
    bottomNavigationBarTheme:
    const BottomNavigationBarThemeData(
      backgroundColor: cardColor,
      selectedItemColor:
      smartQBrandBlue,
      unselectedItemColor:
      secondaryTextColor,
      type:
      BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    snackBarTheme:
    const SnackBarThemeData(
      behavior:
      SnackBarBehavior.floating,
    ),
    dividerTheme:
    const DividerThemeData(
      color: borderColor,
      thickness: 0.7,
    ),
  );
}

ThemeData _buildDarkTheme() {
  const Color backgroundColor =
  Color(0xFF0F172A);

  const Color cardColor =
  Color(0xFF1E293B);

  const Color elevatedCardColor =
  Color(0xFF243247);

  const Color borderColor =
  Color(0xFF334155);

  const Color primaryTextColor =
  Color(0xFFF8FAFC);

  const Color secondaryTextColor =
  Color(0xFF94A3B8);

  final ColorScheme colorScheme =
  ColorScheme.fromSeed(
    seedColor: smartQBrandBlue,
    brightness: Brightness.dark,
    primary: smartQBrandBlue,
    onPrimary: Colors.white,
    surface: cardColor,
    onSurface: primaryTextColor,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor:
    backgroundColor,
    cardColor: cardColor,
    dividerColor: borderColor,
    canvasColor: cardColor,
    dialogBackgroundColor: cardColor,
    splashColor:
    Colors.white.withOpacity(
      0.06,
    ),
    highlightColor:
    Colors.white.withOpacity(
      0.03,
    ),
    appBarTheme:
    const AppBarTheme(
      backgroundColor:
      backgroundColor,
      surfaceTintColor:
      backgroundColor,
      foregroundColor:
      primaryTextColor,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(
        color: primaryTextColor,
      ),
      titleTextStyle: TextStyle(
        color: primaryTextColor,
        fontSize: 21,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme:
    const TextTheme(
      headlineSmall: TextStyle(
        color: primaryTextColor,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        color: primaryTextColor,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        color: primaryTextColor,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: primaryTextColor,
      ),
      bodyMedium: TextStyle(
        color: primaryTextColor,
      ),
      bodySmall: TextStyle(
        color: secondaryTextColor,
      ),
    ),
    iconTheme:
    const IconThemeData(
      color: primaryTextColor,
    ),
    listTileTheme:
    const ListTileThemeData(
      iconColor: primaryTextColor,
      textColor: primaryTextColor,
    ),
    inputDecorationTheme:
    InputDecorationTheme(
      filled: true,
      fillColor: cardColor,
      labelStyle:
      const TextStyle(
        color: secondaryTextColor,
      ),
      hintStyle:
      const TextStyle(
        color: secondaryTextColor,
      ),
      prefixIconColor:
      smartQBrandBlue,
      suffixIconColor:
      secondaryTextColor,
      enabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        borderSide:
        const BorderSide(
          color: borderColor,
        ),
      ),
      disabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        borderSide:
        const BorderSide(
          color: borderColor,
        ),
      ),
      focusedBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        borderSide:
        const BorderSide(
          color: smartQBrandBlue,
          width: 1.3,
        ),
      ),
      errorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        borderSide:
        const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        borderSide:
        const BorderSide(
          color: Colors.redAccent,
          width: 1.3,
        ),
      ),
    ),
    elevatedButtonTheme:
    ElevatedButtonThemeData(
      style:
      ElevatedButton.styleFrom(
        backgroundColor:
        smartQBrandBlue,
        foregroundColor:
        Colors.white,
        disabledBackgroundColor:
        borderColor,
        disabledForegroundColor:
        secondaryTextColor,
        elevation: 0,
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
        ),
      ),
    ),
    outlinedButtonTheme:
    OutlinedButtonThemeData(
      style:
      OutlinedButton.styleFrom(
        foregroundColor:
        smartQBrandBlue,
        side: const BorderSide(
          color: smartQBrandBlue,
        ),
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
        ),
      ),
    ),
    textButtonTheme:
    TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor:
        smartQBrandBlue,
      ),
    ),
    switchTheme:
    SwitchThemeData(
      thumbColor:
      WidgetStateProperty
          .resolveWith(
            (
            Set<WidgetState> states,
            ) {
          if (states.contains(
            WidgetState.selected,
          )) {
            return smartQBrandBlue;
          }

          return const Color(
            0xFFCBD5E1,
          );
        },
      ),
      trackColor:
      WidgetStateProperty
          .resolveWith(
            (
            Set<WidgetState> states,
            ) {
          if (states.contains(
            WidgetState.selected,
          )) {
            return smartQBrandBlue
                .withOpacity(
              0.55,
            );
          }

          return borderColor;
        },
      ),
    ),
    bottomNavigationBarTheme:
    const BottomNavigationBarThemeData(
      backgroundColor:
      elevatedCardColor,
      selectedItemColor:
      smartQBrandBlue,
      unselectedItemColor:
      secondaryTextColor,
      type:
      BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    snackBarTheme:
    const SnackBarThemeData(
      backgroundColor:
      elevatedCardColor,
      contentTextStyle: TextStyle(
        color: primaryTextColor,
      ),
      behavior:
      SnackBarBehavior.floating,
    ),
    dividerTheme:
    const DividerThemeData(
      color: borderColor,
      thickness: 0.7,
    ),
  );
}