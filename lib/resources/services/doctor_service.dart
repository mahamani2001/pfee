import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DoctorService {
  final String baseUrl = 'http://10.0.2.2:3001/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt');
  }

  Future<List<Map<String, dynamic>>> getAllPsychiatrists() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/auth/psy'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['users']);
  }

  /*  Future<List<dynamic>> getAvailabilities(int psychiatristId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');

    final response = await http.get(
      Uri.parse('$baseUrl/appointments/available/$psychiatristId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Erreur récupération créneaux");
    }
  } */
}
