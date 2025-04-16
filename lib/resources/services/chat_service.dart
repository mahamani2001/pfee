import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  final String baseUrl = 'http://10.0.2.2:3001/api/messages';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt');
  }

  // 🔁 Récupérer les messages chiffrés depuis le backend
  Future<List<dynamic>> getMessages(int appointmentId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/$appointmentId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['messages'];
    } else {
      print('❌ Erreur lors du chargement des messages : ${response.body}');
      throw Exception("Erreur chargement historique");
    }
  }

  // ✅ Enregistrer un message chiffré
  Future<void> saveMessage({
    required int appointmentId,
    required String iv,
    required String ciphertext,
    required String tag,
  }) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'appointmentId': appointmentId,
        'iv': iv,
        'ciphertext': ciphertext,
        'tag': tag,
      }),
    );

    if (response.statusCode != 201) {
      print('❌ Échec enregistrement message : ${response.body}');
      throw Exception("Erreur d'envoi du message");
    }
  }
}
