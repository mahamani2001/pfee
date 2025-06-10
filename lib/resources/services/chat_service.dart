import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mypsy_app/helpers/app_config.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/resources/services/http_service.dart';

class ChatService {
  // Correction : ajout d'un slash manquant si baseUrl ne le contient pas déjà
  final String baseUrl = '${AppConfig.instance()!.baseUrl!}messages';

  /// Récupérer les messages liés à un rendez-vous
  Future<List<dynamic>> getMessages(int consultationId) async {
    final response = await HttpService().request(
      url: '$baseUrl/$consultationId',
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

  /// Enregistrer un message chiffré dans la base de données
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
        'to': receiverId,
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

  /// Envoyer un fichier (image, doc, etc.) dans une conversation
  Future<String?> uploadFileMessage({
    required File file,
    required int appointmentId,
    required int receiverId,
  }) async {
    final uri = Uri.parse('$baseUrl/upload');
    final token = await AuthService().getToken();

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['appointmentId'] = appointmentId.toString()
      ..fields['receiverId'] = receiverId.toString()
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();

    if (response.statusCode == 201) {
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseBody);
      return jsonResponse['url'];
    } else {
      print('❌ Upload failed: ${response.statusCode}');
      return null;
    }
  }

  /// Upload d’un fichier médical (peut être fusionné avec `uploadFileMessage`)
  Future<void> uploadMedicalFile({
    required File file,
    required int appointmentId,
    required int receiverId,
  }) async {
    final uri = Uri.parse('$baseUrl/upload');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${await AuthService().getToken()}'
      ..fields['appointmentId'] = appointmentId.toString()
      ..fields['receiverId'] = receiverId.toString()
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();

    if (response.statusCode == 201) {
      print('✅ Fichier uploadé avec succès');
    } else {
      print('❌ Échec de l’upload : ${response.statusCode}');
    }
  }
}
