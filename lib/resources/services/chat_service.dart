import 'dart:convert';
import 'package:mypsy_app/resources/services/http_service.dart';

class ChatService {
  final String baseUrl = 'http://10.0.2.2:3001/api/messages';

  // 🔁 Récupérer les messages chiffrés depuis le backend
  Future<List<dynamic>> getMessages(int appointmentId) async {
    final response = await HttpService().request(
      url: '$baseUrl/$appointmentId',
      method: 'GET',
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
    required int receiverId,
  }) async {
    final response = await HttpService().request(
      url: baseUrl,
      method: 'POST',
      body: {
        'appointmentId': appointmentId,
        'to': receiverId, // ✅ C’EST ÇA QUI MANQUAIT
        'iv': iv,
        'ciphertext': ciphertext,
        'tag': tag,
      },
    );

    if (response.statusCode != 201) {
      print('❌ Échec enregistrement message : ${response.body}');
      throw Exception("Erreur d'envoi du message");
    }
  }
}
