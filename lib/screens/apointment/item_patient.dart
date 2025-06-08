import 'package:flutter/material.dart';

import 'package:mypsy_app/shared/routes.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';

class PatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;

  const PatientCard({
    super.key,
    required this.patient,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            Routes.patientInfo,
            arguments: {'patient': patient},
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.mypsyWhite,
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
              SizedBox(
                width: MediaQuery.of(context).size.width - 150,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(left: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(patient['full_name'] ?? 'Nom inconnu',
                              style: AppThemes.getTextStyle(
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(
                            height: 7,
                          ),
                          Text(
                            patient['specialty'] ?? 'Psychiatre',
                            style: AppThemes.getTextStyle(
                                size: 11, clr: AppColors.mypsyBlack),
                          ),
                          const SizedBox(
                            height: 7,
                          ),
                          timingAdress()
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget timingAdress() => Row(
        children: [
          const Icon(Icons.location_on,
              size: 16, color: AppColors.mypsySecondary),
          const SizedBox(width: 4),
          Text(
            patient['adresse'] ?? 'Adresse non renseignée',
            overflow: TextOverflow.ellipsis,
            style:
                AppThemes.getTextStyle(size: 12, fontWeight: FontWeight.w500),
          ),
        ],
      );
}
