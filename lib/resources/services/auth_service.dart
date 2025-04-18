import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mypsy_app/resources/services/crypto_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cryptography/cryptography.dart';

class AuthService {
  final String baseUrl = 'http://10.0.2.2:3001/api/auth';
  final storage = FlutterSecureStorage();
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      body: jsonEncode({'email': email, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    );
    final data = jsonDecode(response.body);
    return {'status': response.statusCode, 'data': data};
  }

  Future<Map<String, dynamic>> verifyOTP(String otp, String tempToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'otp': otp,
        'tempToken': tempToken,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final token = data['token'];
      final refreshToken = data['refreshToken'];

      await CryptoService().sendPublicKeyToBackend(token);
      await storage.write(key: 'token', value: token);

      return {
        'status': 200,
        'token': token,
        'refreshToken': refreshToken,
        'user': data['user']
      };
    } else {
      print('❌ OTP Backend Error: ${response.body}');
      return {
        'status': response.statusCode,
        'error': jsonDecode(response.body)['message']
      };
    }
  }

  Future<void> saveTokens(String token, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt', token);
    await prefs.setString('refresh_token', refreshToken);
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

    return payloadMap['userId'];
  }

  Future<void> sendPublicKeyToBackend(
      int userId, String publicKeyBase64) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');

    final response = await http.put(
      Uri.parse('http://10.0.2.2:3001/api/auth/publicKey'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'publicKey': publicKeyBase64,
      }),
    );

    if (response.statusCode == 200) {
      print('✅ Clé publique envoyée au backend');
    } else {
      print('❌ Erreur envoi clé : ${response.body}');
    }
  }

  Future<String> fetchPeerPublicKey(String peerId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');

    final response = await http.get(
      Uri.parse('http://10.0.2.2:3001/api/auth/publicKey/$peerId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['publicKey'];
    } else {
      print('❌ Erreur HTTP ${response.statusCode} : ${response.body}');
      throw Exception('Erreur récupération de la clé publique');
    }
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null) return null;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = base64.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(payload));
      final Map<String, dynamic> payloadMap = jsonDecode(decoded);

      return payloadMap['role']; // ou 'userType' ou 'type' selon backend
    } catch (e) {
      print('❌ Erreur lors du décodage du rôle : $e');
      return null;
    }
  }

  static Future<String?> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    if (refreshToken == null) return null;

    final response = await http.post(
      Uri.parse('http://10.0.2.2:3001/api/auth/refresh-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await prefs.setString('jwt', data['token']);
      await prefs.setString('refresh_token', data['refreshToken']);
      return data['token'];
    } else {
      print('🔴 Refresh token expiré ou invalide');
      // ❌ On ne supprime rien, on laisse l'utilisateur dans l'app
      return null;
    }
  }
}
