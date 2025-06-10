import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mypsy_app/helpers/app_config.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/resources/services/http_service.dart';

class AppointmentService {
  String baseUrl = '${AppConfig.instance()!.baseUrl!}appointments';

  // 1️⃣ Réserver un rendez-vous
  Future<Map<String, dynamic>> reserveAppointment({
    required int psychiatristId,
    required String date,
    required String startTime,
    int durationMinutes = 30,
    int? availabilityId,
  }) async {
    final token = await AuthService().getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/appointments'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'psychiatristId': psychiatristId,
        'date': date,
        'startTime': startTime,
        'duration_minutes': durationMinutes,
        'availabilityId': availabilityId,
      }),
    );

    return {
      'status': response.statusCode,
      'body': jsonDecode(response.body),
    };
  }

  // 2️⃣ Annuler un rendez-vous
  Future<bool> cancelAppointment(int appointmentId) async {
    final response = await HttpService().request(
      url: '$baseUrl/$appointmentId',
      method: 'DELETE',
    );
    return response.statusCode == 204;
  }

  Future<dynamic> startOrFetchConsultation(int appointmentId) async {
    final url =
        '${AppConfig.instance()!.baseUrl!}consultation/appointment/$appointmentId';
    final response = await HttpService().request(
      url: url,
      method: 'GET',
    );

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final data = jsonDecode(response.body);
      return data ?? {};
    } else {
      final createResponse = await HttpService().request(
        url: '${AppConfig.instance()!.baseUrl!}consultation',
        method: 'POST',
        body: {
          'appointmentId': appointmentId,
          'type': 'chat',
        },
      );
      if (createResponse.statusCode == 201) {
        return jsonDecode(createResponse.body);
      } else {
        throw Exception("Erreur lors de la création de la consultation");
      }
    }
  }

  // 3️⃣ Récupérer les rendez-vous par statut
  Future<List<dynamic>> getAppointmentsByStatus(String status) async {
    final response = await HttpService().request(
      url: '$baseUrl/me?status=$status',
      method: 'GET',
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded;
      } else {
        print('❌ Structure inattendue : $decoded');
        return [];
      }
    } else {
      print("❌ Erreur API ${response.statusCode} - ${response.body}");
      return [];
    }
  }

  // 4️⃣ Récupérer les créneaux disponibles
  Future<List<dynamic>> getAvailabilities(int psychiatristId) async {
    final response = await HttpService().request(
      url: '$baseUrl/available/$psychiatristId',
      method: 'GET',
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Erreur récupération créneaux");
    }
  }

  // 5️⃣ Récupérer les heures réservées pour un jour donné
  Future<List<String>> getReservedTimes(int psychiatristId, String date) async {
    final response = await HttpService().request(
      url: '$baseUrl/reserved?psychiatristId=$psychiatristId&date=$date',
      method: 'GET',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['reserved']);
    } else {
      throw Exception("Erreur récupération heures réservées");
    }
  }

  // 6️⃣ Proposer un créneau personnalisé
  Future<bool> proposeCustomAppointment({
    required int psychiatristId,
    required String date,
    required String startTime,
    int durationMinutes = 30,
  }) async {
    final response = await HttpService().request(
      url: '$baseUrl/propose',
      method: 'POST',
      body: {
        'psychiatristId': psychiatristId,
        'date': date,
        'startTime': startTime,
        'duration_minutes': durationMinutes,
      },
    );
    return response.statusCode == 201;
  }

  // 7️⃣ Reprogrammer un rendez-vous
  Future<bool> rescheduleAppointment({
    required int appointmentId,
    required String date,
    required String startTime,
  }) async {
    final response = await HttpService().request(
      url: '$baseUrl/$appointmentId/reschedule',
      method: 'PUT',
      body: {
        'date': date,
        'startTime': startTime,
      },
    );
    return response.statusCode == 200;
  }

  // 8️⃣ Vérifier accès à la consultation
  Future<bool> checkAccess(int appointmentId) async {
    final response = await HttpService().request(
      url: '$baseUrl/can-access/$appointmentId',
      method: 'GET',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access'] == true;
    } else {
      return false;
    }
  }

  Future<bool> confirmAppointment(int appointmentId) async {
    try {
      final response = await HttpService().request(
        url: '$baseUrl/$appointmentId/confirm',
        method: 'PUT',
        body: {}, // même vide c’est important pour éviter le JSON.parse null côté Node.js
      );

      return response.statusCode == 200;
    } catch (e) {
      print("❌ Erreur confirmAppointment: $e");
      return false; // on retourne false en cas d’erreur
    }
  }

  Future<bool> rejectAppointment(int appointmentId) async {
    final response = await HttpService().request(
      url: '$baseUrl/$appointmentId/reject',
      method: 'PUT',
      body: {},
    );

    print(
        "🔴 Reject response: ${response.statusCode} | ${response.body}"); // ← AJOUTE CETTE LIGNE

    return response.statusCode == 200;
  }

  Future<bool> extendAppointment({
    required int appointmentId,
    required int extraMinutes,
  }) async {
    final response = await HttpService().request(
      url: '$baseUrl/$appointmentId/extend',
      method: 'PUT',
      body: {'extraMinutes': extraMinutes},
    );

    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>?> getAppointmentById(int appointmentId) async {
    final response = await HttpService().request(
      url: '$baseUrl/$appointmentId',
      method: 'GET',
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('❌ Erreur récupération rendez-vous : ${response.body}');
      return null;
    }
  }
}
