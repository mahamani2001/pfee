import 'package:flutter/material.dart';
import 'package:mypsy_app/resources/services/NotificationService.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> notifications = [];

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    final data = await NotificationService().getMyNotifications();
    setState(() => notifications = data);
  }

  Future<void> markAsRead(int id) async {
    await NotificationService().markAsRead(id);
    loadNotifications();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Notifications")),
        body: ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notif = notifications[index];
            final isUnread = notif['status'] == 'unread';
            return ListTile(
              title: Text(notif['title']),
              subtitle: Text(notif['body']),
              trailing: isUnread
                  ? IconButton(
                      icon: const Icon(Icons.mark_email_read),
                      onPressed: () => markAsRead(notif['id']),
                    )
                  : null,
              tileColor: isUnread ? Colors.teal.shade50 : null,
            );
          },
        ),
      );
}
