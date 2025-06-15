import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mypsy_app/helpers/app_config.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';

class RatingService {
  Future<void> submitRating({
    required int psychiatristId,
    required int appointmentId,
    required double rating,
  }) async {
    try {
      String baseUrl = AppConfig.instance()!.baseUrl!;
      print('appointmentId $appointmentId');
      print('psychiatristId $psychiatristId');
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
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            "Erreur HTTP  here${response.statusCode} : ${response.body}");
      }
    } catch (e) {
      print("❌ Erreur dans submitRating : $e");
      rethrow; // pour propager à l'appelant
    }
  }
}
