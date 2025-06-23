import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mypsy_app/resources/services/appointment_service.dart';
import 'package:mypsy_app/screens/layouts/top_bar_subpage.dart';
import 'package:mypsy_app/shared/routes.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:mypsy_app/shared/ui/alert.dart';
import 'package:mypsy_app/shared/ui/buttons/button.dart';
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
    final dayOfWeek = DateFormat('EEEE', 'fr_FR').format(_selectedDay!);

    try {
      final reserved =
          await AppointmentService().getReservedTimes(psychiatristId, dateStr);
      //print('🔒 Heures déjà réservées : $reserved');

      final available =
          await AppointmentService().getMyAvailiblity(psychiatristId);

      List<String> times = [];

      available!.forEach((jour, horaires) {
        if (dayOfWeek.toLowerCase() == jour.toLowerCase()) {
          for (var h in horaires) {
            final parts = h.split('-');
            final startTime = parts[0];
            if (!reserved.contains(startTime)) {
              times.add(startTime);
            }
          }
        }
      });

      setState(() {
        reservedTimes = reserved;
        availableTimes = times;
        timeToAvailabilityId = {};
      });
    } catch (e) {
      print("❌ Erreur chargement créneaux: $e");
    }
  }

  Widget verifyBeforeConfirm() {
    String date = '';
    if (_selectedDay != null) {
      date = DateFormat('dd/MM/yyyy').format(_selectedDay!);
    }
    return AlertYesNo(
      title: "Confirmer le rendez-vous",
      description:
          "Souhaitez-vous confirmer le rendez-vous le [$date à $_selectedTime] ",
      btnTitle: "Oui",
      btnNoTitle: "Non",
      onClosePopup: () {
        setState(() {
          Navigator.pop(context);
        });
      },
      onPressYes: () {
        confirmAppointment();
        Navigator.pop(context);
      },
    );
  }

  Future<void> confirmAppointment() async {
    if (_selectedDay == null || _selectedTime == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    final hourStr = _selectedTime!.split(":")[0].padLeft(2, '0');
    final minuteStr = _selectedTime!.split(":")[1].padLeft(2, '0');
    final formattedStartTime = "$hourStr:$minuteStr";

    bool success = false;

    if (appointmentId != null) {
      success = await AppointmentService().rescheduleAppointment(
        appointmentId: appointmentId!,
        date: dateStr,
        startTime: formattedStartTime,
      );
    } else if (availableTimes.contains(formattedStartTime)) {
      final result = await AppointmentService().reserveAppointment(
        psychiatristId: psychiatristId,
        date: dateStr,
        startTime: formattedStartTime,
        durationMinutes: 30,
        availabilityId: timeToAvailabilityId[formattedStartTime],
      );

      if (result['status'] == 201) {
        success = true;
      } else if (result['status'] == 409) {
        final errorBody = result['body'];
        final errorMessage = errorBody['message'];
        final conflictingTime = errorBody['conflictingTime'] ?? _selectedTime;

        String dialogMessage;
        if (errorMessage == "Tu as déjà un autre rendez-vous à ce moment.") {
          dialogMessage =
              "❗ Tu as déjà un autre rendez-vous à $conflictingTime.\n\nVeuillez choisir une autre heure.";
        } else if (errorMessage == "Ce créneau est déjà réservé.") {
          dialogMessage =
              "❗ Ce créneau vient d’être réservé par un autre utilisateur.\n\nVeuillez choisir un autre horaire.";
        } else {
          dialogMessage = "Une erreur est survenue. Veuillez réessayer.";
        }

        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                SizedBox(width: 8),
                Text(
                  "Conflit détecté",
                  style: AppThemes.appbarTitleStyle,
                ),
              ],
            ),
            content: Text(
              dialogMessage,
              style: AppThemes.getTextStyle(size: 14),
            ),
            actions: [
              TextButton(
                child: const Text("OK",
                    style: TextStyle(color: Colors.deepPurple)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );

        return;
      }
    } else {
      final result = await AppointmentService().proposeCustomAppointment(
        psychiatristId: psychiatristId,
        date: dateStr,
        startTime: formattedStartTime,
        durationMinutes: 30,
      );

      if (result == true) {
        success = true;
      } else {
        final resultCheck = await AppointmentService().reserveAppointment(
          psychiatristId: psychiatristId,
          date: dateStr,
          startTime: formattedStartTime,
          durationMinutes: 30,
        );

        if (resultCheck['status'] == 409) {
          final errorMessage = resultCheck['body']['message'];
          final conflictingTime =
              resultCheck['body']['conflictingTime'] ?? _selectedTime;

          String dialogMessage;
          if (errorMessage == "Tu as déjà un autre rendez-vous à ce moment.") {
            dialogMessage =
                "❗ Tu as déjà un autre rendez-vous à $conflictingTime.\n\nVeuillez choisir une autre heure.";
          } else if (errorMessage == "Ce créneau est déjà réservé.") {
            dialogMessage =
                "❗Tu as déjà un autre rendez-vous à ce moment.\n\nVeuillez choisir un autre horaire.";
          } else {
            dialogMessage = "Une erreur est survenue. Veuillez réessayer.";
          }

          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text(
                    "Déjà réservé",
                    style: AppThemes.appbarSubPageTitleStyle,
                  ),
                ],
              ),
              content: Text(
                dialogMessage,
                style: AppThemes.getTextStyle(size: 14),
              ),
              actions: [
                mypsyButton(
                  text: 'OK',
                  bgColors: AppColors.mypsySecondary,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  onPress: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );

          return;
        }
      }
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
              locale: 'fr_FR',
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 600)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              onDaySelected: (selected, focused) async {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                  _selectedTime = null;
                  availableTimes = [];
                });

                await loadTimesForDate();
              },
              calendarStyle: CalendarStyle(
                defaultTextStyle: AppThemes.getTextStyle(),
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
              Text(
                "Choisir une heure disponible :",
                style: AppThemes.getTextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (availableTimes.isNotEmpty)
                selectTimingUI()
              else
                Text(
                  "Aucune disponibilité, proposez une heure personnalisée.",
                  style: AppThemes.getTextStyle(),
                ),
              const SizedBox(height: 5),
              OutlinedButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text(
                  "Proposer une heure personnalisée",
                  style: AppThemes.getTextStyle(),
                ),
                onPressed: () {
                  showCustomTimePicker(context, (pickedTime) {
                    print("Time selected: ${pickedTime.format(context)}");
                    setState(() {
                      _selectedTime = pickedTime.format(context);
                    });
                  });
                },
                /*  onPressed: () async {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      _selectedTime = pickedTime.format(context);
                    });
                  }
                }, */
              ),
              const SizedBox(height: 10),
              mypsyButton(
                onPress: _selectedTime == null
                    ? null
                    : () {
                        showDialog(
                            context: context,
                            builder: (context) => verifyBeforeConfirm());
                      },
                text: appointmentId != null
                    ? "Reprogrammer le rendez-vous"
                    : "Prendre un rendez-vous",
              ),
            ]
          ],
        ),
      ));
  Widget selectTimingUI() => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 2.2,
        children: availableTimes.map((time) {
          final isSelected = _selectedTime == time;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTime = time;
              });
            },
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color:
                    isSelected ? AppColors.mypsyPrimary : AppColors.mypsyWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.mypsyPrimary : Colors.black26,
                  width: 0.5,
                ),
              ),
              child: Text(time,
                  style: AppThemes.getTextStyle(
                    clr: isSelected ? Colors.white : Colors.black,
                  )),
            ),
          );
        }).toList(),
      );
}

void showCustomTimePicker(
  BuildContext context,
  Function(TimeOfDay) onTimePicked,
) {
  final List<int> allowedMinutes = [0, 15, 30];

  final now = TimeOfDay.now();
  final int initialHour = now.hour;

  // Round current minutes to the nearest valid option
  int roundedMinute = allowedMinutes.reduce(
      (a, b) => (now.minute - a).abs() < (now.minute - b).abs() ? a : b);

  int selectedHour = initialHour;
  int selectedMinute = roundedMinute;

  int initialMinuteIndex = allowedMinutes.indexOf(roundedMinute);

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    backgroundColor: Colors.white,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => SizedBox(
        height: 300,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Sélectionner une heure',
                  style: TextStyle(fontSize: 18)),
            ),
            Expanded(
              child: Row(
                children: [
                  // Hour picker
                  Expanded(
                    child: CupertinoPicker(
                      scrollController:
                          FixedExtentScrollController(initialItem: initialHour),
                      itemExtent: 40,
                      onSelectedItemChanged: (value) {
                        setState(() => selectedHour = value);
                      },
                      children: List.generate(
                          24,
                          (index) => Center(
                              child: Text(index.toString().padLeft(2, '0')))),
                    ),
                  ),
                  const Text(":", style: TextStyle(fontSize: 24)),
                  // Minute picker
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                          initialItem: initialMinuteIndex),
                      itemExtent: 40,
                      onSelectedItemChanged: (value) {
                        setState(() => selectedMinute = allowedMinutes[value]);
                      },
                      children: allowedMinutes
                          .map((min) => Center(
                              child: Text(min.toString().padLeft(2, '0'))))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    child: Text("Annuler"),
                    onPressed: () => Navigator.pop(context),
                  ),
                  ElevatedButton(
                    child: Text("OK"),
                    onPressed: () {
                      onTimePicked(TimeOfDay(
                          hour: selectedHour, minute: selectedMinute));
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    ),
  );
}
