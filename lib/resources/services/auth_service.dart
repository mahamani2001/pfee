import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mypsy_app/resources/services/crypto_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cryptography/cryptography.dart';

class AuthService {
  final String baseUrl = 'http://10.0.2.2:3001/api/auth';
  final storage = FlutterSecureStorage();
  Future<String?> getJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt');
  }

  static bool isTokenExpired(String? token) {
    if (token == null) return true;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final payloadMap = json.decode(payload);
      final exp = payloadMap['exp'];
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return exp < now;
    } catch (_) {
      return true;
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
      print('🔴 Impossible de refreshToken : ${response.body}');
      return null;
    }
  }

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

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  Future<String?> getValidToken() async {
    final accessToken = await getAccessToken();

    if (!isTokenExpired(accessToken)) {
      return accessToken;
    }

    print('🔁 Token expiré. Tentative de refresh...');
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return null;

    final response = await http.post(
      Uri.parse('http://10.0.2.2:3001/api/auth/refresh-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final newAccessToken = data['token'];
      final newRefreshToken = data['refreshToken'];

      await saveTokens(newAccessToken, newRefreshToken);
      print('✅ Nouveau token rafraîchi avec succès');
      return newAccessToken;
    } else {
      print('❌ Erreur lors du refresh: ${response.body}');
      return null;
    }
  }

  Future<int?> getUserId() async {
    final token = await getJwtToken();
    if (token == null) return null;
    try {
      final parts = token.split('.');
      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final Map<String, dynamic> payloadMap = json.decode(payload);
      return payloadMap['userId'];
    } catch (_) {
      return null;
    }
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

  Future<String?> getToken() async {
    final prefs = await storage;
    return prefs.read(key: 'token');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final storage = FlutterSecureStorage();

    try {
      // 🔥 Supprimer les données sensibles stockées
      await storage.deleteAll(); // Supprimer tout de FlutterSecureStorage
      await prefs.clear(); // Supprimer tout de SharedPreferences

      print('🧹 Déconnexion réussie : stockage nettoyé.');
    } catch (e) {
      print('❌ Erreur lors du logout: $e');
    }
  }
}
