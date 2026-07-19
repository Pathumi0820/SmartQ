import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';

/// Must remain a top-level function.
///
/// Register this handler in main.dart before runApp().
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
    ) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint(
    'Background notification received: ${message.messageId}',
  );

  debugPrint(
    'Background notification data: ${message.data}',
  );
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
  NotificationService._();

  final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin
  _localNotifications =
  FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel =
  AndroidNotificationChannel(
    'smartq_high_importance',
    'SmartQ Notifications',
    description:
    'Token status and hospital queue notifications',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  StreamSubscription<RemoteMessage>?
  _foregroundSubscription;

  StreamSubscription<RemoteMessage>?
  _openedAppSubscription;

  StreamSubscription<String>? _tokenSubscription;

  bool _initialized = false;

  String? _currentFcmToken;

  void Function(Map<String, dynamic> data)?
  _onNotificationOpened;

  String? get currentFcmToken => _currentFcmToken;

  Future<void> initialize({
    Future<void> Function(String token)? onTokenAvailable,
    void Function(Map<String, dynamic> data)?
    onNotificationOpened,
  }) async {
    _onNotificationOpened = onNotificationOpened;

    if (_initialized) {
      final String? token = _currentFcmToken;

      if (token != null &&
          token.isNotEmpty &&
          onTokenAvailable != null) {
        await onTokenAvailable(token);
      }

      return;
    }

    _initialized = true;

    try {
      await _initializeLocalNotifications();

      await _requestPermission();

      await _configureForegroundPresentation();

      await _loadFcmToken(
        onTokenAvailable,
      );

      _listenForTokenRefresh(
        onTokenAvailable,
      );

      // Foreground FCM is logged only.
      // Socket.IO displays the foreground notification,
      // preventing duplicate notifications.
      _listenForForegroundMessages();

      _listenForOpenedNotifications();

      await _handleInitialFcmNotification();

      await _handleInitialLocalNotification();
    } catch (error, stackTrace) {
      _initialized = false;

      debugPrint(
        'Notification service initialization failed: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings settings =
    InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (
          NotificationResponse response,
          ) {
        debugPrint(
          'Local notification opened: ${response.payload}',
        );

        _handleLocalNotificationPayload(
          response.payload,
        );
      },
    );

    final AndroidFlutterLocalNotificationsPlugin?
    androidPlugin =
    _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      _channel,
    );
  }

  Future<NotificationSettings> _requestPermission() async {
    final NotificationSettings settings =
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    final AndroidFlutterLocalNotificationsPlugin?
    androidPlugin =
    _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin
        ?.requestNotificationsPermission();

    debugPrint(
      'Notification permission: '
          '${settings.authorizationStatus}',
    );

    return settings;
  }

  Future<void> _configureForegroundPresentation() async {
    await _firebaseMessaging
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _loadFcmToken(
      Future<void> Function(String token)?
      onTokenAvailable,
      ) async {
    try {
      String? token =
      await _firebaseMessaging.getToken();

      if (token == null ||
          token.trim().isEmpty) {
        debugPrint(
          'FCM token unavailable; retrying...',
        );

        await Future<void>.delayed(
          const Duration(seconds: 2),
        );

        token =
        await _firebaseMessaging.getToken();
      }

      final String normalizedToken =
          token?.trim() ?? '';

      if (normalizedToken.isEmpty) {
        debugPrint(
          'FCM token was not returned',
        );

        return;
      }

      _currentFcmToken = normalizedToken;

      debugPrint(
        'FCM token received: $normalizedToken',
      );

      if (onTokenAvailable != null) {
        try {
          await onTokenAvailable(
            normalizedToken,
          );

          debugPrint(
            'FCM token upload callback completed',
          );
        } catch (error) {
          debugPrint(
            'FCM token upload failed: $error',
          );
        }
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to load FCM token: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );
    }
  }

  void _listenForTokenRefresh(
      Future<void> Function(String token)?
      onTokenAvailable,
      ) {
    _tokenSubscription?.cancel();

    _tokenSubscription =
        _firebaseMessaging.onTokenRefresh.listen(
              (String token) async {
            final String normalizedToken =
            token.trim();

            if (normalizedToken.isEmpty) {
              return;
            }

            _currentFcmToken =
                normalizedToken;

            debugPrint(
              'FCM token refreshed: $normalizedToken',
            );

            if (onTokenAvailable != null) {
              try {
                await onTokenAvailable(
                  normalizedToken,
                );

                debugPrint(
                  'Refreshed FCM token saved',
                );
              } catch (error) {
                debugPrint(
                  'Failed to save refreshed FCM token: $error',
                );
              }
            }
          },
          onError: (Object error) {
            debugPrint(
              'FCM token refresh error: $error',
            );
          },
        );
  }

  /// Do not display a local notification here.
  ///
  /// Socket.IO handles foreground notifications.
  /// Android/iOS displays FCM while the app is in the
  /// background or terminated.
  void _listenForForegroundMessages() {
    _foregroundSubscription?.cancel();

    _foregroundSubscription =
        FirebaseMessaging.onMessage.listen(
              (RemoteMessage message) {
            debugPrint(
              'Foreground FCM received: ${message.messageId}',
            );

            debugPrint(
              'Foreground FCM title: '
                  '${message.notification?.title}',
            );

            debugPrint(
              'Foreground FCM body: '
                  '${message.notification?.body}',
            );

            debugPrint(
              'Foreground FCM data: ${message.data}',
            );
          },
          onError: (Object error) {
            debugPrint(
              'Foreground FCM listener error: $error',
            );
          },
        );
  }

  void _listenForOpenedNotifications() {
    _openedAppSubscription?.cancel();

    _openedAppSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen(
              (RemoteMessage message) {
            final Map<String, dynamic> data =
            Map<String, dynamic>.from(
              message.data,
            );

            debugPrint(
              'FCM notification opened from background: $data',
            );

            _onNotificationOpened?.call(
              data,
            );
          },
          onError: (Object error) {
            debugPrint(
              'Notification-open error: $error',
            );
          },
        );
  }

  Future<void> _handleInitialFcmNotification() async {
    try {
      final RemoteMessage? initialMessage =
      await _firebaseMessaging
          .getInitialMessage();

      if (initialMessage == null) {
        return;
      }

      final Map<String, dynamic> data =
      Map<String, dynamic>.from(
        initialMessage.data,
      );

      debugPrint(
        'FCM notification opened from terminated state: $data',
      );

      _onNotificationOpened?.call(
        data,
      );
    } catch (error) {
      debugPrint(
        'Initial FCM notification error: $error',
      );
    }
  }

  Future<void> _handleInitialLocalNotification() async {
    try {
      final NotificationAppLaunchDetails?
      launchDetails =
      await _localNotifications
          .getNotificationAppLaunchDetails();

      if (launchDetails?.didNotificationLaunchApp !=
          true) {
        return;
      }

      final String? payload =
          launchDetails
              ?.notificationResponse
              ?.payload;

      debugPrint(
        'Local notification launched app: $payload',
      );

      _handleLocalNotificationPayload(
        payload,
      );
    } catch (error) {
      debugPrint(
        'Initial local notification error: $error',
      );
    }
  }

  void _handleLocalNotificationPayload(
      String? payload,
      ) {
    if (payload == null ||
        payload.trim().isEmpty) {
      return;
    }

    try {
      final dynamic decoded =
      jsonDecode(payload);

      if (decoded is Map) {
        final Map<String, dynamic> data =
        Map<String, dynamic>.from(
          decoded,
        );

        _onNotificationOpened?.call(
          data,
        );
      }
    } catch (error) {
      debugPrint(
        'Invalid local notification payload: $error',
      );
    }
  }

  /// Displays one local notification while the app is open.
  ///
  /// Call this from the Socket.IO `notification` event.
  Future<void> showTokenUpdateNotification({
    required String tokenCode,
    required String status,
    String tokenId = '',
    String hospitalId = '',
    String departmentId = '',
  }) async {
    String title = 'Token updated';

    String body =
        'Token $tokenCode status changed to $status.';

    switch (status.toLowerCase()) {
      case 'called':
        title =
        'Your token has been called';
        body =
        'Token $tokenCode has been called. Please proceed.';
        break;

      case 'serving':
        title =
        'Your service has started';
        body =
        'Token $tokenCode is now being served.';
        break;

      case 'completed':
        title = 'Token completed';
        body =
        'Token $tokenCode has been completed.';
        break;

      case 'cancelled':
      case 'canceled':
        title = 'Token cancelled';
        body =
        'Token $tokenCode has been cancelled.';
        break;
    }

    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'smartq_high_importance',
      'SmartQ Notifications',
      channelDescription:
      'Token status and hospital queue notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails =
    DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details =
    NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final Map<String, dynamic> payload = {
      'type': 'token_status',
      'tokenId': tokenId,
      'tokenCode': tokenCode,
      'status': status,
      'hospitalId': hospitalId,
      'departmentId': departmentId,
    };

    final int notificationId =
    DateTime.now()
        .millisecondsSinceEpoch
        .remainder(100000);

    await _localNotifications.show(
      notificationId,
      title,
      body,
      details,
      payload: jsonEncode(payload),
    );

    debugPrint(
      'Foreground local notification displayed',
    );
  }

  Future<String?> refreshToken() async {
    try {
      await _firebaseMessaging.deleteToken();

      final String? token =
      await _firebaseMessaging.getToken();

      _currentFcmToken =
          token?.trim();

      return _currentFcmToken;
    } catch (error) {
      debugPrint(
        'FCM token refresh failed: $error',
      );

      return null;
    }
  }

  Future<void> unsubscribeFromAllListeners() async {
    await _foregroundSubscription?.cancel();
    await _openedAppSubscription?.cancel();
    await _tokenSubscription?.cancel();

    _foregroundSubscription = null;
    _openedAppSubscription = null;
    _tokenSubscription = null;

    _onNotificationOpened = null;

    _initialized = false;
  }
}