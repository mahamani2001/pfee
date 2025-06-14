import 'package:flutter/material.dart';
import 'package:mypsy_app/resources/services/appointment_service.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/screens/layouts/main_screen_psy.dart';
import 'package:mypsy_app/screens/layouts/top_bar_subpage.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:mypsy_app/shared/ui/buttons/button.dart';
import 'package:mypsy_app/shared/ui/flushbar.dart';
import 'package:mypsy_app/utils/functions.dart';

class DoctorAvailiblity extends StatefulWidget {
  const DoctorAvailiblity({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DoctorAvailiblityState createState() => _DoctorAvailiblityState();
}

class _DoctorAvailiblityState extends State<DoctorAvailiblity> {
  bool ispressed = false;
  Map<String, List<String>> cleaned = {};
  final List<String> days = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche'
  ];

  Map<String, bool> daySelected = {};
  Map<String, List<String>> selectedSlots = {};
  List<String> get timeSlots {
    List<String> slots = [];
    for (int hour = 8; hour < 20; hour++) {
      slots.add(
          '${hour.toString().padLeft(2, '0')}:00-${hour.toString().padLeft(2, '0')}:30');
      slots.add(
          '${hour.toString().padLeft(2, '0')}:30-${(hour + 1).toString().padLeft(2, '0')}:00');
    }
    return slots;
  }

  Future<void> loadAvailiblity() async {
    final int? userId = await AuthService().getUserId();
    if (userId != null) {
      final data = await AppointmentService().getMyAvailiblity(userId!);

      print(data);
      setState(() {});
      if (data != null) {
        data.forEach((day, slots) {
          if (slots.isNotEmpty) {
            List<String> sorted = slots.toList()
              ..sort((a, b) => _timeToMinutes(a.split('-')[0])
                  .compareTo(_timeToMinutes(b.split('-')[0])));
            cleaned[day] = sorted;
          }
        });
      }
    }
  }

  @override
  void initState() {
    loadAvailiblity();
    super.initState();
    for (var day in days) {
      daySelected[day] = false;
      selectedSlots[day] = [];
    }
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  void showSlotPicker(String day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) => Container(
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text("Sélectionnez des créneaux pour $day",
                  style: AppThemes.getTextStyle(
                      size: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 15),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: timeSlots.map((slot) {
                    final selected = selectedSlots[day]!.contains(slot);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (selected) {
                            selectedSlots[day]!.remove(slot);
                          } else {
                            selectedSlots[day]!.add(slot);
                          }
                          selectedSlots[day] = selectedSlots[day]!.toList()
                            ..sort((a, b) {
                              // Extract the start times
                              final startA = a.split('-').first;
                              final startB = b.split('-').first;
                              return _timeToMinutes(startA)
                                  .compareTo(_timeToMinutes(startB));
                            });
                        });
                        // Update UI inside modal too
                        setModalState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.mypsyDarkBlue
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          formatedSlot(slot),
                          style: AppThemes.getTextStyle(
                              clr: selected ? Colors.white : Colors.black,
                              size: 11,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              mypsyButton(
                onPress: () => Navigator.pop(context),
                text: "Enregistrer",
                padding: const EdgeInsets.symmetric(horizontal: 10),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> saveAvailability() async {
    setState(() {
      ispressed = true;
    });

    selectedSlots.forEach((day, slots) {
      if (slots.isNotEmpty) {
        List<String> sorted = slots.toList()
          ..sort((a, b) => _timeToMinutes(a.split('-')[0])
              .compareTo(_timeToMinutes(b.split('-')[0])));
        cleaned[day] = sorted;
      }
    });

    final result = await AppointmentService().setAvailiblity(
      slots: cleaned,
    );
    setState(() {
      ispressed = false;
    });
    if (result) {
      customFlushbar(
        '',
        'Avilibilty enregistrer avec success',
        context,
      );
      Future.delayed(const Duration(seconds: 2), () async {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MainScreenPsy(initialTabIndex: 0),
          ),
        );
      });
    } else {
      customFlushbar('', 'Erreur lors de la confirmation', context,
          isError: true);
    }

    print("Saved Availability:\n$cleaned");
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const TopBarSubPage(
          title: "Horaires disponibles",
          goHome: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...days.map((day) {
              final isActive = daySelected[day]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        checkColor: AppColors.mypsyBgApp,
                        value: isActive,
                        onChanged: (val) {
                          setState(() {
                            daySelected[day] = val!;
                          });
                        },
                      ),
                      Text(day,
                          style: AppThemes.getTextStyle(
                            fontWeight: FontWeight.bold,
                          )),
                      const Spacer(),
                      if (isActive)
                        TextButton(
                          onPressed: () => showSlotPicker(day),
                          child: Text("+ Ajouter des créneaux",
                              style: AppThemes.getTextStyle(
                                  size: 13,
                                  fontWeight: FontWeight.w600,
                                  clr: AppColors.mypsyDarkBlue)),
                        ),
                    ],
                  ),
                  if (isActive && selectedSlots[day]!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: selectedSlots[day]!
                            .map((slot) => Chip(
                                  label: Text(
                                    slot,
                                    style: AppThemes.getTextStyle(
                                      size: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  onDeleted: () {
                                    setState(() {
                                      selectedSlots[day]!.remove(slot);
                                    });
                                  },
                                ))
                            .toList(),
                      ),
                    ),
                  const Divider(
                    color: AppColors.mypsyBorderLogo,
                    thickness: 0.2,
                  ),
                ],
              );
            }).toList(),
            const SizedBox(
              height: 30,
            ),
            mypsyButton(
              onPress: ispressed ? null : saveAvailability,
              text: "Save Availability",
              withLoader: ispressed,
            )
          ],
        ),
      );
}
