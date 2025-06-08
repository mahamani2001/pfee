import 'package:flutter/material.dart';
import 'package:mypsy_app/screens/apointment/item_patient.dart';
import 'package:mypsy_app/screens/layouts/top_bar_subpage.dart';
import 'package:mypsy_app/screens/psys/item_doctor.dart';
import 'package:mypsy_app/shared/routes.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:mypsy_app/shared/ui/buttons/button.dart';

class PatientDetailScreen extends StatelessWidget {
  const PatientDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final patient = args['patient'];

    return Scaffold(
      backgroundColor: AppColors.mypsyBgApp,
      appBar: const TopBarSubPage(
        title: 'Detail',
      ),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Column(
          children: [
            PatientCard(
              patient: patient,
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
                  iconTitle(
                    "À propos",
                    Icons.info_outline,
                  ),
                  const SizedBox(height: 8),
                  Text(
                      patient['description'] ??
                          "Je vous accompagne avec écoute et bienveillance.Chaque pas compte vers une vie plus apaisée.",
                      style: AppThemes.getTextStyle()),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            const SizedBox(height: 100),
            _buildSectionTitle("Appointment Schedule"),
            _buildInfoRow("Date", "23 September 2023"),
            _buildInfoRow("Time", "05 : 30 PM"),
            Divider(height: 32),
            _buildSectionTitle("Patient Details"),
            _buildInfoRow("Name", "Akash basak"),
            _buildInfoRow("Age", "26 years"),
            _buildInfoRow("Gender", "Male"),
            _buildInfoRow(
              "Problem",
              "Lorem ipsum dolor sit amet consectetur. Donec duis faucibus vitae",
              isMultiline: true,
              trailingWidget: Text(
                "See more",
                style: TextStyle(color: Colors.teal),
              ),
            ),
            Divider(height: 32),
            _buildSectionTitle("General Instructions"),
            _buildInstruction(
                "Start meeting with a stable internet connection"),
            _buildInstruction("Avoid low light rooms for better observation"),
            _buildInstruction("Talk to Doctor loud and clear"),
            _buildInstruction("Ensure a quiet environment during the session"),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isMultiline = false, Widget? trailingWidget}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment:
            isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              "$label :",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Wrap(
              children: [
                Text(
                  value,
                  style: TextStyle(color: Colors.black87),
                ),
                if (trailingWidget != null) ...[
                  SizedBox(width: 6),
                  trailingWidget,
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

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
