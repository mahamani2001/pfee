import 'package:flutter/material.dart';
import 'package:mypsy_app/screens/layouts/top_bar_subpage.dart';
import 'package:mypsy_app/shared/routes.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
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
        title: 'Detail',
        goHome: true,
      ),
      body: SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ✅ Photo statique
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage("assets/images/psy.jpg"),
            ),
            const SizedBox(height: 16),

            // ✅ Nom + spécialité + ville
            Text(
              psychiatrist['full_name'] ?? 'Nom inconnu',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),

            const SizedBox(height: 4),

            const SizedBox(height: 24),

            // ✅ Informations statiques
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12.withOpacity(0.05), blurRadius: 6),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      InfoItem(icon: Icons.star, label: "4.8", sub: "Avis"),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on,
                          size: 20, color: Color(0xFF6B7280)), // gris foncé
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          psychiatrist['adresse'] ?? 'Adresse non renseignée',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(
                                0xFF374151), // gris très foncé / quasi noir
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Icon(Icons.info_outline,
                          size: 18, color: Colors.blueGrey),
                      SizedBox(width: 8),
                      Text("À propos ",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    psychiatrist['description'] ??
                        "Je vous accompagne avec écoute et bienveillance.Chaque pas compte vers une vie plus apaisée.",
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.medical_services,
                                size: 20, color: Color(0xFF457B9D)),
                            SizedBox(width: 8),
                            Text(
                              "Spécialités",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Chip(
                          label: Text(
                            psychiatrist['specialty'] ?? 'Psychiatre',
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: const Color(0xFFDCEFFF),
                          labelStyle: const TextStyle(color: Color(0xFF457B9D)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: const [],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      )),
      bottomNavigationBar: Padding(
        padding:
            const EdgeInsets.fromLTRB(50, 0, 24, 24), // ⬅ remonte le bouton
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
