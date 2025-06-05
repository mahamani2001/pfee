import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mypsy_app/resources/services/appointment_service.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/screens/consultation/ConsultationLauncherScreen.dart';
import 'package:mypsy_app/screens/layouts/main_screen.dart';
import 'package:mypsy_app/screens/layouts/top_bar_subpage.dart';
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MainScreen(initialTabIndex: 0),
                  ),
                );
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
                  'Annulé',
                  style: AppThemes.appbarSubPageTitleStyle,
                )),
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
      return Center(
        child: Text("Aucun rendez-vous",
            style: AppThemes.getTextStyle(clr: Colors.grey, size: 16)),
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

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
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
                    child: Text(widget.name,
                        style: AppThemes.getTextStyle(
                            fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: AppColors.mypsySecondary),
                const SizedBox(width: 8),
                Text("$dateFr à ${widget.time}",
                    style: AppThemes.getTextStyle(clr: Colors.grey)),
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
    } else if (widget.status == 'cancelled') {
      if (widget.userRole == 'patient') {
        return [
          _button(context, 'Reprogrammer', AppColors.mypsyDarkBlue, () async {
            await Navigator.pushNamed(context, Routes.booking, arguments: {
              'psychiatristId': widget.psychiatristId,
              'appointmentId': widget.id,
            });
            widget.onReload();
          }),
        ];
      } else {
        return [];
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
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: Text(
            text,
            style: AppThemes.getTextStyle(clr: AppColors.mypsyWhite),
          ),
        ),
      );

  Widget _buildJoinButton(BuildContext context) {
    if (widget.status == 'cancelled') {
      return const SizedBox();
    }

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
