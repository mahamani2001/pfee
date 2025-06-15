import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:mypsy_app/helpers/app_config.dart';
import 'package:mypsy_app/screens/consultation/chatconsultation.dart';
import 'package:mypsy_app/screens/consultation/video_call_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();

  Future<Map<String, dynamic>?> fetchConsultationAndPeer(
      int appointmentId) async {
    final url =
        '${AppConfig.instance()!.baseUrl!}consultation/appointment/$appointmentId';
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ fetchConsultationAndPeer réponse brute : $data");

        return {
          'consultation': data['consultation'],
          'peer': data['peer'],
        };
      } else {
        print(
            "❌ Erreur chargement consultation : ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Exception réseau : $e");
      return null;
    }
  }

  Future<void> initFCM(BuildContext context) async {
    print("🚀 Appel de initFCM");

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _initializeLocalNotifications();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final data = message.data;
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
              playSound: true,
            ),
          ),
          payload: data['action'],
        );
      }
    });

    final token = await _messaging.getToken();
    print("📱 FCM Token : $token");

    if (token != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final jwt = prefs.getString('jwt');
        final response = await http.put(
          Uri.parse('${AppConfig.instance()!.baseUrl!}auth/fcm-token'),
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
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notifications importantes',
      description: 'Canal pour les notifications critiques',
      importance: Importance.high,
    );

    await _localPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const InitializationSettings initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _localPlugin.initialize(initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
      final payload = response.payload;
      if (payload != null) {
        print('Notification cliquée avec payload : $payload');
        _handleNotificationAction(payload);
      }
    });
  }

  static Future<void> _showLocalNotification(
      String title, String body, String action) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_importance_channel',
      'Notifications importantes',
      importance: Importance.high,
      enableVibration: true,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _localPlugin.show(
      0,
      title,
      body,
      details,
      payload: action,
    );
  }

  static Future<void> _handleNotificationAction(String action) async {
    final uri = Uri.parse(action);
    final consultationId =
        int.tryParse(uri.queryParameters['consultationId'] ?? '');
    final mode = uri.queryParameters['mode'];

    if (consultationId == null || mode == null) {
      print("❌ Action invalide : $action");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt');

    try {
      final response = await http.get(
        Uri.parse(
            '${AppConfig.instance()!.baseUrl!}consultation/$consultationId'),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final consultation = data['consultation'];
        final peer = data['peer'];

        if (consultation == null || peer == null) {
          print('❌ Données manquantes pour la redirection');
          return;
        }

        final appointmentId = consultation['appointment_id'];
        final peerName = '${peer['first_name']} ${peer['last_name']}';
        final peerId = peer['id'].toString();

        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => mode == 'chat'
                ? ChatScreen(
                    appointmentId: appointmentId,
                    peerName: peerName,
                    peerId: peerId,
                    consultationId: consultationId,
                    roomId: 'room-$consultationId',
                  )
                : VideoCallScreen(
                    roomId: 'room-$consultationId',
                    peerName: peerName,
                    appointmentId: appointmentId,
                    consultationId: consultationId,
                    isCaller: false, // on suppose que c'est le récepteur ici
                  ),
          ),
        );
      } else {
        print("❌ Erreur backend : ${response.body}");
      }
    } catch (e) {
      print("❌ Exception API : $e");
    }
  }

  void handleFCMRedirect(
      BuildContext context, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse(data['action'] ?? '');
      final consultationId =
          int.tryParse(uri.queryParameters['consultationId'] ?? '');
      final mode = uri.queryParameters['mode'];

      if (consultationId == null || mode == null) {
        print('⚠️ Paramètres manquants pour la redirection');
        return;
      }

      final jwt =
          (await SharedPreferences.getInstance()).getString('jwt') ?? '';
      final response = await http.get(
        Uri.parse(
            '${AppConfig.instance()!.baseUrl!}consultation/$consultationId'),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final consultation = decoded['consultation'];
        final peer = decoded['peer'];

        if (consultation == null || peer == null) {
          print('❌ Données de consultation manquantes');
          return;
        }

        final appointmentId = consultation['appointment_id'];
        final peerId = peer['id'].toString();
        final peerName = '${peer['first_name']} ${peer['last_name']}';

        final Widget screen = (mode == 'chat')
            ? ChatScreen(
                peerId: peerId,
                peerName: peerName,
                appointmentId: appointmentId,
                consultationId: consultationId,
                roomId: 'room-$consultationId',
              )
            : VideoCallScreen(
                roomId: 'room-$consultationId',
                peerName: peerName,
                appointmentId: appointmentId,
                consultationId: consultationId,
                isCaller: false,
              );

        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
      } else {
        print('❌ Erreur API consultation: ${response.body}');
      }
    } catch (e) {
      print('❌ Exception dans handleFCMRedirect : $e');
    }
  }
}
