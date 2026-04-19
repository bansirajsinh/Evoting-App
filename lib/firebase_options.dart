import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBqLYgLNoa14Jhb1JcsIvTptEbGOrvQBJM',
    appId: '1:6447421726:web:3b4cf6af29f8fb150dd10f',
    messagingSenderId: '6447421726',
    projectId: 'evote2-68769',
    authDomain: 'evote2-68769.firebaseapp.com',
    storageBucket: 'evote2-68769.firebasestorage.app',
    measurementId: 'G-Z21PJXPFQD',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAMLZF2UHLU_fJ04VX5JiZ-60FegBbRTKM',
    appId: '1:6447421726:android:bcc9884198c4a8160dd10f',
    messagingSenderId: '6447421726',
    projectId: 'evote2-68769',
    storageBucket: 'evote2-68769.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCrkBPc6kFXqevfEkQ5jdmacKNlNPCTI0A',
    appId: '1:6447421726:ios:374d9c0ea70a1a1c0dd10f',
    messagingSenderId: '6447421726',
    projectId: 'evote2-68769',
    storageBucket: 'evote2-68769.firebasestorage.app',
    iosBundleId: 'com.example.evoteCurrent',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCrkBPc6kFXqevfEkQ5jdmacKNlNPCTI0A',
    appId: '1:6447421726:ios:374d9c0ea70a1a1c0dd10f',
    messagingSenderId: '6447421726',
    projectId: 'evote2-68769',
    storageBucket: 'evote2-68769.firebasestorage.app',
    iosBundleId: 'com.example.evoteCurrent',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBqLYgLNoa14Jhb1JcsIvTptEbGOrvQBJM',
    appId: '1:6447421726:web:62cfd5f29c11ddd30dd10f',
    messagingSenderId: '6447421726',
    projectId: 'evote2-68769',
    authDomain: 'evote2-68769.firebaseapp.com',
    storageBucket: 'evote2-68769.firebasestorage.app',
    measurementId: 'G-1JX6M8SGJ0',
  );

}