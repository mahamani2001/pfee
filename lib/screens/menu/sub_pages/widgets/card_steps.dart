import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:mypsy_app/shared/ui/commun_widget.dart';
import 'package:flutter/material.dart';

class CardStep extends StatelessWidget {
  final String number;

  final String description;

  const CardStep({
    super.key,
    required this.number,
    required this.description,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 25),
        decoration: BoxDecoration(
          color: AppColors.mypsyBgApp,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: AppColors.mypsyBgApp,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 46,
              width: 46,
              padding: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: AppColors.mypsyPrimary,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Center(
                child: Text(
                  number,
                  style: AppThemes.getTextStyle(
                      size: 23, clr: AppColors.mypsyWhite),
                ),
              ),
            ),
            spacerLarge,
            Center(
              child: Text(
                description,
                style: AppThemes.pStyle,
                textAlign: TextAlign.center,
              ),
            ),
            spaceBetween
          ],
        ),
      );
}
