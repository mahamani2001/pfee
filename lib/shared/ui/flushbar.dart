import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';

Flushbar customFlushbar(String title, String? msg, BuildContext context,
        {bool isError = false,
        Color bgColor = AppColors.mypsyDarkGreen,
        Color txtColor = AppColors.mypsyBlack,
        bool withBorder = true,
        int duration = 3,
        bool isDismissible = true,
        int animationDuration = 1}) =>
    Flushbar(
      title: title.isNotEmpty ? title : null,
      messageText: Text(
        '$msg',
        style: AppThemes.getTextStyle(clr: AppColors.mypsyWhite),
      ),
      backgroundColor: isError ? AppColors.mypsyRed : bgColor,
      icon: const Icon(Icons.error_outline, color: Colors.white),
      flushbarPosition: FlushbarPosition.TOP,
      isDismissible: isDismissible,
      duration: Duration(seconds: duration),
      animationDuration: Duration(seconds: animationDuration),
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      leftBarIndicatorColor: withBorder
          ? isError
              ? AppColors.mypsyRed
              : AppColors.mypsyPrimary
          : Colors.transparent,
    )..show(context);
