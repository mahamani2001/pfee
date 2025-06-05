import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mypsy_app/helpers/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FileUploadService {
  String baseUrl = AppConfig.instance()!.baseUrl!;

  final Dio _dio = Dio();

  Future<String?> uploadMedicalFile(
      File file, int appointmentId, int receiverId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final fileName = file.path.split('/').last;

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
      'appointmentId': appointmentId.toString(),
      'receiverId': receiverId.toString(),
    });

    final response = await _dio.post(
      '$baseUrl/uploads',
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    if (response.statusCode == 201) {
      return response.data['url'];
    } else {
      return null;
    }
  }
}
