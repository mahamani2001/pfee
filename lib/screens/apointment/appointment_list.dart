import 'package:flutter/material.dart';
import 'package:mypsy_app/resources/services/appointment_service.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/screens/apointment/appointment_item.dart';
import 'package:mypsy_app/utils/constants.dart';

class AppointmentList extends StatefulWidget {
  final String status;
  const AppointmentList({super.key, required this.status});

  @override
  State<AppointmentList> createState() => _AppointmentListState();
}

class _AppointmentListState extends State<AppointmentList> {
  List<dynamic> appointments = [];
  String? userRole;
  bool canAccessAppointment(Map<String, dynamic> appt) {
    final date = DateTime.parse(appt['date']); // ex: 2025-06-09
    final startTime = appt['start_time']; // ex: "14:30"
    final startParts = startTime.split(':');
    final startDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(startParts[0]),
      int.parse(startParts[1]),
    );

    final endDateTime = startDateTime.add(Duration(
      minutes: appt['duration_minutes'] ?? 30,
    ));

    final now = DateTime.now();
    return now.isAfter(startDateTime) && now.isBefore(endDateTime);
  }

  @override
  void initState() {
    super.initState();
    loadAppointments();
  }

  Future<void> loadAppointments() async {
    final data =
        await AppointmentService().getAppointmentsByStatus(widget.status);
    final role = await AuthService().getUserRole();

    setState(() {
      appointments = List<Map<String, dynamic>>.from(data);
      userRole = role;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final futureAppointments = appointments.where((appt) {
      final date = DateTime.parse(appt['date']);
      final startParts = appt['start_time'].split(':');
      final startDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(startParts[0]),
        int.parse(startParts[1]),
      );

      // Inclure rendez-vous à venir ou exactement maintenant
      return !startDateTime.isBefore(now);
    }).toList();

    /*if (futureAppointments.isEmpty) {
      return Center(
        child: Text("Aucun rendez-vous",
            style: AppThemes.getTextStyle(clr: Colors.grey, size: 16)),
      );
    }*/

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appt = appointments[index];
        final displayName = userRole == 'psychiatrist'
            ? appt['patient_name'] ?? 'Patient inconnu'
            : "Dr. ${appt['psychiatrist_name'] ?? 'Inconnu'}";

        return AppointmentCard(
            id: appt['id'],
            psychiatristId: appt['psychiatrist_id'],
            patientId: appt['patient_id'],
            name: displayName,
            time: appt['start_time'].toString().substring(0, 5),
            date: appt['date'],
            status: widget.status,
            userRole: userRole ?? '',
            onReload: loadAppointments,
            appt: appt,
            canJoin: canAccessAppointment(appt),
            specialite: (userRole == PSY_ROLE)
                ? (appt['dans_la_vie_tu_es'] ?? '')
                : '');
      },
    );
  }
}
