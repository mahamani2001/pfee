import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mypsy_app/app.dart';
import 'package:mypsy_app/firebase_options.dart';
import 'package:mypsy_app/helpers/app_config.dart';
import 'package:mypsy_app/shared/ui/device_types.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mypsy_app/env/dev.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔕 [Background] Message: ${message.notification?.title}');
}

Future<void> main({String? env}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = FlutterSecureStorage();
  await storage.deleteAll();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  /*  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  final plainText = 'Hello, this is a secret message!';

  final key =
      encrypt.Key.fromUtf8('myr32lengthsupersecretnooneknows1'); // 32 chars
  final iv = IV.fromUtf8('8bytesiv12345678'); // 16 chars

  final encrypter = Encrypter(AES(key));

  // Encrypt
  final encrypted = encrypter.encrypt(plainText, iv: iv);
  print('Encrypted: ${encrypted.base64}');

  // Decrypt
  final decrypted = encrypter.decrypt(encrypted, iv: iv);
  print('Decrypted: $decrypted');
 */
  Directory? directory;
  if (Device.get().isIos! && !kIsWeb) {
    directory = await getApplicationDocumentsDirectory();
  } else {
    directory = await getExternalStorageDirectory();
  }
  Hive.init(directory!.path);
  if (env == null) {
    AppConfig.fromJson(config);
    env = 'dev';
  }

  SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  ).then((_) {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      runApp(
        MyApp(
          showError: true,
          errorDetails: details,
        ),
      );
    };
  });

  SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  ).then((_) {
    runApp(MyApp());
  });
}
