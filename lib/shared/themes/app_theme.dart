import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:flutter/material.dart';

class AppThemes {
  AppThemes._();
  static const fontRoboto = 'Roboto';
  static const fontInter = 'Raleway';
  static const TextStyle headerStyle = TextStyle(
    color: AppColors.mypsyWhite,
    fontSize: 23,
    fontFamily: fontInter,
    fontWeight: FontWeight.w300,
  );

  static const TextStyle hintInputStyle = TextStyle(
    color: AppColors.mypsyWhite,
    fontSize: 13,
    fontFamily: fontInter,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle labelInputStyle = TextStyle(
    color: AppColors.mypsyWhite,
    fontSize: 13,
    fontFamily: fontInter,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle questionInfo = TextStyle(
    color: AppColors.mypsyWhite,
    fontSize: 13,
    fontFamily: fontInter,
    fontWeight: FontWeight.w400,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.mypsyWhite,
  );

  static const TextStyle titleFooterLink = TextStyle(
    color: AppColors.mypsyWhite,
    fontSize: 15,
    fontFamily: fontInter,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle titleStylePrimary = TextStyle(
    color: AppColors.mypsyPrimary,
    fontSize: 15,
    fontFamily: fontInter,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle subMenuStyle = TextStyle(
    color: AppColors.mypsyBlack,
    fontSize: 13,
    fontFamily: fontInter,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle subTitleStyle = TextStyle(
    color: AppColors.mypsyPrimary,
    fontSize: 15,
    fontFamily: fontInter,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle appbarTitleStyle = TextStyle(
    color: AppColors.mypsyPrimary,
    fontSize: 20,
    fontFamily: fontInter,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle appbarSubPageTitleStyle = TextStyle(
    color: AppColors.mypsyBlack,
    fontSize: 15,
    fontFamily: fontInter,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle placeholderStyle = TextStyle(
    color: AppColors.mypsyPlaceholderColor,
    fontSize: 13,
    fontFamily: fontInter,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle pStyle = TextStyle(
    color: AppColors.mypsyBlack,
    fontSize: 14,
    fontFamily: fontInter,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle headerTitleStyle = TextStyle(
    color: AppColors.mypsyPrimary,
    fontSize: 23,
    fontFamily: fontInter,
    fontWeight: FontWeight.w400,
  );

  ///
  static const TextStyle infoStyle = TextStyle(
    color: AppColors.mypsyGrey,
    fontSize: 12,
    fontFamily: fontInter,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle errorStyle = TextStyle(
    color: AppColors.mypsyRed,
    fontSize: 10,
    fontFamily: fontInter,
    fontWeight: FontWeight.w400,
  );

  static RoundedRectangleBorder shapeRadius = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(5),
  );
  static const EdgeInsets btnPadding =
      EdgeInsets.symmetric(horizontal: 15, vertical: 10);
  static TextStyle getTextStyle({
    Color clr = AppColors.mypsyBlack,
    FontWeight fontWeight = FontWeight.w400,
    double size = 14,
    bool withDecoration = false,
    String fontFamliy = fontInter,
  }) =>
      TextStyle(
        color: clr,
        fontSize: size,
        fontFamily: fontFamliy,
        fontWeight: fontWeight,
        decoration:
            withDecoration ? TextDecoration.underline : TextDecoration.none,
      );
}
