import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RatingService {
  final String baseUrl = 'http://10.0.2.2:3001/api/appointments/ratings';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt');
  }

  Future<Map<String, dynamic>> submitRating({
    required int psychiatristId,
    required int appointmentId,
    required double rating,
  }) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'psychiatristId': psychiatristId,
        'appointmentId': appointmentId,
        'rating': rating,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['message'] ??
          'Erreur lors de l\'envoi de la note');
    }
  }
}
