import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mypsy_app/helpers/app_config.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';

class RatingService {
  Future<void> submitFeedback({
    required int consultationId,
    required int patientId,
    required String feedback,
  }) async {
    final url = "${AppConfig.instance()!.baseUrl!}/consultation/feedbacks";
    final token = await AuthService().getToken();

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'consultationId': consultationId,
        'patientId': patientId,
        'note': feedback,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Erreur lors de l’envoi du feedback');
    }
  }

  Future<void> submitRating({
    required int psychiatristId,
    required int appointmentId,
    required double rating,
    String? comment,
  }) async {
    try {
      String baseUrl = AppConfig.instance()!.baseUrl!;
      final token = await AuthService().getToken();

      final response = await http.post(
        Uri.parse('${baseUrl}appointments/ratings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'psychiatristId': psychiatristId,
          'appointmentId': appointmentId,
          'rating': rating,
          'comment': comment ?? "", // ajouter le commentaire
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            "Erreur HTTP ${response.statusCode} : ${response.body}");
      }
    } catch (e) {
      print("❌ Erreur dans submitRating : $e");
      rethrow;
    }
  }
}
