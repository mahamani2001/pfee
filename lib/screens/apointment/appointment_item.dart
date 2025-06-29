import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mypsy_app/resources/services/appointment_service.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/resources/services/consultation_service.dart';
import 'package:mypsy_app/screens/consultation/ConsultationLauncherScreen.dart';
import 'package:mypsy_app/screens/consultation/ConsultationLauncherScreenPsy.dart';
import 'package:mypsy_app/shared/routes.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:mypsy_app/shared/ui/alert.dart';
import 'package:mypsy_app/shared/ui/buttons/button.dart';
import 'package:mypsy_app/utils/constants.dart';
import 'package:mypsy_app/utils/functions.dart';
import 'package:mypsy_app/shared/ui/device_types.dart';

class AppointmentCard extends StatefulWidget {
  final int id;
  final int psychiatristId;
  final int patientId;
  final String name;
  final String time;
  final String date;
  final String status;
  final String userRole;
  final String specialite;
  final VoidCallback onReload;
  final dynamic appt;
  final bool canJoin;
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
    required this.appt,
    required this.canJoin,
    required this.specialite,
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
    print(' let s get access from ${widget.id}');
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
  Widget build(BuildContext context) => widget.userRole == 'psychiatrist'
      ? GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              Routes.patientInfo,
              arguments: {
                'patient': {
                  ...widget.appt,
                  'appointment_id': widget.id, // ✅ injecté dans patient
                },
              },
            );
          },
          child: cardInfo(widget.userRole))
      : cardInfo(widget.userRole);

  Widget cardInfo(String userRole) {
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
                            if (widget.userRole != PSY_ROLE)
                              Row(
                                children: [
                                  const Icon(Icons.medical_services_outlined,
                                      size: 14,
                                      color: AppColors.mypsySecondary),
                                  const SizedBox(width: 5),
                                  Text(
                                    widget.specialite != null
                                        ? widget.specialite
                                        : '',
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
                            if (widget.status == 'pending')
                              Container(
                                margin: const EdgeInsets.only(top: 5),
                                child: Row(
                                  children: [
                                    const Icon(Icons.hourglass_top,
                                        size: 14, color: AppColors.mypsyOrange),
                                    const SizedBox(width: 5),
                                    Text(
                                      "En attente de confirmation",
                                      style: AppThemes.getTextStyle(
                                          size: 11,
                                          clr: AppColors.mypsyOrange,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            if (widget.status == 'confirmed')
                              Container(
                                margin: const EdgeInsets.only(top: 5),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        size: 14, color: AppColors.mypsyGreen),
                                    const SizedBox(width: 5),
                                    Text(
                                      "Confirmer",
                                      style: AppThemes.getTextStyle(
                                          size: 11,
                                          clr: AppColors.mypsyGreen,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              )
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: _buildActionButtons(context, userRole)),
              const SizedBox(height: 5),
              _buildJoinButton(context),
            ],
          ),
        ],
      ),
    );
  }

  void confirmRdv() {
    final dateFr = formatDateFr(widget.date);
    showDialog(
        context: context,
        builder: (context) => AlertYesNo(
            title: "Confirmation? ",
            description:
                "Voulez-vous confirmer ce RDV\n[$dateFr à ${widget.time}]?",
            btnTitle: "Oui",
            btnNoTitle: "Annuler",
            onPressYes: () async {
              await AppointmentService().confirmAppointment(widget.id);
              Navigator.pop(context);
              widget.onReload();
            },
            onClosePopup: () {
              Navigator.pop(context);
            }));
  }

  void alertRejectWithReason() {
    final TextEditingController reasonController = TextEditingController();
    final dateFr = formatDateFr(widget.date);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.mypsyWhite,
        contentPadding: const EdgeInsets.all(0),
        title: Text(
          "Rejeter le rendez-vous",
          style: AppThemes.getTextStyle(fontWeight: FontWeight.w500, size: 16),
          textAlign: TextAlign.center,
        ),
        content: Container(
          width:
              Device.get().isTablet! ? 400 : MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.mypsyWhite,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Rendez-vous le $dateFr à ${widget.time}",
                style: AppThemes.getTextStyle(
                    fontWeight: FontWeight.w700, size: 13),
              ),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: "Cause du refus",
                  hintText: "Ex: Je ne suis pas disponible",
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: mypsyButton(
                  text: 'Annuler',
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  onPress: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: mypsyButton(
                  text: 'Rejeter',
                  bgColors: AppColors.mypsySecondary,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  onPress: () async {
                    final reason = reasonController.text.trim();
                    if (reason.isEmpty) return;

                    final success = await AppointmentService()
                        .rejectAppointment(widget.id, reason);
                    Navigator.pop(context); // Fermer la boîte

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Rendez-vous rejeté ❌")),
                      );
                      widget.onReload(); // Recharger la liste
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Erreur lors du rejet")),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void alertAnnulerPatient() {
    final dateFr = formatDateFr(widget.date);
    showDialog(
        context: context,
        builder: (context) => AlertYesNo(
            title: "Annuler? ",
            description:
                "Voulez-vous annuler cette demande \n $dateFr à ${widget.time}?",
            btnTitle: "Oui",
            btnNoTitle: "Non",
            onPressYes: () async {
              await AppointmentService().cancelAppointment(widget.id);
              Navigator.pop(context);
              widget.onReload();
            },
            onClosePopup: () {
              Navigator.pop(context);
            }));
  }

  List<Widget> _buildActionButtons(BuildContext context, String userRole) {
    if (widget.userRole == 'psychiatrist' && widget.status == 'pending') {
      return [
        _button(context, 'Confirmer', Colors.green, () async {
          confirmRdv();
        }),
        const SizedBox(width: 8),
        _button(context, 'Rejeter', Colors.red, () async {
          alertRejectWithReason();
        }),
      ];
    } else if (widget.status == 'confirmed' && canAccess) {
      // ✅ Si l'accès est dispo → ne pas afficher d'autres boutons
      return [];
    } else if ((widget.status == 'pending' || widget.status == 'confirmed') &&
        userRole != 'psychiatrist') {
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
          alertAnnulerPatient();
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
    int? consultationId;
    String? type;
    if (widget.status == 'cancelled') {
      return const SizedBox();
    }

    print('canAccess ----> $canAccess');

    if (canAccess) {
      return ElevatedButton.icon(
        onPressed: () async {
          final userRole = await AuthService().getUserRole();
          final receiverId = userRole == 'psychiatrist'
              ? widget.patientId
              : widget.psychiatristId;
          if (userRole == 'psychiatrist') {
            final data =
                await ConsultationService().joinConsultation(widget.id);
            if (data == null)
              throw Exception("Consultation introuvable");
            else {
              print('data not null ');
            }
            final consultation = data['consultation'];
            consultationId = consultation['id'];
            print(consultationId);
            type = consultation['type'];
            print('Consulation details ${consultation}');
          }
          // Redirection dynamique en fonction du rôle
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => userRole == 'psychiatrist'
                  ? ConsultationLauncherScreenPsy(
                      peerId: receiverId.toString(),
                      peerName: widget.name,
                      appointmentId: widget.id,
                      type: type!,
                      consultId: consultationId!)
                  : ConsultationLauncherScreen(
                      peerId: receiverId.toString(),
                      peerName: widget.name,
                      appointmentId: widget.id,
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
      return Text(
        "Disponible à l'heure du rendez-vous",
        style: AppThemes.getTextStyle(clr: AppColors.mypsyGrey),
      );
    }
  }
}
