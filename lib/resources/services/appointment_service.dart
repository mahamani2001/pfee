import 'dart:convert';
import 'package:googleapis/driveactivity/v2.dart';
import 'package:http/http.dart' as http;
import 'package:mypsy_app/helpers/app_config.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/resources/services/http_service.dart';

class AppointmentService {
  String baseUrl = '${AppConfig.instance()!.baseUrl}appointments';
  String baseUrlavailability = '${AppConfig.instance()!.baseUrl!}availability';
  // 1️⃣ Réserver un rendez-vous
  Future<Map<String, dynamic>> reserveAppointment({
    required int psychiatristId,
    required String date,
    required String startTime,
    int durationMinutes = 30,
    int? availabilityId,
  }) async {
    String urlRes = '${baseUrl}';
    final token = await AuthService().getToken();
    final response = await http.post(
      Uri.parse(urlRes),
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

  Future<Map<String, dynamic>?> getConsultationByAppointment(
      int appointmentId) async {
    print("Let s het the  list  $appointmentId");
    final response = await HttpService().request(
      url:
          '${AppConfig.instance()!.baseUrl}consultation/appointment/$appointmentId',
      method: 'GET',
    );

    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body);
    return body['consultation'];
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

  Future<List<dynamic>> getAppointmentsByStatus(String status) async {
    final response = await HttpService().request(
      url: '$baseUrl/me?status=$status',
      method: 'GET',
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        print('get decoded ${decoded}');
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

  Future<bool> checkAccess(int appointmentId) async {
    final response = await HttpService().request(
      url: '$baseUrl/can-access/$appointmentId',
      method: 'GET',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('dat can access ??? $data');
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
        body: {},
      );

      return response.statusCode == 200;
    } catch (e) {
      print("❌ Erreur confirmAppointment: $e");
      return false;
    }
  }

  Future<bool> rejectAppointment(int appointmentId, String reason) async {
    final response = await HttpService().request(
      url: '$baseUrl/$appointmentId/reject',
      method: 'PUT',
      body: {'reason': reason},
    );

    print("🔴 Reject response: ${response.statusCode} | ${response.body}");
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

  Future<Map<String, dynamic>?> getMyAvailiblity(int psyId) async {
    final response = await HttpService().request(
      url: '$baseUrlavailability/$psyId',
      method: 'GET',
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('❌ Erreur récupération rendez-vous : ${response.body}');
      return null;
    }
  }

  Future<bool> setAvailiblity({
    required dynamic slots,
  }) async {
    final response = await HttpService().request(
      url: baseUrlavailability,
      method: 'POST',
      body: {'slots': slots},
    );
    return response.statusCode == 201;
  }

  Future<void> extendConsultation({
    required int consultationId,
    required int extraMinutes,
  }) async {
    final response = await HttpService().request(
      url:
          '${AppConfig.instance()!.baseUrl}consultation/$consultationId/extend',
      method: 'PUT',
      body: {'minutes': extraMinutes},
    );

    if (response.statusCode != 200) {
      throw Exception("Erreur lors de la prolongation de la consultation");
    }
  }

  Future<void> extendAppointment(
      {required int appointmentId, required int extraMinutes}) async {
    final response = await HttpService().request(
      url: '$baseUrl/$appointmentId/extend',
      method: 'PUT',
      headers: {'Authorization': 'Bearer ${await AuthService().getToken()}'},
      body: {'extraMinutes': extraMinutes},
    );

    if (response.statusCode != 200) throw Exception('Échec de la prolongation');
  }

  Future<bool> deleteAvailability(int id) async {
    final token = await AuthService().getToken();

    final url = Uri.parse("${baseUrlavailability}/$id");

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print(
        "🔴 DELETE availability response: ${response.statusCode} | ${response.body}");

    return response.statusCode >= 200 && response.statusCode < 300;
  }

  Future<bool> updateAvailability({
    required int id,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    final token = await AuthService().getToken();

    final url = Uri.parse("${baseUrlavailability}/$id");

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
      }),
    );

    print(
        "🟢 UPDATE availability response: ${response.statusCode} | ${response.body}");

    return response.statusCode == 200;
  }
}
