import 'dart:convert';
import 'package:mypsy_app/resources/services/http_service.dart';

class AppointmentService {
  final String baseUrl = 'http://10.0.2.2:3001/api/appointments';

  // 1️⃣ Réserver un rendez-vous
  Future<Map<String, dynamic>> reserveAppointment({
    required int psychiatristId,
    required String date,
    required String startTime,
    required int durationMinutes,
    int? availabilityId,
  }) async {
    final Map<String, dynamic> body = {
      'psychiatristId': psychiatristId,
      'date': date,
      'startTime': startTime,
      'duration_minutes': durationMinutes,
    };
    if (availabilityId != null) {
      body['availabilityId'] = availabilityId;
    }

    final response = await HttpService().request(
      url: baseUrl,
      method: 'POST',
      body: body,
    );

    return {
      'status': response.statusCode,
      'data': jsonDecode(response.body),
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

  // 3️⃣ Récupérer les rendez-vous par statut
  Future<List<dynamic>> getAppointmentsByStatus(String status) async {
    final response = await HttpService().request(
      url: 'http://10.0.2.2:3001/api/appointments/me?status=$status',
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
  }) async {
    final response = await HttpService().request(
      url: '$baseUrl/propose',
      method: 'POST',
      body: {
        'psychiatristId': psychiatristId,
        'date': date,
        'startTime': startTime,
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
        url: 'http://10.0.2.2:3001/api/appointments/$appointmentId/confirm',
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
      url: 'http://10.0.2.2:3001/api/appointments/$appointmentId/reject',
      method: 'PUT',
      body: {},
    );

    print(
        "🔴 Reject response: ${response.statusCode} | ${response.body}"); // ← AJOUTE CETTE LIGNE

    return response.statusCode == 200;
  }
}
