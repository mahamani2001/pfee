import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:mypsy_app/resources/services/NotificationService.dart';
import 'package:mypsy_app/resources/services/appointment_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> notifications = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    // Initialize timezone database
    tz.initializeTimeZones();
    _markAllAndFetch();
  }

  Future<bool> requestCalendarPermission() async {
    var status = await Permission.calendarFullAccess.status;
    if (!status.isGranted) {
      status = await Permission.calendarFullAccess.request();
    }
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Accès au calendrier requis")),
      );
      return false;
    }
    return true;
  }

  Future<void> _markAllAndFetch() async {
    try {
      await NotificationService().markAllAsRead();
      final notifList = await NotificationService().getMyNotifications();

      final futures = notifList.map((notif) async {
        final isConfirmed =
            (notif['title'] ?? '').toLowerCase().contains("confirm");
        final appointmentId = notif['appointment_id'];

        if (isConfirmed && appointmentId != null) {
          try {
            final appointment =
                await AppointmentService().getAppointmentById(appointmentId);
            notif['appointment_data'] = appointment;
          } catch (e) {
            print("⚠️ Erreur chargement appointment ID $appointmentId : $e");
          }
        }
        return notif;
      }).toList();

      final enrichedNotifs = await Future.wait(futures);

      setState(() {
        notifications = enrichedNotifs;
        loading = false;
      });
    } catch (e) {
      print("❌ Erreur chargement notifications : $e");
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Mes notifications")),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : notifications.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("Aucune notification"),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      final createdAt = DateTime.parse(notif['created_at']);
                      final isConfirmed = (notif['title'] ?? '')
                          .toLowerCase()
                          .contains("confirm");

                      DateTime? start;
                      String? formattedDateTime;
                      final appointment = notif['appointment_data'];

                      if (isConfirmed && appointment != null) {
                        final dateStr = appointment['date'];
                        final timeStr = appointment['start_time'];
                        final int durationMinutes =
                            appointment['duration_minutes'] ?? 30;

                        try {
                          if (dateStr != null && timeStr != null) {
                            start = DateFormat('yyyy-MM-dd HH:mm')
                                .parse('$dateStr $timeStr');
                            formattedDateTime =
                                DateFormat('dd/MM/yyyy à HH:mm').format(start);
                          } else {
                            throw const FormatException(
                                "Date ou heure manquante");
                          }
                        } catch (e) {
                          print("⚠️ Erreur parsing date/heure: $e");
                        }
                      }

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.notifications,
                                    color: notif['status'] == 'unread'
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      notif['title'] ?? 'Notification',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Text(
                                    DateFormat('dd/MM HH:mm').format(createdAt),
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (isConfirmed) ...[
                                Text(
                                  "Super nouvelle ! ${notif['body']}",
                                  style: const TextStyle(color: Colors.green),
                                ),
                                if (formattedDateTime != null &&
                                    start != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    "📅 Rendez-vous le $formattedDateTime",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        if (start == null) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    "Données de rendez-vous invalides")),
                                          );
                                          return;
                                        }

                                        if (!(await requestCalendarPermission())) {
                                          return;
                                        }

                                        try {
                                          final deviceCalendarPlugin =
                                              DeviceCalendarPlugin();
                                          final calendarsResult =
                                              await deviceCalendarPlugin
                                                  .retrieveCalendars();
                                          if (!calendarsResult.isSuccess ||
                                              calendarsResult.data == null) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      "Erreur : impossible de récupérer les calendriers")),
                                            );
                                            return;
                                          }

                                          final calendar =
                                              calendarsResult.data!.firstWhere(
                                            (cal) => cal.isReadOnly == false,
                                            orElse: () => throw Exception(
                                                "Aucun calendrier inscriptible trouvé"),
                                          );

                                          final psychiatristName =
                                              appointment['psychiatristName'] ??
                                                  "votre psychiatre";
                                          final int durationMinutes =
                                              appointment['duration_minutes'] ??
                                                  30;

                                          final event = Event(
                                            calendar.id,
                                            title:
                                                'Consultation avec $psychiatristName',
                                            description:
                                                'Consultation psychiatrique en ligne avec $psychiatristName via MyPsy',
                                            location: 'En ligne - MyPsy',
                                            start: tz.TZDateTime.from(
                                                start, tz.local),
                                            end: tz.TZDateTime.from(
                                                start.add(Duration(
                                                    minutes: durationMinutes)),
                                                tz.local),
                                            reminders: [Reminder(minutes: 15)],
                                          );

                                          final createEventResult =
                                              await deviceCalendarPlugin
                                                  .createOrUpdateEvent(event);
                                          if (createEventResult?.isSuccess ??
                                              false) {
                                            setState(() {
                                              notif['addedToCalendar'] = true;
                                            });
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      "✅ Ajouté au calendrier")),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      "Erreur : événement non ajouté. Vérifiez votre calendrier par défaut.")),
                                            );
                                          }
                                        } catch (e) {
                                          print("❌ Erreur calendrier : $e");
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    "Erreur ajout calendrier")),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                      child: notif['addedToCalendar'] == true
                                          ? const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.check, size: 16),
                                                SizedBox(width: 4),
                                                Text("Ajouté"),
                                              ],
                                            )
                                          : const Text("Ajouter"),
                                    ),
                                  ),
                                ],
                              ] else
                                Text(notif['body'] ?? ''),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      );
}
