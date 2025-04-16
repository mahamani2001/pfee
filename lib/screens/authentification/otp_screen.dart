import 'package:flutter/material.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/resources/services/crypto_service.dart';
import 'package:mypsy_app/screens/layouts/main_screen.dart';

class OtpScreen extends StatefulWidget {
  final String tempToken;

  const OtpScreen({super.key, required this.tempToken});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final AuthService _authService = AuthService();
  final CryptoService _cryptoService = CryptoService();

  bool isLoading = false;
  Future<void> verify() async {
    setState(() => isLoading = true);
    try {
      // ✅ Étape 1 : Générer la clé (si absente)
      await _cryptoService.generateAndStoreKeyPair();

      // ✅ Étape 2 : Vérifier l'OTP
      final result = await _authService.verifyOTP(
        _otpController.text.trim(),
        widget.tempToken,
      );

      if (result['status'] == 200) {
        // ✅ Étape 3 : Sauvegarder le token
        await _authService.saveTokens(
          result['token'],
          result['refreshToken'],
        );

        // ✅ Étape 4 : Redirection
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const MainScreen(initialTabIndex: 0),
            ),
          );
        }
      } else {
        showSnack(result['error'] ?? 'Erreur inconnue');
      }
    } catch (e) {
      print('❌ Exception dans verify(): $e');
      showSnack('Erreur OTP ou connexion. Vérifie le code.');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Vérification OTP")),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text("Un code vous a été envoyé par email."),
              const SizedBox(height: 20),
              TextField(
                controller: _otpController,
                decoration:
                    const InputDecoration(labelText: "Entrer le code OTP"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : verify,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Valider"),
              ),
            ],
          ),
        ),
      );
}
