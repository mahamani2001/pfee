import 'package:flutter/material.dart';
import 'package:mypsy_app/screens/layouts/page_layout.dart';
import 'package:mypsy_app/resources/services/doctor_service.dart';
import 'package:mypsy_app/shared/routes.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  Future<List<Map<String, dynamic>>> _fetchDoctors() async {
    final service = DoctorService();
    return await service.getAllPsychiatrists();
  }

  @override
  Widget build(BuildContext context) => LayoutPage(
        title: 'Home',
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchDoctors(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                  child: Text("Erreur : \${snapshot.error}",
                      style: const TextStyle(color: Colors.red)));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Aucun psychiatre trouvé."));
            }

            final doctors = snapshot.data!;

            return Column(
              children: [
                for (var i = 0; i < doctors.length; i++)
                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        Routes.doctorInfo,
                        arguments: {'psychiatrist': doctors[i]},
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: doctors[i]['image'] != null
                                ? NetworkImage(doctors[i]['image'])
                                : const AssetImage(
                                        "assets/images/doctor_avatar.png")
                                    as ImageProvider,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doctors[i]['full_name'] ?? 'Nom inconnu',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  doctors[i]['specialty'] ?? 'Psychiatre',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.orange, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                (doctors[i]['rating'] ?? 4.5).toString(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  )
              ],
            );
          },
        ),
      );
}
