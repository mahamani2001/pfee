import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mypsy_app/resources/services/auth_service.dart';

class RatingService {
  Future<void> submitRating({
    required int psychiatristId,
    required int appointmentId,
    required double rating,
  }) async {
    try {
      final token = await AuthService().getToken();
      print('🪪 TOKEN UTILISÉ : $token');
      final response = await http.post(
        Uri.parse('http://192.168.1.2:3001/api/appointments/ratings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // ✅ ajoute le token ici
        },
        body: jsonEncode({
          'psychiatristId': psychiatristId,
          'appointmentId': appointmentId,
          'rating': rating,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            "Erreur HTTP ${response.statusCode} : ${response.body}");
      }
    } catch (e) {
      print("❌ Erreur dans submitRating : $e");
      rethrow; // pour propager à l'appelant
    }
  }
}
