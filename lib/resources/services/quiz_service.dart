import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mypsy_app/helpers/app_config.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';

class QuizService {
  String baseUrl = '${AppConfig.instance()!.baseUrl!}quiz';

  // 🔹 Enregistrer un résultat de quiz
  Future<bool> submitResult({
    required int userId,
    required double score,
    required String anxietyLevel,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/submit'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // ✅ Obligatoire
      },
      body: jsonEncode({
        'userId': userId,
        'score': score,
        'anxietyLevel': anxietyLevel,
      }),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      print("❌ Erreur submitResult: ${response.body}");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final token = await AuthService().getJwtToken();
    final userId = await AuthService().getUserId();

    final res = await http.get(
      Uri.parse('$baseUrl/results/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data
          .map((e) => {
                'score': double.tryParse(e['score'].toString()) ?? 0.0,
                'category': e['category'],
                'date': DateTime.parse(e['date']),
              })
          .toList();
    } else {
      throw Exception("Erreur lors de la récupération de l’historique");
    }
  }
}
