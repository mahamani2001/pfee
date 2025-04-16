import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AppointmentService {
  final String baseUrl = 'http://10.0.2.2:3001/api/appointments';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt');
  }

  // 1️⃣ Réserver un rendez-vous
  Future<Map<String, dynamic>> reserveAppointment({
    required int psychiatristId,
    required String date,
    required String startTime,
    required int durationMinutes,
    int? availabilityId, // 👈 facultatif
  }) async {
    final token = await _getToken();

    final Map<String, dynamic> body = {
      'psychiatristId': psychiatristId,
      'date': date,
      'startTime': startTime,
      'duration_minutes': durationMinutes,
    };

    if (availabilityId != null) {
      body['availabilityId'] = availabilityId;
    }

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    print('🟡 Status: ${response.statusCode}');
    print('🟠 Body: ${response.body}');

    final data = jsonDecode(response.body);
    return {'status': response.statusCode, 'data': data};
  }

  // 2️⃣ Annuler un rendez-vous
  Future<bool> cancelAppointment(int appointmentId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/$appointmentId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 204;
  }

  Future<List<dynamic>> getAppointmentsByStatus(String status) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse(
          '$baseUrl/me?status=$status'), // 👈 ici tu passes ?status=confirmed
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body);
    return data;
  }

  Future<List<dynamic>> getAvailabilities(int psychiatristId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/available/$psychiatristId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Erreur récupération créneaux");
    }
  }

  Future<List<String>> getReservedTimes(int psychiatristId, String date) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/reserved?psychiatristId=$psychiatristId&date=$date'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['reserved']);
    } else {
      throw Exception("Erreur récupération heures réservées");
    }
  }

  Future<bool> proposeCustomAppointment({
    required int psychiatristId,
    required String date,
    required String startTime,
  }) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/propose'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'psychiatristId': psychiatristId,
        'date': date,
        'startTime': startTime,
      }),
    );

    return response.statusCode == 201;
  }

  Future<bool> rescheduleAppointment({
    required int appointmentId,
    required String date,
    required String startTime,
  }) async {
    final token = await _getToken();

    final response = await http.put(
      Uri.parse('$baseUrl/$appointmentId/reschedule'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'date': date,
        'startTime': startTime,
      }),
    );

    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    return response.statusCode == 200;
  }

  Future<bool> checkAccess(int appointmentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');

    final response = await http.get(
      Uri.parse(
          'http://10.0.2.2:3001/api/appointments/can-access/$appointmentId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access'] == true;
    } else {
      return false;
    }
  }
}
