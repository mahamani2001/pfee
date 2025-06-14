import 'package:flutter/material.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';

class DoctorAvailiblityOld extends StatefulWidget {
  @override
  _DoctorAvailiblityOldState createState() => _DoctorAvailiblityOldState();
}

class _DoctorAvailiblityOldState extends State<DoctorAvailiblityOld> {
  final List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  Map<String, bool> daySelected = {};
  Map<String, List<String>> selectedSlots = {};

  // Time slots: from 08:00 to 20:00 in 30-min steps
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

  @override
  void initState() {
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
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text("Select slots for $day",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
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
                        padding: EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: selected ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          slot,
                          style: AppThemes.getTextStyle(
                              clr: selected ? Colors.white : Colors.black,
                              size: 11),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Done"),
              )
            ],
          ),
        ),
      ),
    );
  }

  void saveAvailability() {
    Map<String, List<String>> cleaned = {};
    selectedSlots.forEach((day, slots) {
      if (slots.isNotEmpty) {
        List<String> sorted = slots.toList()
          ..sort((a, b) => _timeToMinutes(a.split('-')[0])
              .compareTo(_timeToMinutes(b.split('-')[0])));
        cleaned[day] = sorted;
      }
    });

    print("Saved Availability:\n$cleaned");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Weekly Availability")),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          ...days.map((day) {
            final isActive = daySelected[day]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: isActive,
                      onChanged: (val) {
                        setState(() {
                          daySelected[day] = val!;
                        });
                      },
                    ),
                    Text(day,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Spacer(),
                    if (isActive)
                      TextButton(
                        onPressed: () => showSlotPicker(day),
                        child: Text("+ Add Time Slots"),
                      ),
                  ],
                ),
                if (isActive && selectedSlots[day]!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: selectedSlots[day]!
                          .map((slot) => Chip(
                                label: Text(slot),
                                onDeleted: () {
                                  setState(() {
                                    selectedSlots[day]!.remove(slot);
                                  });
                                },
                              ))
                          .toList(),
                    ),
                  ),
                Divider(),
              ],
            );
          }).toList(),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: saveAvailability,
            child: Text("Save Availability"),
          )
        ],
      ),
    );
  }
}
