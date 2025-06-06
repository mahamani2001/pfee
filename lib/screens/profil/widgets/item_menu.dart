import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';

class ItemMenu extends StatelessWidget {
  final String title;
  final String iconName;
  final bool withColor;
  const ItemMenu(
      {super.key,
      required this.title,
      required this.iconName,
      required this.withColor});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: AppColors.mypsyWhite,
          border: Border.all(color: AppColors.mypsyDarkBlue.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          leading: iconName.isNotEmpty
              ? SvgPicture.asset(
                  'assets/icons/profile/$iconName.svg',
                  height: 22,
                  color: AppColors.mypsyPrimary,
                )
              : null,
          title: Text(
            title,
            style: AppThemes.getTextStyle(
              clr: withColor ? AppColors.mypsyPrimary : AppColors.mypsyBlack,
              size: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: withColor ? AppColors.mypsyPrimary : AppColors.mypsyBlack,
            size: 13,
          ),
        ),
      );
}
