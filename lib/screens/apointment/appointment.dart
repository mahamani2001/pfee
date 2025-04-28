import 'package:flutter/material.dart';
import 'package:mypsy_app/resources/services/appointment_service.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/screens/chat/ConsultationLauncherScreen.dart';
import 'package:mypsy_app/shared/routes.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:mypsy_app/utils/functions.dart';

class Appointment extends StatelessWidget {
  const Appointment({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            centerTitle: false,
            title: Text("Mes rendez-vous", style: AppThemes.appbarTitleStyle),
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            elevation: 0,
            bottom: const TabBar(
              labelColor: AppColors.mypsyDarkBlue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.mypsyDarkBlue,
              tabs: [
                Tab(text: 'À venir'),
                Tab(text: 'En attente'),
                Tab(text: 'Annulé'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              AppointmentList(status: 'confirmed'),
              AppointmentList(status: 'pending'),
              AppointmentList(status: 'cancelled'),
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
    final data =
        await AppointmentService().getAppointmentsByStatus(widget.status);
    final role = await AuthService().getUserRole();
    setState(() {
      appointments = data;
      userRole = role;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return const Center(
        child: Text("Aucun rendez-vous",
            style: TextStyle(color: Colors.grey, fontSize: 16)),
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

class AppointmentCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final dateFr = formatDateFr(date);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, size: 40),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text("$dateFr à $time",
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            Row(children: _buildActionButtons(context)),
            const SizedBox(height: 12),
            _buildJoinButton(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(BuildContext context) {
    if (userRole == 'psychiatrist' && status == 'pending') {
      return [
        _button(context, 'Confirmer', Colors.green, () async {
          await AppointmentService().confirmAppointment(id);
          onReload();
        }),
        const SizedBox(width: 8),
        _button(context, 'Rejeter', Colors.red, () async {
          await AppointmentService().rejectAppointment(id);
          onReload();
        }),
      ];
    } else if (status == 'pending' || status == 'confirmed') {
      return [
        _button(context, 'Reprogrammer', AppColors.mypsyDarkBlue, () async {
          await Navigator.pushNamed(context, Routes.booking, arguments: {
            'psychiatristId': psychiatristId,
            'appointmentId': id,
          });
          onReload();
        }),
        const SizedBox(width: 8),
        _button(context, 'Annuler', Colors.red, () async {
          await AppointmentService().cancelAppointment(id);
          onReload();
        }),
      ];
    } else if (status == 'cancelled') {
      if (userRole == 'patient') {
        return [
          _button(context, 'Reprogrammer', AppColors.mypsyDarkBlue, () async {
            await Navigator.pushNamed(context, Routes.booking, arguments: {
              'psychiatristId': psychiatristId,
              'appointmentId': id,
            });
            onReload();
          }),
        ];
      } else {
        return []; // Psy : pas de bouton reprogrammer
      }
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
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(text, style: const TextStyle(color: Colors.white)),
        ),
      );

  Widget _buildJoinButton(BuildContext context) {
    if (status == 'cancelled') {
      return const SizedBox(); // Si annulé, ne rien afficher du tout
    }

    return FutureBuilder<bool>(
      future: AppointmentService().checkAccess(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }
        if (snapshot.data == true) {
          return ElevatedButton.icon(
            onPressed: () async {
              final userRole = await AuthService().getUserRole();
              final receiverId =
                  userRole == 'psychiatrist' ? patientId : psychiatristId;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConsultationLauncherScreen(
                    peerId: receiverId.toString(),
                    peerName: name,
                    appointmentId: id,
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
        }
        return const Text(
          "Disponible à l'heure du rendez-vous",
          style: TextStyle(color: Colors.grey),
        );
      },
    );
  }
}
