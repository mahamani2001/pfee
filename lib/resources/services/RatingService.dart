import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mypsy_app/helpers/app_config.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';

class RatingService {
  final baseUrl = AppConfig.instance()!.baseUrl!;

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

  Future<List<Map<String, dynamic>>> getPsychiatristRatings(
      int psychiatristId) async {
    try {
      final token = await AuthService().getToken();

      final response = await http.get(
        Uri.parse('${baseUrl}appointments/ratings/$psychiatristId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception("Erreur lors de la récupération des notes");
      }
    } catch (e) {
      print("❌ Erreur dans getPsychiatristRatings : $e");
      rethrow;
    }
  }

  Future<double> getAverageRating(int psychiatristId) async {
    final response = await http.get(
      Uri.parse('${baseUrl}appointments/ratings/$psychiatristId/average'),
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      return double.tryParse(jsonBody['averageRating']?.toString() ?? '0') ??
          0.0;
    } else {
      throw Exception('Échec du chargement de la note moyenne');
    }
  }

  Future<void> addOrUpdateNote({
    required int appointmentId,
    required String note,
  }) async {
    print("📩 Tentative d'envoi de note...");
    print("🧾 appointmentId: $appointmentId");
    print("🧾 note: $note");

    final token = await AuthService().getToken();
    print("🔐 Token récupéré : $token");

    if (token == null) {
      throw Exception('Token JWT introuvable. Veuillez vous reconnecter.');
    }

    final url = '${AppConfig.instance()!.baseUrl!}appointments/notes';

    final body = {
      'appointmentId': appointmentId,
      'note': note, // ✅ patientId supprimé
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    print("📥 Status code: ${response.statusCode}");
    print("📥 Response body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception('Erreur enregistrement note : ${response.body}');
    }

    print("✅ Note envoyée avec succès !");
  }

  Future<String?> getPsyNote(int appointmentId) async {
    final token = await AuthService().getToken();
    if (token == null) {
      throw Exception('Token JWT introuvable. Veuillez vous reconnecter.');
    }

    final response = await http.get(
      Uri.parse(
          '${AppConfig.instance()!.baseUrl}appointments/notes/$appointmentId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['note'];
    } else {
      print('getPsyNote Error: ${response.body}');
      return null;
    }
  }
}
