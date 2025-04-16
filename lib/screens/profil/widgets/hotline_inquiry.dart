import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:flutter/material.dart';

class HotlineInquiry extends StatelessWidget {
  const HotlineInquiry({super.key});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.mypsyPrimary,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            buildInfo(),
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(5),
                bottomRight: Radius.circular(10),
              ),
              child: Image.asset(
                width: 150,
                'assets/journee-accompagnement.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      );

  Widget buildInfo() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vous disposez de',
            style: AppThemes.getTextStyle(
                clr: AppColors.mypsyWhite,
                size: 16,
                fontWeight: FontWeight.w500),
          ),
          Text(
            '4 demi-journées',
            style: AppThemes.getTextStyle(
              clr: AppColors.mypsyWhite,
              size: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'd’accompagnement',
            style: AppThemes.getTextStyle(
              clr: AppColors.mypsyWhite,
              size: 13,
            ),
          ),
        ],
      );
}
