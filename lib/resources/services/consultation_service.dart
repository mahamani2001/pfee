import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/resources/services/http_service.dart';
import 'package:mypsy_app/helpers/app_config.dart';

class ConsultationService {
  final HttpService _httpService = HttpService();
  String baseUrl = '${AppConfig.instance()!.baseUrl!}consultation';

  Future<Map<String, dynamic>?> startConsultation({
    required int appointmentId,
    required String type,
  }) async {
    try {
      final token = await AuthService().getJwtToken();

      if (token == null || AuthService.isTokenExpired(token)) {
        print('❌ Token invalide ou expiré');
        return null;
      }

      final response = await http.post(
        Uri.parse('${AppConfig.instance()!.baseUrl!}consultation'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'appointmentId': appointmentId,
          'type': type,
        }),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Vérifie les noms de clé possibles
        final consultationId = data['id'] ?? data['consultationId'];
        if (consultationId == null) {
          print('❌ Réponse sans ID de consultation');
          return null;
        }

        return data;
      } else {
        print('❌ Erreur HTTP: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Exception dans startConsultation: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> joinConsultation(int appointmentId) async {
    final token = await AuthService().getToken();

    final response = await http.get(
      Uri.parse(
          '${AppConfig.instance()!.baseUrl!}consultation/appointment/$appointmentId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      print("❌ Échec récupération consultation : ${response.body}");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getConsultationById(
      {required int consultationId}) async {
    try {
      final response = await _httpService.request(
        url: '$baseUrl/$consultationId',
        method: 'GET',
      );
      return _decodeResponse(response);
    } catch (e) {
      print("❌ Erreur getConsultationById: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getConsultationByAppointment(
      int appointmentId) async {
    final token = await AuthService().getToken();
    final response = await http.get(
      Uri.parse(
          '${AppConfig.instance()!.baseUrl!}consultation/appointment/$appointmentId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("❌ Erreur récupération consultation: ${response.body}");
      return null;
    }
  }

  Future<Map<String, dynamic>?> endConsultation(
      {required int consultationId}) async {
    try {
      final response = await _httpService.request(
        url: '$baseUrl/$consultationId/end',
        method: 'PUT',
      );
      return _decodeResponse(response);
    } catch (e) {
      print("❌ Erreur endConsultation: $e");
      return null;
    }
  }

  Map<String, dynamic>? _decodeResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      print("❌ HTTP Error ${response.statusCode}: ${response.body}");
      return null;
    }
  }
}
