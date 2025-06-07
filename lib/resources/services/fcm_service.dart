import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:mypsy_app/helpers/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FCMService {
  String baseUrl = '${AppConfig.instance()!.baseUrl!}auth';

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initFCM(BuildContext context) async {
    print("🚀 Appel de initFCM");

    // 🔐 Demande les permissions
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // ✅ Afficher les notifications en foreground
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
    );

    // 🧠 Initialisation de notifications locales
    await _initializeLocalNotifications();

    // 🔔 Gérer les messages reçus pendant l’utilisation
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _localPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'Notifications importantes',
              importance: Importance.max,
              priority: Priority.high,
              playSound: false,
            ),
          ),
        );
      }
    });

    // 🎯 Récupérer le token
    final token = await _messaging.getToken();
    print("📱 FCM Token : $token");

    // 📡 Envoyer le token au backend
    if (token != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final jwt = prefs.getString('jwt');
        final response = await http.put(
          Uri.parse('$baseUrl/fcm-token'),
          headers: {
            'Authorization': 'Bearer $jwt',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'token': token}),
        );

        if (response.statusCode == 200) {
          print("✅ Token FCM envoyé au backend !");
        } else {
          print("❌ Erreur envoi token : ${response.body}");
        }
      } catch (e) {
        print("🚨 Exception FCM : $e");
      }
    } else {
      print("⚠️ Aucun token FCM généré !");
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notifications importantes',
      description: 'Canal pour les notifications critiques',
      importance: Importance.high,
      playSound: false, // ✅ PAS de son
      // ✅ supprime la ligne sound:
    );

    await _localPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _localPlugin.initialize(initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
      debugPrint('Notification cliquée : ${response.payload}');
    });
  }

  static Future<void> _showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_importance_channel', // 🛎️ utiliser le même que dans le channel avec son
      'Notifications importantes',
      importance: Importance.high,
      enableVibration: true,
      priority: Priority.high,
      playSound: true, // ✅ sans son
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _localPlugin.show(
      0,
      title,
      body,
      details,
    );
  }
}
