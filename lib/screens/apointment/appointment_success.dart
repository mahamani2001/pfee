import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mypsy_app/screens/layouts/main_screen.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:mypsy_app/shared/ui/buttons/button.dart';

class AppointmentSuccessScreen extends StatefulWidget {
  const AppointmentSuccessScreen({super.key});

  @override
  State<AppointmentSuccessScreen> createState() =>
      _AppointmentSuccessScreenState();
}

class _AppointmentSuccessScreenState extends State<AppointmentSuccessScreen> {
  Timer? _autoRedirect;

  @override
  void initState() {
    super.initState();
    // Auto-redirect après 4 secondes
    _autoRedirect = Timer(const Duration(seconds: 5), () {
      _navigateToAppointments();
    });
  }

  @override
  void dispose() {
    _autoRedirect?.cancel();
    super.dispose();
  }

  void _navigateToAppointments() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen(initialTabIndex: 1)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withOpacity(0.1),
                  ),
                  child: const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.check, size: 40, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 50),

                Text(
                  "Rendez-vous réservé avec succès",
                  style: AppThemes.getTextStyle(
                      fontWeight: FontWeight.bold, size: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    "Votre rendez-vous a été planifié avec succès.\n Vous pouvez consulter les détails dans l'onglet Rendez-vous.",
                    textAlign: TextAlign.center,
                    style: AppThemes.getTextStyle(),
                  ),
                ),
                const SizedBox(height: 70),
                mypsyButton(
                  isFull: true,
                  onPress: () {
                    _navigateToAppointments;
                  },
                  text: "Voir mes rendez-vous",
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
}
