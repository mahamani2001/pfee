import 'package:flutter/material.dart';
import 'package:mypsy_app/resources/services/doctor_service.dart';
import 'package:mypsy_app/screens/layouts/top_bar_subpage.dart';
import 'package:mypsy_app/screens/psys/item_doctor.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';

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
        backgroundColor: AppColors.mypsyBgApp,
        appBar: const TopBarSubPage(
          title: 'Trouver un professionnel',
          goHome: true,
        ),
        body: SafeArea(
            child: allDoctors.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            hintText: "Rechercher un psychiatre...",
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 20,
                              color: AppColors.mypsyDarkBlue,
                            ),
                            filled: true,
                            fillColor: AppColors.mypsyDarkBlue.withOpacity(0.1),
                            hintStyle: AppThemes.getTextStyle(size: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
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
                            /* Text('Spécialité : ',
                                style: AppThemes.getTextStyle(
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),*/
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.mypsyDarkBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedSpecialty,
                                  isExpanded: true,
                                  icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded),
                                  dropdownColor:
                                      const Color.fromARGB(255, 255, 255, 255),
                                  style: const TextStyle(
                                      fontSize: 15, color: Colors.black87),
                                  hint: Text('Toutes les spécialités',
                                      style: AppThemes.getTextStyle(size: 16)),
                                  borderRadius: BorderRadius.circular(12),
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: null,
                                      child: Text('Toutes les spécialités',
                                          style:
                                              AppThemes.getTextStyle(size: 14)),
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
                          itemBuilder: (context, index) =>
                              DoctorCard(doctor: filteredDoctors[index]),
                        ),
                      )
                    ],
                  )),
      );
}
