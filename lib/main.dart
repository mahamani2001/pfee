import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:mypsy_app/app.dart';
import 'package:mypsy_app/firebase_options.dart';
import 'package:mypsy_app/env/dev.dart';
import 'package:mypsy_app/helpers/app_config.dart';
import 'package:mypsy_app/shared/ui/device_types.dart';
import 'package:mypsy_app/resources/services/fcm_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔕 [Background] Message reçu : ${message.notification?.title}');
}

Future<void> main({String? env}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔐 Optionnel : nettoyage sécurisé
  final storage = FlutterSecureStorage();
  await storage.deleteAll();

  // 🔌 Initialisation Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔔 Gestion des notifications en background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 📁 Initialisation Hive pour le stockage local
  Directory? directory;
  if (Device.get().isIos! && !kIsWeb) {
    directory = await getApplicationDocumentsDirectory();
  } else {
    directory = await getExternalStorageDirectory();
  }
  Hive.init(directory!.path);

  // 🌐 Configuration app
  AppConfig.fromJson(config);
  env = 'dev';
  print('🌍 Base URL : ${AppConfig.instance()!.baseUrl}');

  // 📲 Gestion de redirection quand l’app est en background ou terminée
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("🎯 Notification cliquée avec payload : ${message.data['action']}");
    final context = navigatorKey.currentState?.overlay?.context;
    if (context != null && message.data['action'] != null) {
      FCMService().handleFCMRedirect(context, message.data);
    }
  });

  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    final context = navigatorKey.currentState?.overlay?.context;
    if (context != null && initialMessage.data['action'] != null) {
      FCMService().handleFCMRedirect(context, initialMessage.data);
    }
  }

  // 📲 Lancement de l’application avec gestion des erreurs
  SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  ).then((_) {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      runApp(
        MyApp(
          showError: true,
          errorDetails: details,
          navigatorKey: navigatorKey,
        ),
      );
    };

    runApp(MyApp(navigatorKey: navigatorKey));
  });
}
