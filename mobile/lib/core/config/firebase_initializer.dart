import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

Future<bool> initializeFirebase() async {
  if (!DefaultFirebaseOptions.isConfigured) {
    debugPrint('[Firebase] Push notifications are not configured.');
    return false;
  }

  if (Firebase.apps.isNotEmpty) return true;

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    return true;
  } catch (error) {
    debugPrint('[Firebase] Initialization failed: $error');
    return false;
  }
}
