import 'package:flutter/material.dart';
import 'package:mypsy_app/screens/layouts/top_bar_subpage.dart';
import 'package:mypsy_app/screens/psys/item_doctor.dart';
import 'package:mypsy_app/shared/routes.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:mypsy_app/shared/ui/buttons/button.dart';

class DoctorDetailScreen extends StatelessWidget {
  const DoctorDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final psychiatrist = args['psychiatrist'];

    return Scaffold(
      backgroundColor: AppColors.mypsyBgApp,
      appBar: const TopBarSubPage(
        title: 'Détail',
      ),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Column(
          children: [
            DoctorCard(
              doctor: psychiatrist,
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12.withOpacity(0.05), blurRadius: 6),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              child: Column(
                children: [
                  experienceUi(psychiatrist),
                  const SizedBox(height: 20),
                  iconTitle(
                    "À propos",
                    Icons.info_outline,
                  ),
                  const SizedBox(height: 8),
                  Text(
                      psychiatrist['description'] ??
                          "Je vous accompagne avec écoute et bienveillance.Chaque pas compte vers une vie plus apaisée.",
                      style: AppThemes.getTextStyle()),
                  const SizedBox(height: 20),
                  availiblityUi(),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      )),
      bottomNavigationBar: Padding(
        padding:
            const EdgeInsets.fromLTRB(24, 10, 24, 24), // ⬅ remonte le bouton
        child: mypsyButton(
          isFull: true,
          onPress: () {
            Navigator.pushNamed(
              context,
              Routes.booking,
              arguments: {
                'psychiatristId': psychiatrist['id'],
              },
            );
          },
          bgColors: AppColors.mypsyDarkBlue,
          text: "Prendre rendez-vous",
        ),
      ),
    );
  }

  Widget experienceUi(psychiatrist) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First column: Specialties
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                iconTitle(
                  "Spécialités",
                  Icons.medical_services_outlined,
                ),
                Chip(
                  padding: const EdgeInsets.all(0),
                  label: Text(
                    psychiatrist['specialty'] ?? 'Psychiatre',
                    style: AppThemes.getTextStyle(
                        size: 11, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: AppColors.mypsyBgApp,
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.grey[300],
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                iconTitle(
                  "Expérience",
                  Icons.work,
                ),
                const SizedBox(height: 8),
                Text(
                  psychiatrist['experience'],
                  style: AppThemes.getTextStyle(
                      size: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      );

  Widget availiblityUi() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          iconTitle(
            "Horaires de travail",
            Icons.access_time,
          ),
          const SizedBox(height: 8),
          Divider(
            color: AppColors.mypsyDarkBlue.withOpacity(0.2),
          ),
          ...[
            'Lundi',
            'Mardi',
            'Mercredi',
            'Jeudi',
            'Venredi',
            'Samedi',
          ].map((day) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(day, style: AppThemes.getTextStyle(size: 13)),
                    Row(
                      children: [
                        Text("00:00", style: AppThemes.getTextStyle()),
                        Text(" - ",
                            style: AppThemes.getTextStyle(
                                size: 15, clr: AppColors.mypsyDarkBlue)),
                        Text("00:00", style: AppThemes.getTextStyle()),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      );

  Widget iconTitle(String title, IconData icon) => Row(
        children: [
          Icon(icon, size: 18, color: AppColors.mypsyDarkBlue),
          const SizedBox(width: 8),
          Text(title,
              style: AppThemes.getTextStyle(fontWeight: FontWeight.bold)),
        ],
      );
}

class InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;

  const InfoItem(
      {required this.icon, required this.label, required this.sub, super.key});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, size: 24, color: Colors.teal),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      );
}
