import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final storage = FlutterSecureStorage();

  Future<void> savePrivateKey(String base64Key) async {
    await storage.write(key: 'privateKey', value: base64Key);
  }

  Future<String?> readPrivateKey() async {
    return await storage.read(key: 'privateKey');
  }
}
