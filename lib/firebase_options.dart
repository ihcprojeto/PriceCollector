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
    apiKey: 'AIzaSyD8WHSee0xL1tBijH4FoKzsbNNVRRt13rU',
    appId: '1:826141634966:web:bebe4eb7dbd55c655dadb7',
    messagingSenderId: '826141634966',
    projectId: 'scanner-app-ihc',
    authDomain: 'scanner-app-ihc.firebaseapp.com',
    storageBucket: 'scanner-app-ihc.firebasestorage.app',
    measurementId: 'G-HXBP4XCRC1',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAc36vZNcQ4WYYlNUiDPT62Ioi7dn-CdXc',
    appId: '1:826141634966:android:cb83dac0c05e93635dadb7',
    messagingSenderId: '826141634966',
    projectId: 'scanner-app-ihc',
    storageBucket: 'scanner-app-ihc.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAcOuE_5jIDVJpo7QceuGhGN-ysLZemAXk',
    appId: '1:826141634966:ios:25f2419d5f0c1c075dadb7',
    messagingSenderId: '826141634966',
    projectId: 'scanner-app-ihc',
    storageBucket: 'scanner-app-ihc.firebasestorage.app',
    iosBundleId: 'com.example.priceCollector',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAcOuE_5jIDVJpo7QceuGhGN-ysLZemAXk',
    appId: '1:826141634966:ios:25f2419d5f0c1c075dadb7',
    messagingSenderId: '826141634966',
    projectId: 'scanner-app-ihc',
    storageBucket: 'scanner-app-ihc.firebasestorage.app',
    iosBundleId: 'com.example.priceCollector',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD8WHSee0xL1tBijH4FoKzsbNNVRRt13rU',
    appId: '1:826141634966:web:517faeaa23828e8c5dadb7',
    messagingSenderId: '826141634966',
    projectId: 'scanner-app-ihc',
    authDomain: 'scanner-app-ihc.firebaseapp.com',
    storageBucket: 'scanner-app-ihc.firebasestorage.app',
    measurementId: 'G-F8CTMF59CJ',
  );
}
