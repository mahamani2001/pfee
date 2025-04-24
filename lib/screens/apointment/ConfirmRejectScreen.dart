// Nouvelle page pour confirmer ou rejeter un rendez-vous

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mypsy_app/resources/services/appointment_service.dart';
import 'package:mypsy_app/resources/services/http_service.dart';
import 'package:mypsy_app/resources/services/socket_service.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/resources/services/crypto_service.dart';
import 'package:mypsy_app/resources/services/chat_service.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/utils/functions.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ConfirmRejectScreen extends StatelessWidget {
  final int appointmentId;
  final String patientName;
  final String date;
  final String time;
  final VoidCallback onActionCompleted;

  const ConfirmRejectScreen({
    super.key,
    required this.appointmentId,
    required this.patientName,
    required this.date,
    required this.time,
    required this.onActionCompleted,
  });

  Future<void> confirmAppointment(BuildContext context) async {
    final success =
        await AppointmentService().confirmAppointment(appointmentId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rendez-vous confirmé ✅")),
      );
      onActionCompleted(); // Recharger la liste
      Navigator.pop(context); // Retourner à la liste
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la confirmation")),
      );
    }
  }

  Future<void> rejectAppointment(BuildContext context) async {
    final success = await AppointmentService().rejectAppointment(appointmentId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rendez-vous rejeté ❌")),
      );
      onActionCompleted(); // Recharger la liste
      Navigator.pop(context); // Retourner à la liste
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors du rejet")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFr = formatDateFr(date);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirmer ou Rejeter"),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.mypsyDarkBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Détails du rendez-vous",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.mypsyDarkBlue,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_circle, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            patientName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          "$dateFr | $time",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => confirmAppointment(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Confirmer",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => rejectAppointment(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Rejeter",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
