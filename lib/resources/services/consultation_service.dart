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
    int duration_minutes = 30,
  }) async {
    try {
      final token = await AuthService().getToken();

      final body = {
        'appointmentId': appointmentId,
        'type': type,
        'duration_minutes': duration_minutes,
      };

      print("📤 startConsultation() - body envoyé : $body");

      final response = await _httpService.request(
        url: '$baseUrl',
        method: 'POST',
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print("📦 Réponse backend : ${response.statusCode} => ${response.body}");

      return _decodeResponse(response);
    } catch (e) {
      print("❌ Erreur dans startConsultation: $e");
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
      {required int appointmentId}) async {
    try {
      final response = await _httpService.request(
        url: '$baseUrl/appointment/$appointmentId',
        method: 'GET',
      );
      print(
          "📥 getConsultationByAppointment response: ${response.statusCode} - ${response.body}");
      return _decodeResponse(response);
    } catch (e) {
      print("❌ Erreur getConsultationByAppointment: $e");
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
