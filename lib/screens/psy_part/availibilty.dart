import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class DoctorAvailiblity extends StatefulWidget {
  @override
  _DoctorAvailiblityState createState() => _DoctorAvailiblityState();
}

class _DoctorAvailiblityState extends State<DoctorAvailiblity> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<String, List<String>> availability = {};
  List<String> timeSlots = [];
  String? rangeStart;

  @override
  void initState() {
    super.initState();
    _generateTimeSlots();
  }

  void _generateTimeSlots() {
    for (int hour = 8; hour < 20; hour++) {
      timeSlots.add('${_format(hour)}:00-${_format(hour)}:30');
      timeSlots.add('${_format(hour)}:30-${_format(hour + 1)}:00');
    }
  }

  String _format(int hour) => hour.toString().padLeft(2, '0');

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  void selectRangeSlot(String slot) {
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    final slots = availability.putIfAbsent(dateKey, () => []);

    if (rangeStart == null) {
      setState(() => rangeStart = slot);
    } else {
      final startIndex = timeSlots.indexOf(rangeStart!);
      final endIndex = timeSlots.indexOf(slot);
      if (startIndex == -1 || endIndex == -1) return;

      final from = startIndex < endIndex ? startIndex : endIndex;
      final to = startIndex > endIndex ? startIndex : endIndex;

      for (int i = from; i <= to; i++) {
        if (!slots.contains(timeSlots[i])) {
          slots.add(timeSlots[i]);
        }
      }

      slots.sort((a, b) => _timeToMinutes(a.split('-')[0])
          .compareTo(_timeToMinutes(b.split('-')[0])));

      setState(() => rangeStart = null);
    }
  }

  void saveAvailability() {
    print("\u2705 Final availability:");
    availability.forEach((date, slots) => print("$date: $slots"));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Availability saved.")));
  }

  void showWeeklyRangeDialog() {
    TimeOfDay? start;
    TimeOfDay? end;
    Map<String, bool> dayChecked = {
      'Monday': false,
      'Tuesday': false,
      'Wednesday': false,
      'Thursday': false,
      'Friday': false,
      'Saturday': false,
      'Sunday': false,
    };

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text("Add Weekly Time Range"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    child: Text(start != null
                        ? "Start: ${start!.format(context)}"
                        : "Select Start Time"),
                    onPressed: () async {
                      final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(hour: 8, minute: 0));
                      if (picked != null) setState(() => start = picked);
                    },
                  ),
                  TextButton(
                    child: Text(end != null
                        ? "End: ${end!.format(context)}"
                        : "Select End Time"),
                    onPressed: () async {
                      final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(hour: 9, minute: 0));
                      if (picked != null) setState(() => end = picked);
                    },
                  ),
                  Divider(),
                  Text("Select Days"),
                  ...dayChecked.keys.map((day) {
                    return CheckboxListTile(
                      value: dayChecked[day],
                      title: Text(day),
                      onChanged: (val) =>
                          setState(() => dayChecked[day] = val!),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: Text("Apply"),
                onPressed: () {
                  if (start != null && end != null) {
                    applyWeeklyRange(start!, end!, dayChecked);
                    Navigator.pop(context);
                  }
                },
              )
            ],
          ),
        );
      },
    );
  }

  void applyWeeklyRange(
      TimeOfDay start, TimeOfDay end, Map<String, bool> selectedDays) {
    final allSlots = timeSlots;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    for (var entry in selectedDays.entries) {
      if (!entry.value) continue;

      final day = entry.key;
      final dateList = _generateUpcomingDatesForWeekday(day);

      for (final date in dateList) {
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        final slotList = availability.putIfAbsent(dateKey, () => []);

        for (final slot in allSlots) {
          final from = _timeToMinutes(slot.split('-')[0]);
          final to = _timeToMinutes(slot.split('-')[1]);

          if (from >= startMinutes && to <= endMinutes) {
            if (!slotList.contains(slot)) slotList.add(slot);
          }
        }

        slotList.sort((a, b) => _timeToMinutes(a.split('-')[0])
            .compareTo(_timeToMinutes(b.split('-')[0])));
      }
    }

    setState(() {});
  }

  List<DateTime> _generateUpcomingDatesForWeekday(String weekday) {
    final weekdayMap = {
      'Monday': DateTime.monday,
      'Tuesday': DateTime.tuesday,
      'Wednesday': DateTime.wednesday,
      'Thursday': DateTime.thursday,
      'Friday': DateTime.friday,
      'Saturday': DateTime.saturday,
      'Sunday': DateTime.sunday,
    };

    int targetWeekday = weekdayMap[weekday]!;
    List<DateTime> matchingDates = [];
    DateTime today = DateTime.now();

    for (int i = 0; i < 14; i++) {
      final date = today.add(Duration(days: i));
      if (date.weekday == targetWeekday) {
        matchingDates.add(date);
      }
    }

    return matchingDates;
  }

  @override
  Widget build(BuildContext context) {
    final String selectedDateStr = _selectedDay != null
        ? DateFormat('yyyy-MM-dd').format(_selectedDay!)
        : '';

    return Scaffold(
      appBar: AppBar(title: Text("Select Available Ranges")),
      body: Column(
        children: [
          ElevatedButton.icon(
            onPressed: showWeeklyRangeDialog,
            icon: Icon(Icons.schedule),
            label: Text("Add Weekly Time Range"),
          ),
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(Duration(days: 60)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            calendarStyle: CalendarStyle(
              selectedDecoration:
                  BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
              todayDecoration:
                  BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
            ),
          ),
          if (_selectedDay != null) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Tap to select a start & end time for ${DateFormat.yMMMMd().format(_selectedDay!)}",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                padding: EdgeInsets.all(12),
                children: timeSlots.map((slot) {
                  final isSelected =
                      availability[selectedDateStr]?.contains(slot) ?? false;
                  final isStart = rangeStart == slot;
                  return GestureDetector(
                    onTap: () => selectRangeSlot(slot),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isStart
                            ? Colors.orange
                            : isSelected
                                ? Colors.blue
                                : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        slot,
                        style: TextStyle(
                          color: isSelected || isStart
                              ? Colors.white
                              : Colors.black,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text("Select a date to add availability."),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: saveAvailability,
              icon: Icon(Icons.save),
              label: Text("Save Availability"),
              style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(48)),
            ),
          ),
        ],
      ),
    );
  }
}
