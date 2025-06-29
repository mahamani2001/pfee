import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mypsy_app/screens/apointment/appointment_list.dart';
import 'package:mypsy_app/screens/layouts/main_screen.dart';
import 'package:mypsy_app/screens/layouts/main_screen_psy.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Demandes extends StatelessWidget {
  const Demandes({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
              icon: Container(
                color: Colors.transparent,
                width: 100,
                height: 40,
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.mypsyBlack,
                  size: 15,
                ),
              ),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final role = prefs.getString('user_role');
                if (role == "psychiatrist") {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MainScreenPsy(initialTabIndex: 0),
                    ),
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MainScreen(initialTabIndex: 0),
                    ),
                  );
                }
              }),
          centerTitle: true,
          title: const Text(
            "Liste des demandes",
            style: AppThemes.appbarSubPageTitleStyle,
          ),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const AppointmentList(status: 'pending'),
      );
}
