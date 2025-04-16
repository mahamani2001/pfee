import 'package:flutter/material.dart';
import 'package:mypsy_app/resources/services/doctor_service.dart';
import 'package:mypsy_app/shared/routes.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';

class DoctorDetailScreen extends StatelessWidget {
  const DoctorDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final psychiatrist = args['psychiatrist'];

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  /* child: Image.network(
                    psychiatrist['image'] ?? '',
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                  ),*/
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(psychiatrist['full_name'] ?? '',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(psychiatrist['specialty'] ?? 'Psychiatre',
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(psychiatrist['adresse'] ?? '',
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text("A propos:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              psychiatrist['description'] ??
                  "Ce psychiatre est disponible pour consultation...",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            final availabilityList =
                // await DoctorService().getAvailabilities(psychiatrist['id']);

                Navigator.pushNamed(
              context,
              Routes.booking,
              arguments: {
                'psychiatristId': psychiatrist['id'], // ✅ passe bien l'ID ici
              },
            );
            Navigator.pushNamed(
              context,
              Routes.booking,
              arguments: {
                'psychiatristId': psychiatrist['id'],
              },
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.mypsyPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text("Prendre rendez-vous",
              style: TextStyle(fontSize: 16, color: AppColors.mypsyWhite)),
        ),
      ),
    );
  }
}
