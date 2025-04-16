import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:convert/convert.dart';

class EncryptionHelper {
  final Key key;

  EncryptionHelper(this.key);

  /// Chiffrement AES-GCM
  Map<String, String> encrypt(String plainText) {
    final random = Random.secure();
    final nonce = List<int>.generate(12, (_) => random.nextInt(256)); // 96-bit
    final iv = IV(Uint8List.fromList(nonce));

    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    return {
      'cipher': hex.encode(encrypted.bytes),
      'nonce': hex.encode(iv.bytes),
      // si nécessaire : 'mac': 'non supporté ici',
    };
  }

  /// Déchiffrement AES-GCM
  String decrypt(String cipherHex, String nonceHex) {
    final cipherBytes = hex.decode(cipherHex);
    final nonceBytes = hex.decode(nonceHex);
    final iv = IV(Uint8List.fromList(nonceBytes));

    final encrypted = Encrypted(Uint8List.fromList(cipherBytes));

    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    return encrypter.decrypt(encrypted, iv: iv);
  }
}
