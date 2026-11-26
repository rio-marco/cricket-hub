import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static const String _androidApiKey =
      String.fromEnvironment('FIREBASE_ANDROID_API_KEY');
  static const String _androidAppId =
      String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  static const String _androidMessagingSenderId =
      String.fromEnvironment('FIREBASE_ANDROID_MESSAGING_SENDER_ID');
  static const String _androidProjectId =
      String.fromEnvironment('FIREBASE_ANDROID_PROJECT_ID');

  static const String _iosApiKey =
      String.fromEnvironment('FIREBASE_IOS_API_KEY');
  static const String _iosAppId =
      String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const String _iosMessagingSenderId =
      String.fromEnvironment('FIREBASE_IOS_MESSAGING_SENDER_ID');
  static const String _iosProjectId =
      String.fromEnvironment('FIREBASE_IOS_PROJECT_ID');
  static const String _iosBundleId =
      String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');

  static const String _webApiKey =
      String.fromEnvironment('FIREBASE_WEB_API_KEY');
  static const String _webAppId =
      String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const String _webMessagingSenderId =
      String.fromEnvironment('FIREBASE_WEB_MESSAGING_SENDER_ID');
  static const String _webProjectId =
      String.fromEnvironment('FIREBASE_WEB_PROJECT_ID');
  static const String _webAuthDomain =
      String.fromEnvironment('FIREBASE_WEB_AUTH_DOMAIN');
  static const String _webVapidKey =
      String.fromEnvironment('FIREBASE_WEB_VAPID_KEY');

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: _androidApiKey,
        appId: _androidAppId,
        messagingSenderId: _androidMessagingSenderId,
        projectId: _androidProjectId,
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: _iosApiKey,
        appId: _iosAppId,
        messagingSenderId: _iosMessagingSenderId,
        projectId: _iosProjectId,
        iosBundleId: _iosBundleId,
      );

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: _webApiKey,
        appId: _webAppId,
        messagingSenderId: _webMessagingSenderId,
        projectId: _webProjectId,
        authDomain: _webAuthDomain,
        storageBucket: _webProjectId.isNotEmpty
            ? '$_webProjectId.appspot.com'
            : null,
      );

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static bool get isConfigured {
    final options = currentPlatform;
    return         options.apiKey.isNotEmpty &&
        options.appId.isNotEmpty &&
        options.messagingSenderId.isNotEmpty &&
        options.projectId.isNotEmpty &&
        (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
            ? options.iosBundleId != null && options.iosBundleId!.isNotEmpty
            : true) &&
        (!kIsWeb ||
            (options.authDomain != null && options.authDomain!.isNotEmpty));
  }

  static String? get webVapidKey =>
      _webVapidKey.isEmpty ? null : _webVapidKey;
}
