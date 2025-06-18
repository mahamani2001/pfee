import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mypsy_app/screens/apointment/appointment_list.dart';
import 'package:mypsy_app/screens/layouts/main_screen.dart';
import 'package:mypsy_app/screens/layouts/main_screen_psy.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Appointment extends StatefulWidget {
  const Appointment({super.key});

  @override
  State<Appointment> createState() => _AppointmentState();
}

class _AppointmentState extends State<Appointment> {
  String? role;

  @override
  void initState() {
    getRole();
    super.initState();
  }

  getRole() async {
    final prefs = await SharedPreferences.getInstance();
    role = prefs.getString('user_role');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    String psyRole = "psychiatrist";
    return DefaultTabController(
      length: 3,
      child: Scaffold(
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
                if (role == psyRole) {
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
            "Mes rendez-vous ",
            style: AppThemes.appbarSubPageTitleStyle,
          ),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            labelColor: AppColors.mypsyDarkBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.mypsyDarkBlue,
            tabs: [
              const Tab(
                  child: Text(
                'À venir',
                style: AppThemes.appbarSubPageTitleStyle,
              )),
              Tab(
                child: Text(
                  role == psyRole ? 'Terminé' : 'En attente',
                  style: AppThemes.appbarSubPageTitleStyle,
                ),
              ),
              const Tab(
                  child: Text(
                'Annulé',
                style: AppThemes.appbarSubPageTitleStyle,
              )),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const AppointmentList(status: 'confirmed'),
            AppointmentList(status: role == psyRole ? 'completed' : 'pending'),
            const AppointmentList(status: 'cancelled'),
          ],
        ),
      ),
    );
  }
}
