import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mypsy_app/resources/services/NotificationService.dart';
import 'package:mypsy_app/resources/services/appointment_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mypsy_app/screens/calendar/GoogleCalendarHelper.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> notifications = [];
  bool loading = true;
  bool isGoogleAuthenticated = false;
  final GoogleCalendarHelper _googleCalendarHelper = GoogleCalendarHelper();

  @override
  void initState() {
    super.initState();
    _markAllAndFetch();
    _checkGoogleAuthStatus();
  }

  Future<void> _checkGoogleAuthStatus() async {
    final isSignedIn = await _googleCalendarHelper.isSignedIn();
    setState(() {
      isGoogleAuthenticated = isSignedIn;
    });
  }

  Future<void> _markAllAndFetch() async {
    try {
      setState(() => loading = true);
      await NotificationService().markAllAsRead();
      final notifList = await NotificationService().getMyNotifications();

      final futures = notifList.map((notif) async {
        if (notif['type'] == 'confirmed' && notif['appointment_id'] != null) {
          try {
            final appointment = await AppointmentService()
                .getAppointmentById(notif['appointment_id']);
            notif['appointment_data'] = appointment;
          } catch (e) {
            print(
                "⚠️ Erreur chargement appointment ID ${notif['appointment_id']} : $e");
          }
        }
        return notif;
      }).toList();

      final enrichedNotifs = await Future.wait(futures);

      // Filter out expired appointments for confirmed notifications
      final now = DateTime.now();
      final filteredNotifs = enrichedNotifs.where((notif) {
        if (notif['type'] == 'confirmed' && notif['appointment_data'] != null) {
          final appointment = notif['appointment_data'];
          final dateStr = appointment['date'];
          final timeStr = appointment['start_time'];
          final start = parseAppointmentDateTime(dateStr, timeStr);
          return start == null || start.isAfter(now);
        }
        return true; // Keep reminder and cancellation notifications
      }).toList();

      setState(() {
        notifications = filteredNotifs;
        loading = false;
      });
    } catch (e) {
      print("❌ Erreur chargement notifications : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Erreur lors du chargement des notifications")),
      );
      setState(() => loading = false);
    }
  }
  Future<void> _clearAllNotifications() async {
    try {
      setState(() => loading = true);
      await NotificationService().clearAllNotifications();
      setState(() {
        notifications = [];
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Toutes les notifications ont été supprimées")),
      );
    } catch (e) {
      print("❌ Erreur suppression notifications : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Erreur lors de la suppression des notifications")),
      );
      setState(() => loading = false);
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      setState(() => loading = true);
      await NotificationService().deleteNotification(id);
      await _markAllAndFetch();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Notification supprimée")),
      );
    } catch (e) {
      print("❌ Erreur suppression notification : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la suppression")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  DateTime? parseAppointmentDateTime(String? dateStr, String? timeStr) {
    if (dateStr == null || timeStr == null) return null;
    try {
      return DateFormat('yyyy-MM-dd HH:mm').parse('$dateStr $timeStr');
    } catch (e) {
      print("⚠️ Erreur parsing date/heure: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text("Mes notifications"),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _markAllAndFetch,
              tooltip: 'Rafraîchir',
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: notifications.isEmpty
                  ? null
                  : () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Supprimer tout"),
                          content: const Text(
                              "Voulez-vous supprimer toutes les notifications ?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Annuler"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _clearAllNotifications();
                              },
                              child: const Text("Supprimer"),
                            ),
                          ],
                        ),
                      );
                    },
              tooltip: 'Supprimer tout',
            ),
          ],
        ),
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
                : RefreshIndicator(
                    onRefresh: _markAllAndFetch,
                    child: ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notif = notifications[index];
                        final createdAt = DateTime.parse(notif['created_at']);
                        final notificationType = notif['type'];

                        DateTime? start;
                        String? formattedDateTime;
                        String? psychiatristName;
                        final appointment = notif['appointment_data'];

                        if (notificationType == 'confirmed' &&
                            appointment != null) {
                          final dateStr = appointment['date'];
                          final timeStr = appointment['start_time'];
                          psychiatristName =
                              "Dr. ${appointment['full_name'] ?? 'psychiatre'}";

                          final int durationMinutes =
                              appointment['duration_minutes'] ?? 30;
                          start = parseAppointmentDateTime(dateStr, timeStr);
                          if (start != null) {
                            formattedDateTime =
                                DateFormat('dd/MM/yyyy à HH:mm').format(start);
                          }
                        }

                        return AnimatedOpacity(
                          opacity: 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: Card(
                            elevation: 3,
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
                                        notificationType == 'confirmed'
                                            ? Icons.check_circle
                                            : notificationType == 'cancellation'
                                                ? Icons.cancel
                                                : Icons.alarm,
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
                                        DateFormat('dd/MM HH:mm')
                                            .format(createdAt),
                                        style: const TextStyle(
                                            fontSize: 11, color: Colors.grey),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red, size: 20),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text("Supprimer ?"),
                                              content: const Text(
                                                  "Voulez-vous supprimer cette notification ?"),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text("Annuler"),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    _deleteNotification(
                                                        notif['id'].toString());
                                                  },
                                                  child:
                                                      const Text("Supprimer"),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    notificationType == 'confirmed' &&
                                            psychiatristName != null
                                        ? 'Votre rendez-vous a été confirmé par le $psychiatristName.'
                                        : notif['body'] ?? '',
                                    style: TextStyle(
                                      color: notificationType == 'confirmed'
                                          ? Colors.green
                                          : notificationType == 'cancellation'
                                              ? Colors.red
                                              : Colors.blue,
                                    ),
                                  ),
                                  if (notificationType == 'confirmed' &&
                                      appointment != null) ...[
                                    if (psychiatristName != null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          "👨‍⚕️ Avec $psychiatristName",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    if (formattedDateTime != null &&
                                        start != null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          "📅 Rendez-vous le $formattedDateTime",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: isGoogleAuthenticated
                                          ? ElevatedButton(
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

                                                try {
                                                  final int durationMinutes =
                                                      appointment[
                                                              'duration_minutes'] ??
                                                          30;

                                                  final success =
                                                      await _googleCalendarHelper
                                                          .addEventToGoogleCalendar(
                                                    title:
                                                        'Consultation avec $psychiatristName',
                                                    description:
                                                        'Consultation psychiatrique en ligne via MyPsy',
                                                    location: 'En ligne',
                                                    start: start,
                                                    end: start.add(Duration(
                                                        minutes:
                                                            durationMinutes)),
                                                  );

                                                  if (success) {
                                                    setState(() {
                                                      notif['addedToCalendar'] =
                                                          true;
                                                    });
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content: Text(
                                                              "Événement ajouté à Google Agenda")),
                                                    );
                                                  }
                                                } catch (e) {
                                                  print(
                                                      "❌ Erreur ajout Google Agenda : $e");
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                        content: Text(
                                                            "Erreur lors de l'ajout à Google Agenda")),
                                                  );
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8)),
                                              ),
                                              child: notif['addedToCalendar'] ==
                                                      true
                                                  ? const Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.check,
                                                            size: 16),
                                                        SizedBox(width: 4),
                                                        Text("Ajouté"),
                                                      ],
                                                    )
                                                  : const Text(
                                                      "Ajouter à Google Agenda"),
                                            )
                                          : ElevatedButton(
                                              onPressed: () async {
                                                try {
                                                  final success =
                                                      await _googleCalendarHelper
                                                          .signIn();
                                                  if (success) {
                                                    setState(() {
                                                      isGoogleAuthenticated =
                                                          true;
                                                    });
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content: Text(
                                                              "Connexion à Google Agenda réussie")),
                                                    );
                                                  }
                                                } catch (e) {
                                                  print(
                                                      "❌ Erreur connexion Google Agenda : $e");
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                        content: Text(
                                                            "Erreur lors de la connexion à Google Agenda")),
                                                  );
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8)),
                                              ),
                                              child: const Text(
                                                  "Connecter Google Agenda"),
                                            ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      );
}
