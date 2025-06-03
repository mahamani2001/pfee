import 'package:http/http.dart' as http;
import 'dart:convert';

class PublicKeyAPI {
  Future<String> getPublicKey(String userId) async {
    final response = await http.get(
      Uri.parse('192.168.100.139:3001/api/public-key/$userId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['publicKey'];
    } else {
      throw Exception('Erreur lors de la récupération de la clé publique');
    }
  }
}
