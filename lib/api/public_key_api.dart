import 'package:http/http.dart' as http;
import 'dart:convert';

class PublicKeyAPI {
  Future<String> getPublicKey(String userId) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:3001/api/public-key/$userId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['publicKey'];
    } else {
      throw Exception('Erreur lors de la récupération de la clé publique');
    }
  }
}
