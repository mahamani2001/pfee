import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:mypsy_app/shared/ui/device_types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class IconMenu extends StatelessWidget {
  final bool isSelected;
  final String icon;
  final String title;

  const IconMenu({
    super.key,
    required this.isSelected,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) => Container(
        height: 75,
        color: Colors.transparent,
        width: (MediaQuery.of(context).size.width / 4) - 10,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              child: SvgPicture.asset(
                icon,
                height: Device.get().isTablet! ? 30 : 23,
                width: 25,
                color:
                    isSelected ? AppColors.mypsyPrimary : AppColors.mypsyBlack,
              ),
            ),
            Text(
              title,
              style: AppThemes.getTextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                size: Device.get().isTablet! ? 15 : 12,
                clr: isSelected ? AppColors.mypsyPrimary : AppColors.mypsyBlack,
              ),
            ),
          ],
        ),
      );
}
