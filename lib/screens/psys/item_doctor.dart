import 'package:flutter/material.dart';
import 'package:mypsy_app/resources/services/RatingService.dart';

import 'package:mypsy_app/shared/routes.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';

class DoctorCard extends StatelessWidget {
  final Map<String, dynamic> doctor;

  const DoctorCard({
    super.key,
    required this.doctor,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            Routes.doctorInfo,
            arguments: {'psychiatrist': doctor},
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
                          Text(doctor['full_name'] ?? 'Nom inconnu',
                              style: AppThemes.getTextStyle(
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(
                            height: 7,
                          ),
                          Text(
                            doctor['specialty'] ?? 'Psychiatre',
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
                    ratingUi()
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
            doctor['adresse'] ?? 'Adresse non renseignée',
            overflow: TextOverflow.ellipsis,
            style:
                AppThemes.getTextStyle(size: 12, fontWeight: FontWeight.w500),
          ),
          /*  const SizedBox(width: 10),
          const Icon(Icons.access_time,
              size: 14, color: AppColors.mypsySecondary),
          const SizedBox(width: 4),
          Text(
            '8:30 - 4:30',
            overflow: TextOverflow.ellipsis,
            style:
                AppThemes.getTextStyle(size: 12, fontWeight: FontWeight.w500),
          ),*/
        ],
      );
  Widget ratingUi() {
    return FutureBuilder<double>(
      future: RatingService().getAverageRating(doctor['id']),
      builder: (context, snapshot) {
        final rating = snapshot.data ?? 0.0;

        return Row(
          children: [
            const Icon(Icons.star, size: 18, color: Colors.orange),
            const SizedBox(width: 3),
            Text(
              rating.toStringAsFixed(1),
              style:
                  AppThemes.getTextStyle(size: 11, fontWeight: FontWeight.w500),
            ),
          ],
        );
      },
    );
  }
}
