import 'package:flutter/material.dart';
import 'package:mypsy_app/screens/layouts/top_bar_subpage.dart';
import 'package:mypsy_app/shared/routes.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:mypsy_app/shared/ui/buttons/button.dart';
import 'package:mypsy_app/utils/functions.dart';

class PatientDetailScreen extends StatelessWidget {
  const PatientDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final patient = args['patient'];
    print(patient);
    final dateFr = formatDateFr(patient["date"]);
    return Scaffold(
      backgroundColor: AppColors.mypsyBgApp,
      appBar: const TopBarSubPage(
        title: 'Detail',
      ),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Column(
          children: [
            if (patient["status"] == "cancelled")
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.mypsyAlertRed,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    const BoxShadow(color: AppColors.mypsyBgApp, blurRadius: 6),
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                child: Column(
                  children: [
                    iconTitle("Cause d'annulation", Icons.info_outline,
                        colorWhite: true),
                    const SizedBox(height: 8),
                    Text(
                        patient['description'] ??
                            "Je vous accompagne avec écoute et bienveillance.Chaque pas compte vers une vie plus apaisée.",
                        style: AppThemes.getTextStyle(
                            clr: AppColors.mypsyBgApp,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: decorationUi(),
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              child: Column(
                children: [
                  iconTitle(
                    "Horaire",
                    Icons.info_outline,
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow("Date", dateFr),
                  _buildInfoRow("Time", patient["start_time"]),
                  _buildInfoRow("Durée", "${patient["duration_minutes"]} min"),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: decorationUi(),
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              child: Column(
                children: [
                  iconTitle(
                    "Informations du patient",
                    Icons.info_outline,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow("Nom", "${patient["patient_name"]}"),
                  _buildInfoRow("Age", "26 years"),
                  _buildInfoRow("Genre", "Male"),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: decorationUi(),
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              child: Column(
                children: [
                  iconTitle(
                    "Notes",
                    Icons.info_outline,
                  ),
                  const SizedBox(height: 8),
                  Text(
                      patient['description'] ??
                          "Je vous accompagne avec écoute et bienveillance.Chaque pas compte vers une vie plus apaisée.",
                      style: AppThemes.getTextStyle()),
                ],
              ),
            ),
          ],
        ),
      )),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
        child: mypsyButton(
          isFull: true,
          onPress: () {
            Navigator.pushNamed(
              context,
              Routes.booking,
              arguments: {
                'patientId': patient['id'],
              },
            );
          },
          bgColors: AppColors.mypsyDarkBlue,
          text: "Commence on ....",
        ),
      ),
    );
  }

  BoxDecoration decorationUi() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 6),
        ],
      );

  Widget _buildInfoRow(String label, String value,
          {bool isMultiline = false, Widget? trailingWidget}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: isMultiline
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 90,
              child: Text("$label :",
                  style: AppThemes.getTextStyle(
                    fontWeight: FontWeight.bold,
                  )),
            ),
            Expanded(
              child: Wrap(
                children: [
                  Text(value, style: AppThemes.getTextStyle()),
                  if (trailingWidget != null) ...[
                    const SizedBox(width: 6),
                    trailingWidget,
                  ]
                ],
              ),
            ),
          ],
        ),
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

  Widget iconTitle(String title, IconData icon, {bool colorWhite = false}) =>
      Row(
        children: [
          Icon(icon, size: 18, color: AppColors.mypsyDarkBlue),
          const SizedBox(width: 8),
          Text(title,
              style: AppThemes.getTextStyle(
                  fontWeight: FontWeight.bold,
                  clr: colorWhite
                      ? AppColors.mypsyWhite
                      : AppColors.mypsyBlack)),
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
