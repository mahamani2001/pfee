// 📁 resources/services/notification_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mypsy_app/helpers/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  String baseUrl = '${AppConfig.instance()!.baseUrl!}notifications';

  Future<List<dynamic>> getMyNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt');

    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: {'Authorization': 'Bearer $jwt'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("Erreur getMyNotifications: ${response.body}");
      return [];
    }
  }

  Future<void> markAsRead(int notifId) async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt');

    await http.put(
      Uri.parse('$baseUrl/$notifId/read'),
      headers: {'Authorization': 'Bearer $jwt'},
    );
  }

  Future<bool> hasUnread() async {
    final all = await getMyNotifications();
    return all.any((n) => n['status'] == 'unread');
  }

  Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt');

    final response = await http.put(
      Uri.parse('${baseUrl}mark-all-read'),
      headers: {'Authorization': 'Bearer $jwt'},
    );

    if (response.statusCode != 200) {
      print("❌ Erreur markAllAsRead: ${response.body}");
      throw Exception('Échec de la mise à jour des notifications');
    }
  }

  Future<int> getUnreadCount() async {
    final all = await getMyNotifications();
    return all.where((n) => n['status'] == 'unread').length;
  }
}
