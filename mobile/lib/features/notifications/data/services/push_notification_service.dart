import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/firebase_initializer.dart';
import '../../../../core/config/firebase_options.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/repositories/notifications_repository.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await initializeFirebase();
}

class PushNotificationMessage {
  final String? notificationId;
  final String title;
  final String body;
  final Map<String, dynamic> data;

  const PushNotificationMessage({
    this.notificationId,
    required this.title,
    required this.body,
    required this.data,
  });

  factory PushNotificationMessage.fromRemote(RemoteMessage message) {
    final data = message.data.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    return PushNotificationMessage(
      notificationId: data['notificationId']?.toString(),
      title: message.notification?.title ?? data['title']?.toString() ?? '',
      body: message.notification?.body ?? data['body']?.toString() ?? '',
      data: data,
    );
  }
}

abstract class PushNotificationPlatform {
  Future<bool> initialize();
  Future<bool> requestPermission();
  Future<String?> getToken();
  Future<void> setForegroundPresentationOptions();
  Stream<String> get onTokenRefresh;
  Stream<PushNotificationMessage> get onMessage;
  Stream<PushNotificationMessage> get onMessageOpenedApp;
  Future<PushNotificationMessage?> getInitialMessage();
}

class FirebasePushNotificationPlatform implements PushNotificationPlatform {
  final FirebaseMessaging _messaging;

  FirebasePushNotificationPlatform({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  @override
  Future<bool> initialize() async {
    return initializeFirebase();
  }

  @override
  Future<bool> requestPermission() async {
    var settings = await _messaging.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    }
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> getToken() async {
    if (!DefaultFirebaseOptions.isConfigured) return null;
    if (kIsWeb && DefaultFirebaseOptions.webVapidKey != null) {
      return _messaging.getToken(vapidKey: DefaultFirebaseOptions.webVapidKey);
    }
    return _messaging.getToken();
  }

  @override
  Future<void> setForegroundPresentationOptions() async {
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<PushNotificationMessage> get onMessage =>
      FirebaseMessaging.onMessage.map(PushNotificationMessage.fromRemote);

  @override
  Stream<PushNotificationMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp
          .map(PushNotificationMessage.fromRemote);

  @override
  Future<PushNotificationMessage?> getInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message == null) return null;
    return PushNotificationMessage.fromRemote(message);
  }
}

class PushNotificationService {
  final PushNotificationPlatform _platform;
  final NotificationsRepository _repository;
  final SecureStorage _storage;
  final StreamController<PushNotificationMessage> _messages;
  final StreamController<PushNotificationMessage> _taps;

  bool _initialized = false;
  bool _listening = false;

  PushNotificationService({
    required this._platform,
    required this._repository,
    required this._storage,
  })  : _messages = StreamController<PushNotificationMessage>.broadcast(),
        _taps = StreamController<PushNotificationMessage>.broadcast();

  Stream<PushNotificationMessage> get messages => _messages.stream;
  Stream<PushNotificationMessage> get taps => _taps.stream;

  Future<bool> initialize() async {
    if (_initialized) {
      await registerCurrentToken();
      return true;
    }
    final firebaseReady = await _platform.initialize();
    if (!firebaseReady) return false;
    final permissionGranted = await _platform.requestPermission();
    if (!permissionGranted) return false;
    await _platform.setForegroundPresentationOptions();
    _initialized = true;
    _startListening();
    await registerCurrentToken();
    return true;
  }

  Future<void> registerCurrentToken() async {
    final token = await _platform.getToken();
    if (token == null || token.isEmpty) return;
    await _storage.savePushToken(token);

    final accessToken = await _storage.getToken();
    if (accessToken == null || accessToken.isEmpty) return;

    await _repository.registerDeviceToken(
      token: token,
      platform: _platformName(),
      deviceId: null,
      appVersion: AppConstants.appVersion,
    );
  }

  Future<void> unregisterCurrentToken() async {
    final token = await _storage.getPushToken();
    if (token == null || token.isEmpty) return;

    final accessToken = await _storage.getToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      await _repository.removeDeviceToken(token);
    }
    await _storage.deletePushToken();
  }

  Future<void> dispose() async {
    await _messages.close();
    await _taps.close();
  }

  void _startListening() {
    if (_listening) return;
    _listening = true;

    _platform.onTokenRefresh.listen((token) async {
      await _storage.savePushToken(token);
      await registerCurrentToken();
    });
    _platform.onMessage.listen(_handleMessage);
    _platform.onMessageOpenedApp.listen(_handleTap);
    _platform.getInitialMessage().then((message) {
      if (message != null) _handleTap(message);
    });
  }

  void _handleMessage(PushNotificationMessage message) {
    if (!_messages.isClosed) _messages.add(message);
  }

  void _handleTap(PushNotificationMessage message) {
    if (!_taps.isClosed) _taps.add(message);
  }

  String _platformName() {
    if (kIsWeb) return 'WEB';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'IOS';
      case TargetPlatform.android:
        return 'ANDROID';
      default:
        return 'ANDROID';
    }
  }
}
