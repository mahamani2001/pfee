import 'package:flutter/material.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/resources/services/crypto_service.dart';
import 'package:mypsy_app/screens/authentification/widgets/footer_btn.dart';
import 'package:mypsy_app/screens/layouts/main_screen.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:mypsy_app/shared/ui/commun_widget.dart';
import 'package:mypsy_app/shared/ui/flushbar.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

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
      await _cryptoService.generateAndStoreKeyPair();
      final result = await _authService.verifyOTP(
        _otpController.text.trim(),
        widget.tempToken,
      );

      if (result['status'] == 200) {
        await _authService.saveTokens(
          result['token'],
          result['refreshToken'],
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const MainScreen(initialTabIndex: 0),
            ),
          );
        }
      } else {
        customFlushbar('', result['error'] ?? 'Erreur inconnue', context,
            isError: true);
      }
    } catch (e) {
      customFlushbar('', 'Erreur OTP ou connexion. Vérifie le code', context,
          isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: mainDecoration,
          child: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Vérification de sécurité',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Le reste centré
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                              'Un code a été envoyé à votre adresse email.\nVeuillez le saisir ci-dessous.',
                              textAlign: TextAlign.center,
                              style: AppThemes.getTextStyle(
                                  clr: AppColors.mypsyWhite,
                                  size: 15,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(
                            height: 60,
                          ),
                          PinCodeTextField(
                            length: 6,
                            appContext: context,
                            controller: _otpController,
                            animationType: AnimationType.fade,
                            pinTheme: PinTheme(
                              shape: PinCodeFieldShape.box,
                              borderRadius: BorderRadius.circular(10),
                              fieldHeight: 50,
                              fieldWidth: 45,
                              activeFillColor: Colors.white,
                              selectedColor: Colors.white,
                              activeColor: Colors.white,
                              inactiveColor: Colors.white70,
                            ),
                            cursorColor: Colors.black,
                            animationDuration:
                                const Duration(milliseconds: 300),
                            enableActiveFill: true,
                            onCompleted: (value) {
                              // action après saisie complète
                            },
                            onChanged: (value) {},
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: isLoading ? null : verify,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[900],
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator()
                                : const Text("Valider"),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {},
                            child: const Text("Renvoyer le code ?",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
