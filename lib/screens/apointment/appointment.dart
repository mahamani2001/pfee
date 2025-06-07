import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mypsy_app/resources/services/appointment_service.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/screens/consultation/ConsultationLauncherScreen.dart';
import 'package:mypsy_app/shared/routes.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:mypsy_app/utils/functions.dart';

class Appointment extends StatelessWidget {
  const Appointment({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 3, // Réduit de 4 à 3 pour supprimer l'onglet "Annulé"
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
                Navigator.pop(context);
              },
            ),
            centerTitle: true,
            title: const Text(
              "Mes rendez-vous",
              style: AppThemes.appbarSubPageTitleStyle,
            ),
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            elevation: 0,
            bottom: const TabBar(
              labelColor: AppColors.mypsyDarkBlue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.mypsyDarkBlue,
              tabs: [
                Tab(
                    child: Text(
                  'À venir',
                  style: AppThemes.appbarSubPageTitleStyle,
                )),
                Tab(
                  child: Text(
                    'En attente',
                    style: AppThemes.appbarSubPageTitleStyle,
                  ),
                ),
                Tab(
                    child: Text(
                  'Passés', // Onglet restant
                  style: AppThemes.appbarSubPageTitleStyle,
                )),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              AppointmentList(
                  status: 'confirmed'), // Rendez-vous confirmés (futurs)
              AppointmentList(status: 'pending'), // En attente
              AppointmentList(status: 'past'), // Passés
            ],
          ),
        ),
      );
}

class AppointmentList extends StatefulWidget {
  final String status;
  const AppointmentList({super.key, required this.status});

  @override
  State<AppointmentList> createState() => _AppointmentListState();
}

class _AppointmentListState extends State<AppointmentList> {
  List<dynamic> appointments = [];
  String? userRole;

  @override
  void initState() {
    super.initState();
    loadAppointments();
  }

  Future<void> loadAppointments() async {
    // Récupérer les rendez-vous confirmés pour les filtrer entre "À venir" et "Passés"
    final data = widget.status == 'past' || widget.status == 'confirmed'
        ? await AppointmentService().getAppointmentsByStatus('confirmed')
        : await AppointmentService().getAppointmentsByStatus(widget.status);

    final role = await AuthService().getUserRole();

    // Filtrer les rendez-vous selon leur date et heure
    final now = DateTime.now(); // 5 juin 2025, 16h19 CET
    List<dynamic> filteredAppointments = [];

    if (widget.status == 'confirmed') {
      // "À venir" : uniquement les rendez-vous futurs
      filteredAppointments = data.where((appt) {
        final apptDateTime =
            parseAppointmentDateTime(appt['date'], appt['start_time']);
        return apptDateTime != null && apptDateTime.isAfter(now);
      }).toList();
    } else if (widget.status == 'past') {
      // "Passés" : uniquement les rendez-vous passés
      filteredAppointments = data.where((appt) {
        final apptDateTime =
            parseAppointmentDateTime(appt['date'], appt['start_time']);
        return apptDateTime != null && apptDateTime.isBefore(now);
      }).toList();
    } else {
      // Pour "En attente", on garde tous les rendez-vous
      filteredAppointments = data;
    }

    setState(() {
      appointments = filteredAppointments;
      userRole = role;
    });
  }

  // Fonction pour parser la date et l'heure du rendez-vous
  DateTime? parseAppointmentDateTime(String date, String time) {
    try {
      final dateParsed = DateTime.parse(date); // Format attendu : yyyy-MM-dd
      final timeParts = time.split(':'); // Format attendu : HH:mm
      return DateTime(
        dateParsed.year,
        dateParsed.month,
        dateParsed.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    } catch (e) {
      print("Erreur lors du parsing de la date/heure : $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return Center(
        child: Text(
          widget.status == 'past'
              ? "Aucun rendez-vous passé"
              : "Aucun rendez-vous",
          style: AppThemes.getTextStyle(clr: Colors.grey, size: 16),
        ),
      );
    }

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
        );
      },
    );
  }
}

class AppointmentCard extends StatefulWidget {
  final int id;
  final int psychiatristId;
  final int patientId;
  final String name;
  final String time;
  final String date;
  final String status;
  final String userRole;
  final VoidCallback onReload;

  const AppointmentCard({
    super.key,
    required this.id,
    required this.psychiatristId,
    required this.patientId,
    required this.name,
    required this.time,
    required this.date,
    required this.status,
    required this.userRole,
    required this.onReload,
  });

  @override
  State<AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<AppointmentCard> {
  bool canAccess = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkAccess();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _checkAccess());
  }

  Future<void> _checkAccess() async {
    final access = await AppointmentService().checkAccess(widget.id);
    if (mounted) {
      setState(() {
        canAccess = access;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFr = formatDateFr(widget.date);
    final isPast = widget.status ==
        'past'; // Indique si le rendez-vous est dans l'onglet "Passés"

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      color:
          isPast ? Colors.grey[200] : Colors.white, // Griser la carte si passée
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, size: 30),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(
                  widget.name,
                  style: AppThemes.getTextStyle(
                      fontWeight: FontWeight.bold,
                      clr: isPast ? Colors.grey : Colors.black),
                )),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: AppColors.mypsySecondary),
                const SizedBox(width: 8),
                Text(
                  "$dateFr à ${widget.time}",
                  style: AppThemes.getTextStyle(
                      clr: isPast ? Colors.grey : Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isPast) ...[
              Text(
                "Terminé",
                style: AppThemes.getTextStyle(clr: Colors.grey, size: 14),
              ),
            ] else ...[
              Row(children: _buildActionButtons(context)),
              const SizedBox(height: 12),
              _buildJoinButton(context),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(BuildContext context) {
    if (widget.userRole == 'psychiatrist' && widget.status == 'pending') {
      return [
        _button(context, 'Confirmer', Colors.green, () async {
          await AppointmentService().confirmAppointment(widget.id);
          widget.onReload();
        }),
        const SizedBox(width: 8),
        _button(context, 'Rejeter', Colors.red, () async {
          await AppointmentService().rejectAppointment(widget.id);
          widget.onReload();
        }),
      ];
    } else if (widget.status == 'pending' || widget.status == 'confirmed') {
      return [
        _button(context, 'Reprogrammer', AppColors.mypsyDarkBlue, () async {
          await Navigator.pushNamed(context, Routes.booking, arguments: {
            'psychiatristId': widget.psychiatristId,
            'appointmentId': widget.id,
          });
          widget.onReload();
        }),
        const SizedBox(width: 8),
        _button(context, 'Annuler', Colors.red, () async {
          await AppointmentService().cancelAppointment(widget.id);
          widget.onReload();
        }),
      ];
    }
    return [];
  }

  Widget _button(BuildContext context, String text, Color color,
          VoidCallback onPressed) =>
      Expanded(
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: Text(
            text,
            style: AppThemes.getTextStyle(clr: AppColors.mypsyWhite),
          ),
        ),
      );

  Widget _buildJoinButton(BuildContext context) {
    if (canAccess) {
      return ElevatedButton.icon(
        onPressed: () async {
          final userRole = await AuthService().getUserRole();
          final receiverId = userRole == 'psychiatrist'
              ? widget.patientId
              : widget.psychiatristId;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ConsultationLauncherScreen(
                peerId: receiverId.toString(),
                peerName: widget.name,
                appointmentId: widget.id,
                mode: 'chat',
              ),
            ),
          );
        },
        icon: const Icon(Icons.chat, color: Colors.white),
        label: const Text(
          "Rejoindre la consultation",
          style: TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      return const Text(
        "Disponible à l'heure du rendez-vous",
        style: TextStyle(color: Colors.grey),
      );
    }
  }
}
