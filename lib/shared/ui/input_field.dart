import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mypsy_app/shared/ui/device_types.dart';

TextStyle labelInputOutline() => TextStyle(
      color: AppColors.mypsyBlack,
      fontWeight: FontWeight.w400,
      fontSize:
          Device.get().isTablet! || Device.get().isSmallTablet! ? 17 : 14.4,
    );

class InputField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final Function validatorFct;
  final TextInputAction textInputAction;
  final Function? onChanged;
  final Function? onTap;
  final Function? pressedIcon;

  final int maxLines;
  final bool isPhone;
  final bool isLightTheme;
  final bool isRequired;
  final bool fromAuthentification;
  final bool withHideIcon;
  final bool hidePwd;
  final bool showEyes;
  final bool hideTopLabel;
  final bool isReadOnly;
  final bool disableInput;

  const InputField(
    this.controller,
    this.label,
    this.validatorFct,
    this.textInputAction, {
    this.maxLines = 1,
    this.isPhone = false,
    this.onChanged,
    this.isLightTheme = true,
    this.isRequired = true,
    this.fromAuthentification = false,
    this.withHideIcon = true,
    this.hidePwd = true,
    super.key,
    this.pressedIcon,
    this.onTap,
    this.showEyes = false,
    this.hideTopLabel = false,
    this.isReadOnly = false,
    this.disableInput = false,
  });

  @override
  Widget build(BuildContext context) {
    Color labelColor = AppColors.mypsyWhite, borderColor = AppColors.mypsyGrey;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hideTopLabel)
          Row(
            children: [
              Text(
                label,
                style: AppThemes.labelInputStyle,
              ),
              if (isRequired)
                const Text(
                  ' *',
                  style: TextStyle(
                    color: AppColors.mypsyPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        const SizedBox(
          height: 7,
        ),
        TextFormField(
          readOnly: isReadOnly,
          obscureText: withHideIcon ? false : hidePwd,
          inputFormatters: isPhone
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                ]
              : [],
          maxLines: maxLines,
          style: AppThemes.placeholderStyle,
          controller: controller,
          validator: validatorFct as String? Function(String?)?,
          onTap: onTap != null ? onTap as void Function()? : null,
          onChanged:
              onChanged != null ? onChanged as void Function(String)? : null,
          keyboardType: TextInputType.text,
          textInputAction: textInputAction,
          decoration: showEyes
              ? inputDecorationPwd(labelColor, borderColor)
              : InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                  errorMaxLines: 1,
                  errorStyle: AppThemes.errorStyle,
                  prefix: const Padding(padding: EdgeInsets.only()),
                  label: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      (isRequired)
                          ? Text(
                              label,
                              style: AppThemes.placeholderStyle,
                            )
                          : Expanded(
                              child: Text(
                                label,
                                style: AppThemes.placeholderStyle,
                              ),
                            ),
                    ],
                  ),
                  hintText: isPhone ? '(00 xx xxx xxxxx)' : '',
                  hintStyle: AppThemes.hintInputStyle,
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  labelStyle: AppThemes.placeholderStyle,
                  enabledBorder: outlineBorder(0),
                  border: outlineBorder(0),
                  focusedBorder: outlineBorder(0),
                  filled: true,
                  fillColor:
                      disableInput ? Colors.grey[300] : AppColors.mypsyWhite,
                ),
        ),
      ],
    );
  }

  Widget iconEye(bool hidePwd) => Icon(
        hidePwd ? Icons.visibility_off : Icons.visibility,
        color: hidePwd ? AppColors.mypsyPrimary : AppColors.mypsyGrey,
        size: 20,
      );

  InputDecoration inputDecorationPwd(Color labelColor, Color borderColor) =>
      InputDecoration(
        errorMaxLines: 1,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
        errorStyle: AppThemes.errorStyle,
        prefix: const Padding(padding: EdgeInsets.only()),
        label: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            (isRequired) ? Text(label) : Expanded(child: Text(label)),
          ],
        ),
        hintStyle: AppThemes.infoStyle,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        labelStyle: AppThemes.placeholderStyle,
        enabledBorder: outlineBorder(1),
        border: outlineBorder(1),
        focusedBorder: outlineBorder(1),
        filled: true,
        fillColor: AppColors.mypsyWhite,
        suffixIcon: withHideIcon
            ? null
            : IconButton(
                onPressed: pressedIcon as void Function()?,
                icon: iconEye(hidePwd),
              ),
      );

  InputDecoration inputDecorationTopHint(
    String content,
  ) {
    double borderWidth = 0.7;
    return InputDecoration(
      prefix: const SizedBox(width: 10),
      floatingLabelBehavior: hideTopLabel
          ? FloatingLabelBehavior.never
          : FloatingLabelBehavior.auto,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      counterText: '',
      labelText: content,
      labelStyle: labelInputOutline(),
      focusedBorder: outlineBorder(borderWidth),
      border: outlineBorder(borderWidth),
      enabledBorder: outlineBorder(borderWidth),
      suffixIcon: withHideIcon
          ? null
          : IconButton(
              onPressed: pressedIcon as void Function()?,
              icon: iconEye(hidePwd),
            ),
    );
  }
}

OutlineInputBorder outlineBorder(
  double widthB, {
  Color borderColor = AppColors.mypsyInputBorder,
}) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: BorderSide(
        color: borderColor,
        width: widthB,
      ),
    );
