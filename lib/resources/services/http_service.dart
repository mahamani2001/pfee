import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';

class HttpService {
  static final HttpService _instance = HttpService._internal();
  factory HttpService() => _instance;
  HttpService._internal();

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt');
  }

  Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  /// 🔁 Essaie de rafraîchir le token si nécessaire
  Future<bool> _tryRefreshToken() async {
    final newToken = await AuthService.refreshToken();
    return newToken != null;
  }

  /// 🧠 Requête générique avec gestion auto des tokens
  Future<http.Response> request({
    required String url,
    required String method, // 'GET', 'POST', 'PUT', 'DELETE'
    Map<String, String>? headers,
    Object? body,
  }) async {
    String? token = await _getAccessToken();

    Future<http.Response> sendRequest(String token) {
      final allHeaders = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        ...?headers,
      };

      final uri = Uri.parse(url);
      switch (method.toUpperCase()) {
        case 'GET':
          return http.get(uri, headers: allHeaders);
        case 'POST':
          return http.post(uri, headers: allHeaders, body: jsonEncode(body));
        case 'PUT':
          return http.put(uri, headers: allHeaders, body: jsonEncode(body));
        case 'DELETE':
          return http.delete(uri, headers: allHeaders);
        default:
          throw Exception("Méthode HTTP non supportée");
      }
    }

    var response = await sendRequest(token!);

    if (response.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        final newToken = await _getAccessToken();
        response = await sendRequest(newToken!);
      } else {
        print(
            "⚠️ Échec du refresh token. Session expirée mais pas déconnecté.");
        return http.Response(jsonEncode({'error': 'Session expirée'}),
            401); // 👈 tu peux détecter ce cas dans l’UI
      }
    }

    return response;
  }
}
