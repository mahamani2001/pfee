import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mypsy_app/helpers/app_config.dart';

class CryptoService {
  final algorithm = X25519();
  final aesGcm = AesGcm.with256bits();
  final storage = const FlutterSecureStorage();

  final String baseUrl = '${AppConfig.instance()!.baseUrl!}auth';

  // 🔐 Générer et stocker la paire de clés X25519 si non existante
  Future<void> generateAndStoreKeyPair() async {
    final privateKeyBase64 = await storage.read(key: 'privateKey');
    if (privateKeyBase64 != null) return; // déjà générée

    final keyPair = await algorithm.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

    await storage.write(
        key: 'privateKey', value: base64Encode(privateKeyBytes));
    await storage.write(key: 'publicKey', value: base64Encode(publicKey.bytes));

    print('🔐 Nouvelle paire de clés X25519 générée et sauvegardée');
  }

  // 🔑 Récupère ma clé privée locale
  Future<SimpleKeyPair> getMyKeyPair() async {
    final privateKeyBase64 = await storage.read(key: 'privateKey');
    if (privateKeyBase64 == null) throw Exception("Clé privée manquante");
    return algorithm.newKeyPairFromSeed(base64Decode(privateKeyBase64));
  }

  // 🔑 Récupère la clé publique d’un pair (base64 venant du backend)
  Future<SimplePublicKey> getPeerPublicKey(String base64Key) async {
    final cleanedKey =
        base64Key.contains(':') ? base64Key.split(':')[1] : base64Key;

    return SimplePublicKey(
      base64Decode(cleanedKey),
      type: KeyPairType.x25519,
    );
  }

  // 🔐 Chiffrement AES-GCM d’un message
  Future<Map<String, dynamic>> encryptMessage(
      String plainText, String peerPublicKeyBase64) async {
    final myKeyPair = await getMyKeyPair();
    final peerPublicKey = await getPeerPublicKey(peerPublicKeyBase64);

    final sharedSecret = await algorithm.sharedSecretKey(
      keyPair: myKeyPair,
      remotePublicKey: peerPublicKey,
    );

    final nonce = aesGcm
        .newNonce(); // 👈 correct, reste identique pour chiffrer/déchiffrer

    final secretBox = await aesGcm.encrypt(
      utf8.encode(plainText),
      secretKey: sharedSecret,
      nonce: nonce,
    );
    print("🔐 Encrypted:");
    print("cipherText: ${base64Encode(secretBox.cipherText)}");
    print("nonce: ${base64Encode(secretBox.nonce)}");
    print("mac: ${base64Encode(secretBox.mac.bytes)}");

    return {
      'cipherText': base64Encode(secretBox.cipherText),
      'nonce': base64Encode(secretBox.nonce),
      'mac': base64Encode(secretBox.mac.bytes), // facultatif
    };
  }

  Future<String> decryptMessage({
    required String cipherTextBase64,
    required String nonceBase64,
    required String macBase64, // 👈 ajoute ce paramètre
    required String peerPublicKeyBase64,
  }) async {
    final myKeyPair = await getMyKeyPair();
    final peerPublicKey = await getPeerPublicKey(peerPublicKeyBase64);

    final sharedSecret = await algorithm.sharedSecretKey(
      keyPair: myKeyPair,
      remotePublicKey: peerPublicKey,
    );

    final secretBox = SecretBox(
      base64Decode(cipherTextBase64),
      nonce: base64Decode(nonceBase64),
      mac: Mac(base64Decode(macBase64)), // ✅ ici tu vérifies l’authenticité
    );

    final decrypted = await aesGcm.decrypt(
      secretBox,
      secretKey: sharedSecret,
    );
    print("🧩 Decrypting with:");
    print("cipherText: $cipherTextBase64");
    print("nonce: $nonceBase64");
    print("mac: $macBase64");

    return utf8.decode(decrypted);
  }

  // 🔑 Récupère ma clé publique (X25519) locale
  Future<SimplePublicKey> getPublicKey() async {
    final publicKeyBase64 = await storage.read(key: 'publicKey');
    if (publicKeyBase64 == null) throw Exception("Clé publique manquante");
    return SimplePublicKey(
      base64Decode(publicKeyBase64),
      type: KeyPairType.x25519,
    );
  }

  // ✅ Envoi de la clé publique vers le backend
  Future<void> sendPublicKeyToBackend(String token) async {
    final publicKeyBase64 = await storage.read(key: 'publicKey');
    if (publicKeyBase64 == null) {
      throw Exception("Clé publique introuvable dans le stockage local");
    }

    final response = await http.put(
      Uri.parse('$baseUrl/publicKey'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'publicKey': publicKeyBase64}),
    );

    if (response.statusCode != 200) {
      throw Exception(
          "Erreur lors de l'envoi de la clé publique: ${response.body}");
    }

    print("✅ Clé publique envoyée au backend avec succès !");
  }
}
