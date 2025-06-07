import 'package:mypsy_app/resources/services/socket_service.dart';
import 'package:mypsy_app/screens/apointment/appointment_success.dart';
import 'package:mypsy_app/screens/calendar/calednar_info.dart';
import 'package:mypsy_app/screens/home/doctor_info.dart';
import 'package:mypsy_app/screens/home/home.dart';
import 'package:mypsy_app/screens/profil/contact.dart';
import 'package:mypsy_app/screens/notifications_screen.dart';
import 'package:mypsy_app/screens/psys/doctors_list.dart';
import 'package:mypsy_app/screens/splash/splash.dart';
import 'package:mypsy_app/shared/routes.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/ui/error/error_page.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class MyApp extends StatefulWidget {
  bool? showError;
  FlutterErrorDetails? errorDetails;

  MyApp({
    super.key,
    this.showError = false,
    this.errorDetails,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) => MaterialApp(
        navigatorKey: navigatorKey,
        locale: const Locale('fr'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr')],
        title: 'mypsy',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.mypsyPrimary),
          useMaterial3: true,
        ),
        home: widget.showError!
            ? Scaffold(
                body: ErrorScreen(
                  errorMessage:
                      widget.errorDetails?.exceptionAsString() ?? 'Erreur',
                ),
              )
            : const SplashScreen(),
        routes: {
          '/home': (context) => const Home(),
          Routes.contact: (context) => const ContactPage(),
          Routes.doctorInfo: (context) => const DoctorDetailScreen(),
          Routes.booking: (context) => const BookingPage(),
          Routes.appointmentSuccess: (context) =>
              const AppointmentSuccessScreen(),
          Routes.doctorliste: (context) => const DoctorListScreen(),
          '/psy-list': (context) => const DoctorListScreen(),
          Routes.notificationsScreen: (_) => const NotificationsScreen(),
          '/notifications': (_) => const NotificationsScreen(),
        },
      );
}
