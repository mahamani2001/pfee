import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mypsy_app/helpers/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  String baseUrl = '${AppConfig.instance()!.baseUrl!}auth';

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      body: jsonEncode({'email': email, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    );
    final data = jsonDecode(response.body);
    return {'status': response.statusCode, 'data': data};
  }

  Future<Map<String, dynamic>> verifyOtp(String tempToken, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify-otp'),
      body: jsonEncode({'tempToken': tempToken, 'otp': otp}),
      headers: {'Content-Type': 'application/json'},
    );
    final data = jsonDecode(response.body);
    return {'status': response.statusCode, 'data': data};
  }

  Future<void> saveTokens(String token, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt', token);
    await prefs.setString('refresh_token', refreshToken);
  }

  Future<String> fetchPublicKey(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');

    final response = await http.get(
      Uri.parse('$baseUrl/$userId/x25519-public-key'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['x25519_public_key'].replaceAll('x25519:', '');
    } else {
      print('❌ Erreur HTTP ${response.statusCode} : ${response.body}');
      throw Exception('Erreur récupération de la clé publique');
    }
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null) return null;

    final parts = token.split('.');
    if (parts.length != 3) return null;

    final payload = base64.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(payload));
    final Map<String, dynamic> payloadMap = jsonDecode(decoded);

    return payloadMap['userId']; // ou 'id' selon ce que tu mets dans le JWT
  }

  Future<Map<String, dynamic>> register(
      String fullName, String email, String password) async {
    final url = Uri.parse('$baseUrl/register');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "full_name": fullName,
        "email": email,
        "password": password,
      }),
    );

    final data = jsonDecode(response.body);
    return {'status': response.statusCode, 'data': data};
  }
}
