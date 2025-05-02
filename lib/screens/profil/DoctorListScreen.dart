import 'package:flutter/material.dart';
import 'package:mypsy_app/resources/services/doctor_service.dart';
import 'package:mypsy_app/shared/routes.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/screens/layouts/page_layout.dart';

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({super.key});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  List<Map<String, dynamic>> allDoctors = [];
  List<Map<String, dynamic>> filteredDoctors = [];
  final TextEditingController _searchController = TextEditingController();
  String? selectedSpecialty;
  List<String> specialties = [];

  Future<void> fetchDoctors() async {
    final doctors = await DoctorService().getAllPsychiatrists();
    final uniqueSpecialties =
        {...doctors.map((doc) => doc['specialty'] ?? 'Psychiatre')}.toList();

    setState(() {
      allDoctors = doctors;
      filteredDoctors = doctors;
      specialties = uniqueSpecialties.cast<String>();
    });
  }

  @override
  void initState() {
    super.initState();
    fetchDoctors();
    _searchController.addListener(_filterDoctors);
  }

  void _filterDoctors() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      filteredDoctors = allDoctors.where((doc) {
        final nameMatch =
            (doc['full_name'] ?? '').toString().toLowerCase().contains(query);
        final specialtyMatch = selectedSpecialty == null ||
            (doc['specialty'] ?? 'Psychiatre') == selectedSpecialty;
        return nameMatch && specialtyMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Trouver un professionnel')),
        body: allDoctors.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Rechercher un psychiatre...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Spécialité',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12.withOpacity(0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedSpecialty,
                              isExpanded: true,
                              icon:
                                  const Icon(Icons.keyboard_arrow_down_rounded),
                              dropdownColor: Colors.white,
                              style: const TextStyle(
                                  fontSize: 15, color: Colors.black87),
                              hint: const Text('Toutes les spécialités'),
                              borderRadius: BorderRadius.circular(12),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Toutes les spécialités'),
                                ),
                                ...specialties
                                    .map((spec) => DropdownMenuItem<String>(
                                          value: spec,
                                          child: Text(spec),
                                        )),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  selectedSpecialty = value;
                                });
                                _filterDoctors();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredDoctors.length,
                      itemBuilder: (context, index) {
                        final doctor = filteredDoctors[index];
                        return InkWell(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              Routes.doctorInfo,
                              arguments: {'psychiatrist': doctor},
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 30,
                                  backgroundImage: AssetImage("assets/psy.jpg"),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doctor['full_name'] ?? 'Nom inconnu',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Chip(
                                        label: Text(
                                          doctor['specialty'] ?? 'Psychiatre',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        backgroundColor: Colors.blue.shade50,
                                        labelStyle:
                                            const TextStyle(color: Colors.blue),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on,
                                              size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              doctor['adresse'] ??
                                                  'Adresse non renseignée',
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.star,
                                            size: 18, color: Colors.orange),
                                        SizedBox(width: 3),
                                        Text("4.5",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Icon(Icons.favorite_border,
                                        color: Colors.grey),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
      );
}
