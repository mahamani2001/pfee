import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:mypsy_app/helpers/app_config.dart';

class PublicKeyAPI {
  String baseUrl = '${AppConfig.instance()!.baseUrl!}public-key';

  Future<String> getPublicKey(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$userId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['publicKey'];
    } else {
      throw Exception('Erreur lors de la récupération de la clé publique');
    }
  }
}
