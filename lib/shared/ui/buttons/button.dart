import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:mypsy_app/shared/ui/device_types.dart';
import 'package:flutter/material.dart';

enum BtnType {
  filled,
  filledWhite,
  outline,
  disabled,
  disabledOutline,
  disabledGrey,
  disabledGreyOutline
}

class mypsyButton extends StatelessWidget {
  final String text;
  final Function? onPress;
  final BtnType btnType;
  final EdgeInsets padding;
  final Color colr;
  final Color bgColors;
  final bool isSmallBtn;
  final bool isFull;
  final bool isLight;
  final bool withLoader;

  const mypsyButton(
      {super.key,
      required this.text,
      required this.onPress,
      this.btnType = BtnType.filled,
      this.padding = const EdgeInsets.symmetric(
        vertical: 18,
      ),
      this.colr = AppColors.mypsyWhite,
      this.bgColors = AppColors.mypsyPrimary,
      this.isSmallBtn = false,
      this.isFull = false,
      this.isLight = false,
      this.withLoader = false});

  @override
  Widget build(BuildContext context) {
    Widget btn;
    Widget textWidget = Text(
      text,
      style: TextStyle(
        color: colr,
        fontSize: Device.get().isTablet! ? 18 : 16,
        fontFamily: AppThemes.fontInter,
        fontWeight: isLight ? FontWeight.w300 : FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
    if (withLoader) {
      textWidget = Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            textWidget,
          ]);
    }
    switch (btnType) {
      case BtnType.filled:
        btn = ElevatedButton(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: AppColors.mypsyDisabledGrey,
            foregroundColor: AppColors.mypsyWhite,
            backgroundColor: bgColors,
            padding: padding,
            shape: AppThemes.shapeRadius,
          ),
          onPressed: onPress as void Function()?,
          child: textWidget,
        );
        break;
      case BtnType.filledWhite:
        btn = ElevatedButton(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            side: const BorderSide(width: 0.5),
            shadowColor: Colors.transparent,
            foregroundColor: bgColors,
            backgroundColor: bgColors,
            padding: padding,
            shape: AppThemes.shapeRadius,
          ),
          onPressed: onPress as void Function()?,
          child: Text(
            text,
            style: AppThemes.getTextStyle(
              size: Device.get().isTablet! ? 19 : 17,
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
        );
        break;

      case BtnType.disabled:
        btn = ElevatedButton(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: padding,
            disabledBackgroundColor: AppColors.mypsyPrimary.withOpacity(0.22),
            shape: AppThemes.shapeRadius,
            shadowColor: Colors.transparent,
          ),
          onPressed: null,
          child: textWidget,
        );
        break;
      case BtnType.disabledGrey:
        btn = ElevatedButton(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: padding,
            disabledBackgroundColor: AppColors.mypsyDisabledGrey,
            shape: AppThemes.shapeRadius,
            shadowColor: Colors.transparent,
          ),
          onPressed: null,
          child: textWidget,
        );
        break;
      default:
        btn = ElevatedButton(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: padding,
            disabledBackgroundColor: AppColors.mypsyDisabledGrey,
            shape: AppThemes.shapeRadius,
            shadowColor: Colors.transparent,
          ),
          onPressed: null,
          child: textWidget,
        );
    }

    return isFull ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
