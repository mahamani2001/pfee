import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:mypsy_app/shared/ui/buttons/button.dart';
import 'package:mypsy_app/shared/ui/device_types.dart';

class AlertYesNo extends StatelessWidget {
  final String title;
  final String description;
  final String btnTitle;
  final String btnNoTitle;
  final Function onPressYes;
  final Function onClosePopup; // press no
  const AlertYesNo({
    super.key,
    required this.title,
    required this.description,
    required this.btnTitle,
    required this.btnNoTitle,
    required this.onPressYes,
    required this.onClosePopup,
  });

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: AppColors.mypsyWhite,
        contentPadding: const EdgeInsets.all(0),
        content: Stack(
          children: [
            Container(
              width: Device.get().isTablet!
                  ? 400
                  : MediaQuery.of(context).size.width,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.mypsyWhite,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: AppThemes.getTextStyle(
                        clr: AppColors.mypsyPrimary,
                        fontWeight: FontWeight.w700,
                        size: 14),
                    textAlign: TextAlign.center,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Text(
                      description,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: mypsyButton(
                          text: btnTitle,
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          onPress: () {
                            onPressYes();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: mypsyButton(
                          text: btnNoTitle,
                          bgColors: AppColors.mypsySecondary,
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          onPress: () {
                            onClosePopup();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                ],
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: GestureDetector(
                onTap: () {
                  onClosePopup();
                },
                child: Container(
                  color: Colors.transparent,
                  width: 50,
                  height: 40,
                  child: Center(
                    child: Container(
                      color: Colors.transparent,
                      height: 15,
                      width: 15,
                      child: SvgPicture.asset(
                        'assets/icons/close.svg',
                        height: 15,
                        width: 15,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
