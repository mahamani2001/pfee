import 'dart:convert';
import 'package:http/http.dart' as http;

class QuizService {
  final String baseUrl = "http://10.0.2.2:3001/api/quiz";

  Future<void> submitResult({
    required int userId,
    required double score,
    required String level,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/submit"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "userId": userId,
        "score": score,
        "anxietyLevel": level,
      }),
    );

    if (res.statusCode == 201) {
      print("✅ Résultat envoyé avec succès.");
    } else {
      print("❌ Erreur lors de l'envoi : ${res.statusCode} - ${res.body}");
    }
  }
}
