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
                //Lottie.asset('assets/animations/success.json',
                // width: 200, repeat: false),
                const SizedBox(height: 32),
                Text(
                  'Rendez-vous réservé avec succès 🎉',
                  textAlign: TextAlign.center,
                  style: AppThemes.getTextStyle(
                      clr: AppColors.mypsyDarkBlue, size: 20),
                ),
                const SizedBox(height: 20),
                mypsyButton(
                  isFull: true,
                  onPress: () {
                    _navigateToAppointments;
                  },
                  bgColors: AppColors.mypsyDarkBlue,
                  text: "Voir mes rendez-vous",
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
}
