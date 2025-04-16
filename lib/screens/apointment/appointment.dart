import 'package:flutter/material.dart';
import 'package:mypsy_app/resources/services/appointment_service.dart';
import 'package:mypsy_app/screens/consultation/chatconsultation.dart';
import 'package:mypsy_app/shared/routes.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:mypsy_app/utils/functions.dart'; // pour le formatage de date

// Page principale des rendez-vous
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

// Liste des rendez-vous filtrés par statut
class AppointmentList extends StatefulWidget {
  final String status;
  const AppointmentList({super.key, required this.status});

  @override
  State<AppointmentList> createState() => _AppointmentListState();
}

class _AppointmentListState extends State<AppointmentList> {
  List<dynamic> appointments = [];

  @override
  void initState() {
    super.initState();
    loadAppointments();
  }

  Future<void> loadAppointments() async {
    final data =
        await AppointmentService().getAppointmentsByStatus(widget.status);
    setState(() => appointments = data);
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
        return AppointmentCard(
          id: appt['id'],
          psychiatristId: appt['psychiatrist_id'],
          name: "Dr. ${appt['psychiatrist_name'] ?? 'Inconnu'}",
          time: appt['start_time'].toString().substring(0, 5),
          date: appt['date'],
          status: widget.status,
          onCancelled: loadAppointments,
        );
      },
    );
  }
}

// Carte de rendez-vous
class AppointmentCard extends StatelessWidget {
  final int id;
  final int psychiatristId;
  final String name;
  final String time;
  final String date;
  final String status;
  final VoidCallback onCancelled;

  const AppointmentCard({
    super.key,
    required this.id,
    required this.psychiatristId,
    required this.name,
    required this.time,
    required this.date,
    required this.status,
    required this.onCancelled,
  });

  Future<void> rescheduleAppointment(
    BuildContext context,
    int appointmentId,
    String date,
    String startTime,
  ) async {
    try {
      final success = await AppointmentService().rescheduleAppointment(
        appointmentId: appointmentId,
        date: date,
        startTime: startTime,
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Rendez-vous reprogrammé avec succès")),
        );
        onCancelled();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de la reprogrammation")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur de connexion")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFr = formatDateFr(date);
    final cardColor = status == 'cancelled'
        ? Colors.red[50]
        : status == 'pending'
            ? Colors.orange[50]
            : Colors.white;

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.account_circle, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (status == 'pending')
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text("En attente de confirmation",
                      style: TextStyle(fontSize: 12)),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text("$dateFr | $time",
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),

            /// Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (status == 'confirmed') ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          Routes.booking,
                          arguments: {
                            'psychiatristId': psychiatristId,
                            'appointmentId': id,
                          },
                        );
                        if (result == true) onCancelled();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mypsyDarkBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Reprogrammer",
                          style: TextStyle(color: AppColors.mypsyBgApp)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Confirmation"),
                            content: const Text(
                                "Souhaitez-vous annuler ce rendez-vous ?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Non"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Oui"),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          final success =
                              await AppointmentService().cancelAppointment(id);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text("Rendez-vous annulé avec succès")),
                            );
                            onCancelled();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Erreur lors de l’annulation")),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Annuler",
                          style: TextStyle(color: AppColors.mypsyBgApp)),
                    ),
                  ),
                ],
                if (status == 'pending' || status == 'cancelled') ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          Routes.booking,
                          arguments: {
                            'psychiatristId': psychiatristId,
                            'appointmentId': id,
                          },
                        );
                        if (result == true) onCancelled();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mypsyDarkBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Reprogrammer",
                          style: TextStyle(color: AppColors.mypsyBgApp)),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            /// Bouton "Rejoindre" si consultation active
            FutureBuilder<bool>(
              future: AppointmentService().checkAccess(id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox();
                }
                if (snapshot.hasData && snapshot.data == true) {
                  return ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            peerId: psychiatristId.toString(),
                            peerName: name,
                            appointmentId: id,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text("Rejoindre la consultation"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                } else {
                  return const Text(
                    "Disponible à l’heure du rendez-vous",
                    style: TextStyle(color: Colors.grey),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
