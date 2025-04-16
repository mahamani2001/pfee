import 'package:mypsy_app/screens/profil/widgets/hotline_button.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:flutter/material.dart';

class HotlineInfo extends StatelessWidget {
  const HotlineInfo({super.key});

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image.asset(
              'assets/hotline-ambassadeur.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(left: 16, top: 10, child: buildInfo()),
        ],
      );

  Widget buildInfo() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accès privilégié \nHotline Technique mypsy',
            style: AppThemes.getTextStyle(
                clr: AppColors.mypsyWhite,
                size: 16,
                fontWeight: FontWeight.w500),
          ),
          const HotlineButton(),
          Text(
            'Code d’accès : 2006',
            style: AppThemes.getTextStyle(
              clr: AppColors.mypsyWhite,
              size: 13,
            ),
          ),
        ],
      );
}
