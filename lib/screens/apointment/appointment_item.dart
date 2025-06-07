import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mypsy_app/resources/services/appointment_service.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/screens/consultation/ConsultationLauncherScreen.dart';
import 'package:mypsy_app/shared/routes.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:mypsy_app/shared/ui/buttons/button.dart';
import 'package:mypsy_app/utils/functions.dart';

class AppointmentCard extends StatefulWidget {
  final int id;
  final int psychiatristId;
  final int patientId;
  final String name;
  final String time;
  final String date;
  final String status;
  final String userRole;
  final VoidCallback onReload;

  const AppointmentCard({
    super.key,
    required this.id,
    required this.psychiatristId,
    required this.patientId,
    required this.name,
    required this.time,
    required this.date,
    required this.status,
    required this.userRole,
    required this.onReload,
  });

  @override
  State<AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<AppointmentCard> {
  bool canAccess = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkAccess();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _checkAccess());
  }

  Future<void> _checkAccess() async {
    final access = await AppointmentService().checkAccess(widget.id);
    if (mounted) {
      setState(() {
        canAccess = access;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFr = formatDateFr(widget.date);
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          const BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            image: const DecorationImage(
                                image: AssetImage("assets/images/psy.jpg")),
                            color: AppColors.mypsyPrimary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: AppColors.mypsyPrimary.withOpacity(0.2),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.name,
                                style: AppThemes.getTextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.medical_services_outlined,
                                    size: 14, color: AppColors.mypsySecondary),
                                const SizedBox(width: 5),
                                Text(
                                  "specilaite",
                                  style: AppThemes.getTextStyle(
                                    size: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 14, color: AppColors.mypsySecondary),
                                const SizedBox(width: 5),
                                Text(
                                  "$dateFr à ${widget.time}",
                                  style: AppThemes.getTextStyle(
                                      size: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(
            color: AppColors.mypsyDarkBlue.withOpacity(0.2),
          ),
          Row(children: _buildActionButtons(context)),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(BuildContext context) {
    if (widget.userRole == 'psychiatrist' && widget.status == 'pending') {
      return [
        _button(context, 'Confirmer', Colors.green, () async {
          await AppointmentService().confirmAppointment(widget.id);
          widget.onReload();
        }),
        const SizedBox(width: 8),
        _button(context, 'Rejeter', Colors.red, () async {
          await AppointmentService().rejectAppointment(widget.id);
          widget.onReload();
        }),
      ];
    } else if (widget.status == 'pending' || widget.status == 'confirmed') {
      return [
        _button(context, 'Reprogrammer', AppColors.mypsyDarkBlue, () async {
          await Navigator.pushNamed(context, Routes.booking, arguments: {
            'psychiatristId': widget.psychiatristId,
            'appointmentId': widget.id,
          });
          widget.onReload();
        }),
        const SizedBox(width: 8),
        _button(context, 'Annuler', Colors.red, isOutline: true, () async {
          await AppointmentService().cancelAppointment(widget.id);
          widget.onReload();
        }),
      ];
    }
    return [];
  }

  Widget _button(BuildContext context, String text, Color color,
          VoidCallback onPressed,
          {bool isOutline = false}) =>
      Expanded(
        child: mypsyButton(
          text: text,
          onPress: onPressed,
          bgColors: color,
          isFull: true,
          btnType: isOutline ? BtnType.outline : BtnType.filled,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
        ),
      );

  Widget _buildJoinButton(BuildContext context) {
    if (widget.status == 'cancelled') {
      return const SizedBox();
    }

    if (canAccess) {
      return ElevatedButton.icon(
        onPressed: () async {
          final userRole = await AuthService().getUserRole();
          final receiverId = userRole == 'psychiatrist'
              ? widget.patientId
              : widget.psychiatristId;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ConsultationLauncherScreen(
                peerId: receiverId.toString(),
                peerName: widget.name,
                appointmentId: widget.id,
                mode: 'chat',
              ),
            ),
          );
        },
        icon: const Icon(Icons.chat, color: Colors.white),
        label: const Text(
          "Rejoindre la consultation",
          style: TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      return const Text(
        "Disponible à l'heure du rendez-vous",
        style: TextStyle(color: Colors.grey),
      );
    }
  }
}
