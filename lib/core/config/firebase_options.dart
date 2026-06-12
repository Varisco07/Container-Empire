import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS:     return ios;
      default:                     return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyDEiDYLKKk9sDG_0S2Mvq8FyeXLBZM5cOU',
    appId:             '1:494983197999:web:8746bd951ca18602429dda',
    messagingSenderId: '494983197999',
    projectId:         'container-empire',
    authDomain:        'container-empire.firebaseapp.com',
    storageBucket:     'container-empire.firebasestorage.app',
    measurementId:     'G-Q57T4QM629',
  );

  // Per Android: scarica google-services.json da Firebase Console
  // Impostazioni progetto → La tua app → Aggiungi app Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'AIzaSyDEiDYLKKk9sDG_0S2Mvq8FyeXLBZM5cOU',
    appId:             '1:494983197999:web:8746bd951ca18602429dda',
    messagingSenderId: '494983197999',
    projectId:         'container-empire',
    storageBucket:     'container-empire.firebasestorage.app',
  );

  // Per iOS: scarica GoogleService-Info.plist da Firebase Console
  // Impostazioni progetto → La tua app → Aggiungi app iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'AIzaSyDEiDYLKKk9sDG_0S2Mvq8FyeXLBZM5cOU',
    appId:             '1:494983197999:web:8746bd951ca18602429dda',
    messagingSenderId: '494983197999',
    projectId:         'container-empire',
    storageBucket:     'container-empire.firebasestorage.app',
    iosBundleId:       'com.yourcompany.containerEmpire',
  );
}
