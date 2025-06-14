import 'package:mypsy_app/resources/services/fcm_service.dart';
import 'package:mypsy_app/screens/apointment/appointment.dart';
import 'package:mypsy_app/screens/apointment/requests.dart';
import 'package:mypsy_app/screens/home/home_psy.dart';
import 'package:mypsy_app/screens/profil/settings.dart';
import 'package:mypsy_app/screens/psy_part/availibilty.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/ui/device_types.dart';
import 'package:mypsy_app/shared/ui/menu/icon_menu.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreenPsy extends StatefulWidget {
  final int initialTabIndex;
  const MainScreenPsy({super.key, required this.initialTabIndex});

  @override
  State<MainScreenPsy> createState() => _MainScreenPsyState();
}

class _MainScreenPsyState extends State<MainScreenPsy>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool isLoggedIn = false;
  String? userName;
  SharedPreferences? prefs;

  final List<Widget> _screens = [
    const HomePsy(),
    const Demandes(),
    const Appointment(),
    const Settings(),
    DoctorAvailiblity(),
  ];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await FCMService().initFCM(context);
    });

    _currentIndex = widget.initialTabIndex;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.mypsyBgApp,
        body: _screens[_currentIndex],
        bottomNavigationBar: Container(
          padding:
              EdgeInsets.only(bottom: Device.get().isIos! ? 17 : 8, top: 5),
          color: AppColors.mypsyWhite,
          child: Container(
            margin: const EdgeInsets.only(left: 10, right: 10),
            width: MediaQuery.of(context).size.width,
            color: AppColors.mypsyWhite,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _currentIndex = 0),
                  child: IconMenu(
                    icon: 'assets/menu/home.svg',
                    isSelected: _currentIndex == 0,
                    title: 'Accueil',
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _currentIndex = 1),
                  child: IconMenu(
                    icon: 'assets/menu/booking.svg',
                    isSelected: _currentIndex == 1,
                    title: 'Demandes',
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _currentIndex = 2),
                  child: IconMenu(
                    icon: 'assets/menu/booking.svg',
                    isSelected: _currentIndex == 2,
                    title: 'Rdv',
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _currentIndex = 3),
                  child: IconMenu(
                    icon: 'assets/menu/user.svg',
                    isSelected: _currentIndex == 3,
                    title: 'Profil',
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _currentIndex = 4),
                  child: IconMenu(
                    icon: 'assets/menu/booking.svg',
                    isSelected: _currentIndex == 4,
                    title: 'Calendar',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
