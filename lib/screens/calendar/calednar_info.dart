import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mypsy_app/resources/services/appointment_service.dart';
import 'package:mypsy_app/screens/layouts/top_bar_subpage.dart';
import 'package:mypsy_app/shared/routes.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedTime;
  List<String> availableTimes = [];
  List<String> reservedTimes = [];
  List<String> allTimes = [];
  late int psychiatristId;
  int? appointmentId;
  Map<String, int> timeToAvailabilityId = {};
  @override
  void initState() {
    super.initState();
    allTimes = [
      ...generateTimeSlots(start: "09:00", end: "12:15", stepMinutes: 45),
      ...generateTimeSlots(start: "14:00", end: "17:15", stepMinutes: 45),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    psychiatristId = args['psychiatristId'];
    appointmentId = args['appointmentId'];
  }

  List<String> generateTimeSlots({
    required String start,
    required String end,
    int stepMinutes = 30,
  }) {
    final format = DateFormat("HH:mm");
    final startTime = format.parse(start);
    final endTime = format.parse(end);
    final List<String> slots = [];

    for (var t = startTime;
        t.isBefore(endTime);
        t = t.add(Duration(minutes: stepMinutes))) {
      slots.add(format.format(t));
    }

    return slots;
  }

  Future<void> loadTimesForDate() async {
    if (_selectedDay == null) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    print('📅 Date sélectionnée (Flutter) : $dateStr');

    try {
      final reserved =
          await AppointmentService().getReservedTimes(psychiatristId, dateStr);
      print('🔒 Heures déjà réservées : $reserved');

      final available =
          await AppointmentService().getAvailabilities(psychiatristId);
      print('✅ Disponibilités récupérées du backend :');
      for (var a in available) {
        print(
            '  → id=${a['availability_id']} | date=${a['date']} | start=${a['start_time']}');
      }

      final availableFiltered = available.where((a) {
        final dateFromApi = DateTime.parse(a['date']).toLocal();
        final formattedDate = DateFormat('yyyy-MM-dd').format(dateFromApi);
        return formattedDate == dateStr;
      }).toList();

      final times = <String>[];
      final map = <String, int>{};

      for (var a in availableFiltered) {
        final time = a['start_time'].toString().substring(0, 5);
        times.add(time);
        map[time] = a['availability_id'];
      }

      setState(() {
        reservedTimes = reserved;
        availableTimes = times;
        timeToAvailabilityId = map;
      });
    } catch (e) {
      print("❌ Erreur chargement créneaux: $e");
    }
  }

  Future<void> confirmAppointment() async {
    if (_selectedDay == null || _selectedTime == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);

    // On convertit le time formaté Flutter → format HH:mm
    final timeOfDay = TimeOfDay(
      hour: int.parse(_selectedTime!.split(":")[0]),
      minute: int.parse(_selectedTime!.split(":")[1]),
    );
    final startTime = timeOfDay.format(context); // e.g. 14:30
    final hourStr = timeOfDay.hour.toString().padLeft(2, '0');
    final minuteStr = timeOfDay.minute.toString().padLeft(2, '0');
    final formattedStartTime = "$hourStr:$minuteStr";

    bool success = false;

    // Cas 1 : Reprogrammation
    if (appointmentId != null) {
      success = await AppointmentService().rescheduleAppointment(
        appointmentId: appointmentId!,
        date: dateStr,
        startTime: formattedStartTime,
      );
    }

    // Cas 2 : Créneau proposé par le psychiatre
    else if (availableTimes.contains(formattedStartTime)) {
      final result = await AppointmentService().reserveAppointment(
        psychiatristId: psychiatristId,
        date: dateStr,
        startTime: formattedStartTime,
        durationMinutes: 30,
        availabilityId: timeToAvailabilityId[formattedStartTime], // 👈
      );
      success = result['status'] == 201;
    }

    // Cas 3 : Heure personnalisée (non dans les créneaux)
    else {
      success = await AppointmentService().proposeCustomAppointment(
        psychiatristId: psychiatristId,
        date: dateStr,
        startTime: formattedStartTime,
        durationMinutes: 30,
      );
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(appointmentId != null
            ? "Rendez-vous reprogrammé avec succès"
            : "Rendez-vous réservé avec succès"),
      ));
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.appointmentSuccess,
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Erreur lors de la réservation"),
      ));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.mypsyBgApp,
      appBar: TopBarSubPage(
        title: appointmentId != null
            ? "Reprogrammer le rendez-vous"
            : "Prendre rendez-vous",
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 60)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              onDaySelected: (selected, focused) async {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                  _selectedTime = null;
                  availableTimes = []; // ✅ Reset pour forcer la reconstruction
                });

                await loadTimesForDate(); // ✅ après setState
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.mypsyDarkBlue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_selectedDay != null) ...[
              const Text(
                "Choisir une heure disponible :",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              if (availableTimes.isNotEmpty)
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: availableTimes.map((time) {
                    final isSelected = _selectedTime == time;
                    return ChoiceChip(
                      label: Text(time),
                      selected: isSelected,
                      selectedColor: AppColors.mypsyDarkBlue,
                      onSelected: (_) => setState(() => _selectedTime = time),
                    );
                  }).toList(),
                )
              else
                const Text(
                    "Aucune disponibilité. Proposez une heure personnalisée."),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.access_time),
                label: const Text("Proposer une heure personnalisée"),
                onPressed: () async {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      _selectedTime = pickedTime.format(context);
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed:
                    _selectedTime == null ? null : () => confirmAppointment(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mypsyPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  appointmentId != null
                      ? "Reprogrammer le rendez-vous"
                      : "Prendre un rendez-vous",
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ]
          ],
        ),
      ));
}
